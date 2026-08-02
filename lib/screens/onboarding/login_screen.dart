import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';
import 'package:muntum/screens/onboarding/find_password_screens/find_password_screen.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/keyword_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/user_preference_store.dart';

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
  bool _isLoading = false;

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
    _passwordController.addListener(() {
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
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isLoginEnabled =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.none,
              leadingIcon: 'arrow_left.svg',
              leadingColor: AppColors.gray200,
              onLeadingTap: _handleBack,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40.h),
                    Text(
                      '이메일로\n로그인 해주세요',
                      style: AppTypography.display.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    TextFieldWidget(
                      errorText: '가입되지 않은 이메일 입니다.',
                      isError: _isEmailError,
                      hintText: '아이디(이메일)',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      focusNode: _emailFocusNode,
                      suffixIcon:
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
                    SizedBox(height: 12.h),
                    TextFieldWidget(
                      errorText: '잘못된 비밀번호 입니다.',
                      isError: _isPasswordError,
                      hintText: '비밀번호',
                      controller: _passwordController,
                      obscureText: _obsecureText,
                      focusNode: _passwordFocusNode,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() => _obsecureText = !_obsecureText);
                        },
                        child: SvgPicture.asset(
                          !_obsecureText
                              ? 'assets/icons/visibility.svg'
                              : 'assets/icons/visibility-false.svg',
                          width: 20.w,
                          colorFilter: ColorFilter.mode(
                            _isPasswordError
                                ? AppColors.gray700
                                : !_obsecureText
                                ? AppColors.primary400
                                : AppColors.gray500,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            pushToScreen(context, const FindPasswordScreen()),
                        child: Text(
                          '비밀번호를 잊으셨나요?',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.gray400,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gray400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ButtonSolid(
                      text: _isLoading ? '로그인 중...' : '로그인',
                      textColor: isLoginEnabled
                          ? AppColors.gray900
                          : AppColors.gray700,
                      boxColor: isLoginEnabled
                          ? AppColors.primary400
                          : AppColors.gray700.withValues(alpha: 0.1),
                      onTap: isLoginEnabled ? _login : null,
                    ),
                    SizedBox(height: isKeyboardVisible ? 20.h : 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const InitialScreen()),
    );
  }

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _isEmailError = false;
      _isPasswordError = false;
    });
    try {
      final session = await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      await _routeAfterApiLogin(session.nickname);
    } catch (error) {
      if (!mounted) return;
      _setLoginError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setLoginError(Object error) {
    final code = error is ApiException ? error.code ?? '' : '';
    final message = error is ApiException ? error.message : error.toString();
    final normalized = '$code $message'.toLowerCase();
    final isEmailFailure =
        code == 'A006' ||
        code == 'A007' ||
        normalized.contains('email') ||
        normalized.contains('이메일') ||
        normalized.contains('user not found') ||
        normalized.contains('not found') ||
        normalized.contains('가입되지');

    setState(() {
      _isEmailError = isEmailFailure;
      _isPasswordError = !isEmailFailure;
    });
  }

  Future<void> _routeAfterApiLogin(String? nickname) async {
    if (nickname == null || nickname.trim().isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NicknameScreen()),
      );
      return;
    }

    final keywords = await TasteService().fetchMyKeywords();
    UserPreferenceStore.instance.updateKeywords(
      keywords.selectedKeywords.map((keyword) => keyword.name),
    );
    if (!mounted) return;
    if (keywords.selectedKeywords.length < 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KeywordScreen()),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }
}
