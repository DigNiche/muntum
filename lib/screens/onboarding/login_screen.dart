import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/screens/home/home_screen.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';
import 'package:muntum/screens/onboarding/find_password_screens/find_password_screen.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/keyword_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';

class LoginScreen extends StatefulWidget {
  final bool showBackButton;

  const LoginScreen({super.key, this.showBackButton = false});

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
        body: Stack(
          children: [
            Padding(
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
                          SvgPicture.asset(
                            'assets/login_image.svg',
                            width: 350.w,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "틈 사이로 발견한 새로운 문화생활",
                            style: AppTypography.body3.copyWith(
                              color: AppColors.primary400,
                            ),
                          ),
                          SizedBox(height: 40.h),
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
                                colorFilter: ColorFilter.mode(
                                  _isPasswordError
                                      ? AppColors.gray700
                                      : !_obsecureText && !_isPasswordError
                                      ? AppColors.primary400
                                      : AppColors.gray500,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ButtonSolid(
                            text: _isLoading ? '로그인 중...' : '로그인',
                            textColor: AppColors.gray900,
                            boxColor: AppColors.primary400,
                            onTap: _login,
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
                            onTap: () {
                              pushToScreen(context, SignUpScreen());
                            },
                          ),
                          SizedBox(height: 24.h),
                          GestureDetector(
                            child: Text(
                              '비밀번호 찾기',
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.gray700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.gray700,
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
                    onTap: () async {
                      if (widget.showBackButton) {
                        Navigator.pop(context);
                        return;
                      }
                      await TokenStore.instance.clear();
                      ProgramScrapStore.instance.clear(notify: false);
                      UserPreferenceStore.instance.clear();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationScreen(
                            initialHomeScreenType: ScreenTypes.entire,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
            if (widget.showBackButton)
              Positioned(
                left: 20.w,
                top: 82.h,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleBack,
                  child: SizedBox(
                    width: 32.r,
                    height: 32.r,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/arrow_left.svg',
                        width: 24.r,
                        height: 24.r,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
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
    Navigator.of(context, rootNavigator: true).maybePop();
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
