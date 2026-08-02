import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/onboarding/find_password_screens/reset_password_screen.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/utils/app_toast.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;
  final int expiresIn;
  final int resendAfter;

  const VerificationCodeScreen({
    super.key,
    required this.email,
    required this.expiresIn,
    this.resendAfter = 0,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isError = false;
  bool _isLoading = false;
  bool _isResending = false;
  String _errorText = '인증번호가 일치하지 않습니다.';
  Timer? _ticker;
  late DateTime _expiresAt;
  DateTime? _resendAvailableAt;
  int _remainingSeconds = 0;
  int _resendCooldownSeconds = 0;

  bool get _isExpired => _remainingSeconds <= 0;
  bool get _canResend => !_isResending && _resendCooldownSeconds <= 0;
  bool get _canVerify =>
      _controller.text.trim().length == 6 && !_isLoading && !_isExpired;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyServerTiming(
      expiresIn: widget.expiresIn,
      resendAfter: widget.resendAfter,
    );
    _focusNode.addListener(() {
      setState(() {});
    });
    _controller.addListener(() {
      setState(() {
        _isError = false;
        _errorText = '인증번호가 일치하지 않습니다.';
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateRemainingTime();
    }
  }

  void _applyServerTiming({
    required int expiresIn,
    required int resendAfter,
    bool notify = false,
  }) {
    final now = DateTime.now();
    _expiresAt = now.add(Duration(seconds: expiresIn.clamp(0, 86400)));
    _resendAvailableAt = resendAfter > 0
        ? now.add(Duration(seconds: resendAfter.clamp(0, 86400)))
        : null;
    _remainingSeconds = _secondsUntil(_expiresAt);
    _resendCooldownSeconds = _secondsUntil(_resendAvailableAt);
    if (notify && mounted) setState(() {});
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (_remainingSeconds <= 0 && _resendCooldownSeconds <= 0) return;
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
  }

  void _updateRemainingTime() {
    if (!mounted) return;
    final nextRemaining = _secondsUntil(_expiresAt);
    final nextResendCooldown = _secondsUntil(_resendAvailableAt);
    if (nextRemaining == _remainingSeconds &&
        nextResendCooldown == _resendCooldownSeconds) {
      return;
    }
    setState(() {
      _remainingSeconds = nextRemaining;
      _resendCooldownSeconds = nextResendCooldown;
    });
    if (_remainingSeconds <= 0 && _resendCooldownSeconds <= 0) {
      _ticker?.cancel();
    }
  }

  int _secondsUntil(DateTime? deadline) {
    if (deadline == null) return 0;
    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / 1000).ceil();
  }

  String _formatRemainingTime(int seconds) {
    if (seconds <= 0) return '만료';
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.none,
              leadingIcon: 'arrow_left.svg',
              leadingColor: AppColors.gray200,
              onLeadingTap: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 32.h),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(
                          "메일로\n인증번호를 보냈어요",
                          style: AppTypography.display.copyWith(
                            color: AppColors.gray200,
                          ),
                        ),
                      ),
                      SizedBox(height: 13.h),
                      Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(
                          "가입하신 메일을 확인하고\n보내드린 인증번호 6자리를 입력해주세요.",
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.gray200,
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                      TextFieldWidget(
                        hintText: '인증번호를 입력해주세요.',
                        controller: _controller,
                        obscureText: false,
                        isError: _isError,
                        focusNode: _focusNode,
                        suffixIcon:
                            _focusNode.hasFocus && _controller.text != ''
                            ? GestureDetector(
                                onTap: () {
                                  _controller.clear();
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/circle_close.svg',
                                  width: 20.w,
                                  color: AppColors.gray600,
                                ),
                              )
                            : null,
                        errorText: _isExpired ? '인증번호가 만료되었습니다.' : _errorText,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatRemainingTime(_remainingSeconds),
                            style: AppTypography.caption1.copyWith(
                              color: _isExpired
                                  ? AppColors.error
                                  : AppColors.primary400,
                            ),
                          ),
                          GestureDetector(
                            onTap: _canResend ? _resendCode : null,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              _resendCooldownSeconds > 0
                                  ? '재발송 ${_resendCooldownSeconds}s'
                                  : '재발송',
                              style: AppTypography.caption1.copyWith(
                                color: _canResend
                                    ? AppColors.gray200
                                    : AppColors.gray600,
                                decoration: TextDecoration.underline,
                                decorationColor: _canResend
                                    ? AppColors.gray200
                                    : AppColors.gray600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0.w),
              child: ButtonSolid(
                text: _isLoading ? '확인 중...' : '다음으로',
                textColor: _canVerify ? AppColors.gray900 : AppColors.gray700,
                boxColor: _canVerify ? AppColors.primary400 : Color(0x1AF5F5F3),
                onTap: _verifyCode,
              ),
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    final code = _controller.text.trim();
    if (_isLoading) return;
    if (code.length != 6) {
      setState(() {
        _isError = true;
        _errorText = '인증번호 6자리를 입력해주세요.';
      });
      return;
    }
    if (_isExpired) {
      setState(() {
        _isError = true;
        _errorText = '인증번호가 만료되었습니다.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      final result = await AuthService().verifyPasswordCode(
        email: widget.email,
        code: code,
      );
      if (!mounted) return;
      pushToScreen(context, ResetPasswordScreen(resetToken: result.resetToken));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        if (error is ApiException && error.code == 'A011') {
          _remainingSeconds = 0;
          _expiresAt = DateTime.now();
          _ticker?.cancel();
          _errorText = '인증번호가 만료되었습니다.';
        } else if (error is ApiException && error.message.isNotEmpty) {
          _errorText = error.message;
        }
      });
      showAppToast(context, '$error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;
    setState(() {
      _isResending = true;
      _isError = false;
      _controller.clear();
    });
    try {
      final result = await AuthService().requestPasswordCode(widget.email);
      if (!mounted) return;
      _applyServerTiming(
        expiresIn: result.expiresIn,
        resendAfter: result.resendAfter,
        notify: true,
      );
      showAppToast(context, '인증번호를 다시 보냈어요.');
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }
}
