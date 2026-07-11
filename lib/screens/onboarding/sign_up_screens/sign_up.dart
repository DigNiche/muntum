import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up_complete_screen.dart';
import 'package:muntum/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  bool obsecureText1 = true;
  bool obsecureText2 = true;
  bool isPasswordError = false;
  bool isPasswordConfirmError = false;
  bool isEmailError = false;
  bool isLoading = false;
  String _emailErrorText = '이메일 형식이 올바르지 않습니다.';
  String _passwordErrorText = '비밀번호가 조건에 맞지 않습니다.';

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {
        isEmailError = false;
      });
    });
    passwordController.addListener(() {
      setState(() {
        isPasswordError = false;
      });
    });
    confirmPasswordController.addListener(() {
      setState(() {
        isPasswordConfirmError = false;
      });
    });
    emailFocusNode.addListener(() {
      setState(() {});
    });
    passwordFocusNode.addListener(() {
      setState(() {});
    });
    confirmPasswordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
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
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "안녕하세요!\n문화의 틈, 문틈입니다.",
                            style: AppTypography.display.copyWith(
                              color: AppColors.gray200,
                            ),
                          ),
                          SizedBox(height: 13.h),
                          Text(
                            "문화, 전시, 예술 등 다양한 프로그램들.\n문틈과 함께 문화의 틈으로 초대합니다.",
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.gray200,
                            ),
                          ),
                          SizedBox(height: 30.h),
                          // email
                          TextFieldWidget(
                            hintText: '이메일을 입력해 주세요.',
                            focusNode: emailFocusNode,
                            controller: emailController,
                            obscureText: false,
                            isError: isEmailError,
                            errorText: _emailErrorText,
                            keyboardType: TextInputType.emailAddress,
                            suffixIcon:
                                emailFocusNode.hasFocus &&
                                    emailController.text != ''
                                ? GestureDetector(
                                    onTap: () {
                                      emailController.clear();
                                    },
                                    child: SvgPicture.asset(
                                      'assets/icons/circle_close.svg',
                                      width: 20.w,
                                      color: AppColors.gray600,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(height: 12.h),
                          // password
                          TextFieldWidget(
                            hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                            focusNode: passwordFocusNode,
                            controller: passwordController,
                            obscureText: obsecureText1,
                            isError: isPasswordError,
                            errorText: _passwordErrorText,
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  obsecureText1 = !obsecureText1;
                                });
                              },
                              child: SvgPicture.asset(
                                !obsecureText1
                                    ? 'assets/icons/visibility.svg'
                                    : 'assets/icons/visibility-false.svg',
                                width: 20.w,
                                color: isPasswordError
                                    ? AppColors.gray700
                                    : !obsecureText1 && !isPasswordError
                                    ? AppColors.primary400
                                    : AppColors.gray500,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // confirm password
                          TextFieldWidget(
                            hintText: '비밀번호를 재입력해 주세요.',
                            focusNode: confirmPasswordFocusNode,
                            controller: confirmPasswordController,
                            obscureText: obsecureText2,
                            isError: isPasswordConfirmError,
                            errorText: '비밀번호가 일치하지 않습니다.',
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  obsecureText2 = !obsecureText2;
                                });
                              },
                              child: SvgPicture.asset(
                                !obsecureText2
                                    ? 'assets/icons/visibility.svg'
                                    : 'assets/icons/visibility-false.svg',
                                width: 20.w,
                                color: isPasswordConfirmError
                                    ? AppColors.gray700
                                    : !obsecureText2 && !isPasswordConfirmError
                                    ? AppColors.primary400
                                    : AppColors.gray500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '회원가입 시 문틈의 정책 및 약관에 동의합니다.',
              textAlign: TextAlign.center,
              style: AppTypography.caption1.copyWith(color: AppColors.gray700),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  child: Text(
                    '서비스 이용약관',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.gray700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.gray700,
                    ),
                  ),
                  onTap: () {
                    print('Tab');
                  },
                ),
                SizedBox(width: 16.h),
                GestureDetector(
                  child: Text(
                    '개인정보 처리방침',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.gray700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.gray700,
                    ),
                  ),
                  onTap: () {
                    print('Tab');
                  },
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0.h),
              child: ButtonSolid(
                text: isLoading ? '가입 중...' : '다음으로',
                textColor: AppColors.gray900,
                boxColor: AppColors.primary400,
                onTap: _signUp,
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (isLoading) return;
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    setState(() {
      isLoading = true;
      isEmailError = false;
      isPasswordError = false;
      isPasswordConfirmError = false;
      _emailErrorText = '이메일 형식이 올바르지 않습니다.';
      _passwordErrorText = '비밀번호가 조건에 맞지 않습니다.';
    });

    if (!_isValidEmail(email)) {
      setState(() {
        isLoading = false;
        isEmailError = true;
        _emailErrorText = '이메일 형식이 올바르지 않습니다.';
      });
      return;
    }

    if (!_isValidPassword(password)) {
      setState(() {
        isLoading = false;
        isPasswordError = true;
        _passwordErrorText = '영문, 숫자, 특수문자 포함 8자 이상이어야 합니다.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        isLoading = false;
        isPasswordConfirmError = true;
      });
      return;
    }

    try {
      final authService = AuthService();
      await authService.signup(email: email, password: password);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignUpCompleteScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _setSignUpError(error);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    ).hasMatch(password);
  }

  void _setSignUpError(Object error) {
    final code = error is ApiException ? error.code ?? '' : '';
    final message = error is ApiException ? error.message : error.toString();
    final normalized = '$code $message'.toLowerCase();
    final isPasswordFailure =
        normalized.contains('password') ||
        normalized.contains('비밀번호') ||
        normalized.contains('영문') ||
        normalized.contains('특수문자');

    setState(() {
      if (isPasswordFailure) {
        isPasswordError = true;
        _passwordErrorText = '영문, 숫자, 특수문자 포함 8자 이상이어야 합니다.';
      } else {
        isEmailError = true;
        _emailErrorText = normalized.contains('형식')
            ? '이메일 형식이 올바르지 않습니다.'
            : '이미 가입된 이메일 입니다.';
      }
    });
  }
}
