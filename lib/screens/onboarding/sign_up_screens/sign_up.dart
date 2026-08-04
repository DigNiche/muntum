import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up_password_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const int _verificationDuration = 300;

  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _verificationCodeFocusNode = FocusNode();

  Timer? _timer;
  bool _isVerificationRequested = false;
  bool _isEmailError = false;
  bool _isCodeError = false;
  String _codeErrorText = '인증번호가 일치하지 않습니다. 다시 확인해 주세요.';
  int _remainingSeconds = _verificationDuration;

  bool get _isValidEmail => RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  ).hasMatch(_emailController.text.trim());

  bool get _canVerifyCode =>
      _verificationCodeController.text.length == 6 && _remainingSeconds > 0;
  bool get _isExpired => _remainingSeconds == 0;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleEmailChanged);
    _verificationCodeController.addListener(_handleCodeChanged);
    _emailFocusNode.addListener(_refresh);
    _verificationCodeFocusNode.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocusNode.requestFocus();
    });
  }

  void _handleEmailChanged() {
    setState(() => _isEmailError = false);
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
                      errorText: '이메일 형식이 올바르지 않습니다.',
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
                        text: '인증하기',
                        textColor: _isValidEmail
                            ? AppColors.gray900
                            : AppColors.gray700,
                        boxColor: _isValidEmail
                            ? AppColors.primary400
                            : const Color(0x1AF5F5F3),
                        onTap: _isValidEmail ? _requestVerification : null,
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
                            onTap: _resendVerification,
                            child: Text(
                              '재발송',
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.gray300,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.gray300,
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
              text: '인증 확인',
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

  void _requestVerification() {
    if (!_isValidEmail) {
      setState(() => _isEmailError = true);
      return;
    }

    // TODO: 이메일 인증 API 배포 후 중복 확인 및 인증번호 발송을 연결합니다.
    setState(() {
      _isVerificationRequested = true;
      _remainingSeconds = _verificationDuration;
    });
    _startTimer();
    _verificationCodeFocusNode.requestFocus();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isCodeError = true;
          _codeErrorText = '인증 시간이 만료되었습니다. 재발송을 눌러주세요.';
        });
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _resendVerification() {
    _verificationCodeController.clear();
    setState(() {
      _remainingSeconds = _verificationDuration;
      _isCodeError = false;
      _codeErrorText = '인증번호가 일치하지 않습니다. 다시 확인해 주세요.';
    });
    _startTimer();
    _verificationCodeFocusNode.requestFocus();

    // TODO: 이메일 인증번호 재발송 API를 연결합니다.
  }

  void _verifyCode() {
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

    // TODO: 인증번호 확인 API 배포 후 signupToken을 다음 화면에 전달합니다.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SignUpPasswordScreen(email: _emailController.text.trim()),
      ),
    );
  }
}
