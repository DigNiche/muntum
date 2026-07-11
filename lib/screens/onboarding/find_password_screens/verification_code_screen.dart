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

  const VerificationCodeScreen({
    super.key,
    required this.email,
    required this.expiresIn,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _isError = false;
  bool _isLoading = false;
  bool _isResending = false;
  Timer? _timer;
  Timer? _resendCooldownTimer;
  late int _remainingSeconds;
  int _resendCooldownSeconds = 0;

  bool get _isExpired => _remainingSeconds <= 0;
  bool get _canResend => !_isResending && _resendCooldownSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.expiresIn);
    _focusNode.addListener(() {
      setState(() {});
    });
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendCooldownTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    _remainingSeconds = seconds <= 0 ? 0 : seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  void _startResendCooldown({int seconds = 30}) {
    _resendCooldownTimer?.cancel();
    setState(() => _resendCooldownSeconds = seconds);
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSeconds = 0);
        return;
      }
      setState(() => _resendCooldownSeconds -= 1);
    });
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
                        errorText: _isExpired
                            ? '인증번호가 만료되었습니다.'
                            : '인증번호가 일치하지 않습니다.',
                        keyboardType: TextInputType.number,
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
                text: '다음으로',
                textColor: _controller.text != ''
                    ? AppColors.gray900
                    : AppColors.gray700,
                boxColor: _controller.text != ''
                    ? AppColors.primary400
                    : Color(0x1AF5F5F3),
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
    if (code.isEmpty || _isLoading) return;
    if (_isExpired) {
      setState(() => _isError = true);
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
      pushToScreen(
        context,
        ResetPasswordScreen(
          resetToken: result.resetToken,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        if (error is ApiException && error.code == 'A011') {
          _remainingSeconds = 0;
          _timer?.cancel();
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
      _startCountdown(result.expiresIn);
      _startResendCooldown();
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
