import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';
import 'package:muntum/screens/onboarding/find_password_screen.dart';
import 'package:muntum/screens/onboarding/text_field_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obsecureText = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isEmailError = false;
  bool _isPasswordError = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
    _emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
        backgroundColor: AppColors.backgroundDark,
        resizeToAvoidBottomInset: false,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 200.h),
                      Text(
                        textAlign: TextAlign.center,
                        "MUNTUM",
                        style: TextStyle(
                          color: AppColors.primary400,
                          fontSize: 40.sp,
                        ),
                      ),
                      SizedBox(height: 50.h),
                      TextFieldWidget(
                        errorText: '가입되지 않은 이메일 입니다.',
                        isError: _isEmailError,
                        hintText: '이메일을 입력해 주세요.',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        focusNode: _emailFocusNode,
                        suffixIcon:
                            _emailFocusNode.hasFocus &&
                                _emailController.text != ''
                            ? GestureDetector(
                                onTap: () {
                                  _emailController.clear();
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
                      TextFieldWidget(
                        errorText: '잘못된 비밀번호 입니다.',
                        isError: _isPasswordError,
                        hintText: '비밀번호를 입력해 주세요.',
                        controller: _passwordController,
                        obscureText: _obsecureText,
                        focusNode: _passwordFocusNode,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obsecureText = !_obsecureText;
                            });
                          },
                          child: SvgPicture.asset(
                            !_obsecureText
                                ? 'assets/icons/visibility.svg'
                                : 'assets/icons/visibility-false.svg',
                            width: 20.w,
                            color: _isPasswordError
                                ? AppColors.gray700
                                : _obsecureText &&
                                      _passwordFocusNode.hasFocus &&
                                      !_isPasswordError
                                ? AppColors.primary400
                                : AppColors.gray500,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      ButtonSolid(
                        text: '로그인',
                        textColor: AppColors.gray900,
                        boxColor: AppColors.primary400,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainNavigationScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12.h),
                      ButtonSolid(
                        border: BoxBorder.all(
                          color: AppColors.primary400,
                          width: 1.sp,
                        ),
                        text: '회원가입',
                        textColor: AppColors.primary400,
                        boxColor: Colors.transparent,
                      ),
                      SizedBox(height: 24.h),
                      GestureDetector(
                        child: Text(
                          '비밀번호 찾기',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.gray700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gray700,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          pushToScreen(context, FindPasswordScreen());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ButtonSolid(
                text: '로그인 없이 둘러보기',
                textColor: AppColors.gray600,
                boxColor: Colors.transparent,
                border: BoxBorder.all(
                  color: AppColors.lineNormal.withValues(alpha: 0.5),
                  width: 1.w,
                ),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }
}
