import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/pre_update.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/terms_detail_screen.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/keyword_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up.dart';
import 'package:muntum/services/apple_auth_service.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';
import 'package:muntum/utils/app_toast.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class InitialScreen extends StatefulWidget {
  final bool showBackButton;

  const InitialScreen({super.key, this.showBackButton = false});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isAppleLoading = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              if (widget.showBackButton)
                Column(
                  children: [
                    SizedBox(height: 50.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
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
              const Spacer(),
              SvgPicture.asset(
                'assets/login_image.svg',
                width: 350.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20.h),
              Text(
                '내 주변의 문화라이프',
                style: AppTypography.title4.copyWith(color: AppColors.white),
              ),
              const Spacer(),
              ButtonSolid(
                text: '이메일로 로그인',
                textColor: AppColors.white,
                boxColor: Colors.transparent,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.25),
                  width: 1.w,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              if (showSocialLogin &&
                  defaultTargetPlatform == TargetPlatform.iOS) ...[
                SizedBox(height: 12.h),
                ButtonSolid(
                  leading: Text(
                    '',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 24.sp,
                      height: 1,
                    ),
                  ),
                  border: Border.all(color: Colors.transparent, width: 1.w),
                  text: _isAppleLoading ? 'Apple 로그인 중...' : 'Apple로 시작하기',
                  textColor: AppColors.black,
                  boxColor: AppColors.white,
                  onTap: _loginWithApple,
                ),
              ],
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TextAction(text: '둘러보기', onTap: _browseWithoutLogin),
                  Container(
                    width: 1.w,
                    height: 14.h,
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    color: AppColors.gray700,
                  ),
                  _TextAction(
                    text: '회원가입',
                    onTap: () => _push(const SignUpScreen()),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              Text(
                '회원가입 시 문틈의 정책 및 약관에 동의합니다.',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TermsLink(
                    text: '서비스 이용약관',
                    onTap: () =>
                        _push(const TermsDetailScreen(title: '서비스 이용약관')),
                  ),
                  SizedBox(width: 12.w),
                  _TermsLink(
                    text: '개인정보 처리방침',
                    onTap: () =>
                        _push(const TermsDetailScreen(title: '개인정보 처리방침')),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _browseWithoutLogin() async {
    if (widget.showBackButton) {
      Navigator.pop(context);
      return;
    }

    await TokenStore.instance.clear();
    ProgramScrapStore.instance.clear(notify: false);
    UserPreferenceStore.instance.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(initialIndex: 1),
      ),
    );
  }

  Future<void> _loginWithApple() async {
    if (_isAppleLoading) return;
    setState(() => _isAppleLoading = true);
    try {
      final request = await AppleAuthService().authorize();
      final session = await AuthService().socialLogin(request);
      if (!mounted) return;
      await _routeAfterLogin(session.nickname);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (!mounted || error.code == AuthorizationErrorCode.canceled) return;
      if (kDebugMode) {
        debugPrint(
          'Apple authorization failed: ${error.code.name} ${error.message}',
        );
      }
      showAppToast(context, 'Apple 로그인에 실패했습니다. 다시 시도해주세요.', isError: true);
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        ApiException(code: '007') => '잘못된 요청입니다.',
        ApiException(code: 'A017') => '소셜 로그인 가입에는 이메일 정보가 필요합니다.',
        ApiException(code: 'A018') => '지원하지 않는 소셜 로그인 제공자입니다.',
        ApiException(code: 'A016') => '유효하지 않은 소셜 로그인 토큰입니다.',
        ApiException(code: 'A004') => '비활성화된 계정입니다.',
        ApiException(code: 'A001') => '이미 사용 중인 이메일입니다.',
        ApiException(code: 'T005') => '게시된 약관이 존재하지 않습니다.',
        ApiException(code: 'E001') => '서버 오류가 발생했습니다.',
        _ => 'Apple 로그인에 실패했습니다. 다시 시도해주세요.',
      };
      showAppToast(context, message, isError: true);
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _routeAfterLogin(String? nickname) async {
    if (nickname == null || nickname.trim().isEmpty) {
      _push(const NicknameScreen());
      return;
    }

    final keywords = await TasteService().fetchMyKeywords();
    UserPreferenceStore.instance.updateKeywords(
      keywords.selectedKeywords.map((keyword) => keyword.name),
    );
    if (!mounted) return;
    if (keywords.selectedKeywords.length < 3) {
      _push(const KeywordScreen());
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }
}

class _TextAction extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _TextAction({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        text,
        style: AppTypography.button3.copyWith(color: AppColors.gray400),
      ),
    );
  }
}

class _TermsLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _TermsLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: AppTypography.caption1.copyWith(
          color: AppColors.gray700,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.gray600,
        ),
      ),
    );
  }
}
