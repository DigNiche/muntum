import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up_password_screen.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/utils/app_toast.dart';

class SignUpScreen extends StatefulWidget {
  final AuthService? authService;

  const SignUpScreen({super.key, this.authService});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const int _verificationDuration = 300;

  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _verificationCodeFocusNode = FocusNode();

  late final AuthService _authService;
  Timer? _timer;
  bool _isVerificationRequested = false;
  bool _isEmailError = false;
  bool _isCodeError = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isResendingCode = false;
  String _emailErrorText = '이메일 형식이 올바르지 않습니다.';
  String _codeErrorText = '인증번호가 일치하지 않습니다. 다시 확인해 주세요.';
  int _remainingSeconds = _verificationDuration;
  int _resendCooldownSeconds = 0;

  bool get _isValidEmail => RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  ).hasMatch(_emailController.text.trim());

  bool get _canVerifyCode =>
      _verificationCodeController.text.length == 6 &&
      _remainingSeconds > 0 &&
      !_isVerifyingCode;
  bool get _isExpired => _remainingSeconds == 0;
  bool get _canResend =>
      _resendCooldownSeconds == 0 && !_isResendingCode && !_isSendingCode;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _emailController.addListener(_handleEmailChanged);
    _verificationCodeController.addListener(_handleCodeChanged);
    _emailFocusNode.addListener(_refresh);
    _verificationCodeFocusNode.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocusNode.requestFocus();
    });
  }

  void _handleEmailChanged() {
    setState(() {
      _isEmailError = false;
      _emailErrorText = '이메일 형식이 올바르지 않습니다.';
    });
  }

  void _handleCodeChanged() {
    setState(() {
      _isCodeError = _isExpired;
      if (_isExpired) {
        _codeErrorText = '인증 시간이 만료되었습니다. 재발송을 눌러주세요.';
      }
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController
      ..removeListener(_handleEmailChanged)
      ..dispose();
    _verificationCodeController
      ..removeListener(_handleCodeChanged)
      ..dispose();
    _emailFocusNode
      ..removeListener(_refresh)
      ..dispose();
    _verificationCodeFocusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
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
              onLeadingTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 32.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안녕하세요!\n이메일을 입력해주세요',
                      style: AppTypography.display.copyWith(
                        color: AppColors.gray200,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    TextFieldWidget(
                      hintText: '이메일을 입력해 주세요.',
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      readOnly: _isVerificationRequested,
                      isError: _isEmailError,
                      errorText: _emailErrorText,
                      suffixIcon:
                          !_isVerificationRequested &&
                              _emailFocusNode.hasFocus &&
                              _emailController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: _emailController.clear,
                              child: SvgPicture.asset(
                                'assets/icons/circle_close.svg',
                                width: 20.w,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.gray600,
                                  BlendMode.srcIn,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (!_isVerificationRequested) ...[
                      SizedBox(height: 12.h),
                      ButtonSolid(
                        text: _isSendingCode ? '전송 중...' : '인증하기',
                        textColor: _isValidEmail && !_isSendingCode
                            ? AppColors.gray900
                            : AppColors.gray700,
                        boxColor: _isValidEmail && !_isSendingCode
                            ? AppColors.primary400
                            : const Color(0x1AF5F5F3),
                        onTap: _isValidEmail && !_isSendingCode
                            ? _requestVerification
                            : null,
                      ),
                    ] else ...[
                      SizedBox(height: 12.h),
                      _buildVerificationInput(),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '코드가 오지 않나요? ',
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _canResend ? _resendVerification : null,
                            child: Text(
                              _resendCooldownSeconds > 0
                                  ? '재발송 $_resendCooldownSeconds초'
                                  : _isResendingCode
                                  ? '재발송 중...'
                                  : '재발송',
                              style: AppTypography.caption1.copyWith(
                                color: _canResend
                                    ? AppColors.gray300
                                    : AppColors.gray600,
                                decoration: TextDecoration.underline,
                                decorationColor: _canResend
                                    ? AppColors.gray300
                                    : AppColors.gray600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8.w,
          children: [
            Expanded(
              child: TextFieldWidget(
                hintText: '인증번호 6자리 입력',
                controller: _verificationCodeController,
                focusNode: _verificationCodeFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                obscureText: false,
                isError: _isCodeError,
                showErrorMessage: false,
                errorText: _codeErrorText,
                suffixIconPadding: EdgeInsets.only(right: 16.w),
                suffixIcon: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10.w,
                    children: [
                      if (_verificationCodeController.text.isNotEmpty)
                        GestureDetector(
                          onTap: _verificationCodeController.clear,
                          child: SvgPicture.asset(
                            'assets/icons/circle_close.svg',
                            width: 20.w,
                            height: 20.w,
                            colorFilter: const ColorFilter.mode(
                              AppColors.gray600,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      Text(
                        _formattedRemainingTime,
                        textAlign: TextAlign.center,
                        style: AppTypography.button2.copyWith(
                          color: AppColors.gray200,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ButtonSolid(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 13.h),
              text: _isVerifyingCode ? '확인 중...' : '인증 확인',
              textColor: _canVerifyCode ? AppColors.gray900 : AppColors.gray700,
              boxColor: _canVerifyCode
                  ? AppColors.primary400
                  : const Color(0x1AF5F5F3),
              onTap: _canVerifyCode ? _verifyCode : null,
            ),
          ],
        ),
        if (_isCodeError) ...[
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.w,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: SvgPicture.asset(
                  'assets/icons/error.svg',
                  width: 16.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.error,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _codeErrorText,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String get _formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _requestVerification() async {
    if (!_isValidEmail) {
      setState(() => _isEmailError = true);
      return;
    }

    setState(() {
      _isSendingCode = true;
      _isEmailError = false;
    });
    try {
      final result = await _authService.requestSignupEmailCode(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      _applyServerTiming(
        expiresIn: result.expiresIn,
        resendAfter: result.resendAfter,
      );
      setState(() => _isVerificationRequested = true);
      _verificationCodeFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) return;
      _handleSendCodeError(error);
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds == 0 && _resendCooldownSeconds == 0) {
        _timer?.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }
        if (_resendCooldownSeconds > 0) {
          _resendCooldownSeconds--;
        }
        if (_remainingSeconds == 0) {
          _isCodeError = true;
          _codeErrorText = '인증 시간이 만료되었습니다. 재발송을 눌러주세요.';
        }
      });
    });
  }

  void _applyServerTiming({required int expiresIn, required int resendAfter}) {
    setState(() {
      _remainingSeconds = expiresIn > 0 ? expiresIn : _verificationDuration;
      _resendCooldownSeconds = resendAfter > 0 ? resendAfter : 0;
      _isCodeError = false;
      _codeErrorText = '인증번호가 일치하지 않습니다. 다시 확인해 주세요.';
    });
    _startTimer();
  }

  Future<void> _resendVerification() async {
    if (!_canResend) return;
    setState(() {
      _isResendingCode = true;
      _isCodeError = false;
    });
    try {
      final result = await _authService.requestSignupEmailCode(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      _verificationCodeController.clear();
      _applyServerTiming(
        expiresIn: result.expiresIn,
        resendAfter: result.resendAfter,
      );
      _verificationCodeFocusNode.requestFocus();
      showAppToast(context, '인증번호를 다시 보냈어요.');
    } catch (error) {
      if (!mounted) return;
      _handleSendCodeError(error, showInlineError: false);
    } finally {
      if (mounted) setState(() => _isResendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_isExpired) {
      setState(() {
        _isCodeError = true;
        _codeErrorText = '인증 시간이 만료되었습니다. 재발송을 눌러주세요.';
      });
      return;
    }
    if (!_canVerifyCode) {
      setState(() {
        _isCodeError = true;
        _codeErrorText = '인증번호 6자리를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isVerifyingCode = true;
      _isCodeError = false;
    });
    try {
      final result = await _authService.verifySignupEmailCode(
        email: _emailController.text.trim(),
        code: _verificationCodeController.text,
      );
      if (!mounted) return;
      if (result.signupToken.isEmpty) {
        throw const ApiException(message: '회원가입 인증 토큰을 받지 못했습니다.');
      }
      _timer?.cancel();
      final passwordResult = await Navigator.push<SignUpPasswordResult>(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpPasswordScreen(
            email: _emailController.text.trim(),
            signupToken: result.signupToken,
            authService: _authService,
          ),
        ),
      );
      if (!mounted) return;
      if (passwordResult == SignUpPasswordResult.restartEmailVerification) {
        _resetToEmailStep();
        showAppToast(context, '이메일 인증이 만료되었어요. 다시 인증해주세요.', isError: true);
      }
    } catch (error) {
      if (!mounted) return;
      _handleVerifyCodeError(error);
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  void _resetToEmailStep() {
    _timer?.cancel();
    _verificationCodeController.clear();
    setState(() {
      _isVerificationRequested = false;
      _remainingSeconds = _verificationDuration;
      _resendCooldownSeconds = 0;
      _isCodeError = false;
      _codeErrorText = '인증번호가 일치하지 않습니다. 다시 확인해 주세요.';
    });
    _emailFocusNode.requestFocus();
  }

  void _handleSendCodeError(Object error, {bool showInlineError = true}) {
    final exception = error is ApiException ? error : null;
    if (exception?.code == 'A020' && _isVerificationRequested) {
      setState(() => _resendCooldownSeconds = 60);
      _startTimer();
    }
    final message = switch (exception?.code) {
      '007' => '이메일 형식이 올바르지 않습니다.',
      'A001' => '이미 가입된 이메일입니다.',
      'A020' => '재발송은 60초 후에 가능합니다.',
      'A021' => '일일 인증번호 발송 한도를 초과했습니다.',
      _ =>
        exception?.message.isNotEmpty == true
            ? exception!.message
            : '인증번호를 보내지 못했습니다. 다시 시도해주세요.',
    };
    if (showInlineError) {
      setState(() {
        _isEmailError = true;
        _emailErrorText = message;
      });
    } else {
      showAppToast(context, message, isError: true);
    }
  }

  void _handleVerifyCodeError(Object error) {
    final exception = error is ApiException ? error : null;
    switch (exception?.code) {
      case 'A011':
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isCodeError = true;
          _codeErrorText = '인증 시간이 만료되었습니다. 재발송을 눌러주세요.';
        });
      case 'A013':
        _resetToEmailStep();
        showAppToast(context, '시도 횟수를 초과했어요. 인증번호를 다시 받아주세요.', isError: true);
      case 'A001':
        _resetToEmailStep();
        setState(() {
          _isEmailError = true;
          _emailErrorText = '이미 가입된 이메일입니다.';
        });
      case '007':
        setState(() {
          _isCodeError = true;
          _codeErrorText = '인증번호 6자리 숫자를 입력해주세요.';
        });
      case 'A012':
        setState(() {
          _isCodeError = true;
          _codeErrorText = '인증번호가 일치하지 않습니다. 다시 확인해 주세요.';
        });
      default:
        setState(() {
          _isCodeError = true;
          _codeErrorText = exception?.message.isNotEmpty == true
              ? exception!.message
              : '인증번호를 확인하지 못했습니다.';
        });
    }
  }
}
