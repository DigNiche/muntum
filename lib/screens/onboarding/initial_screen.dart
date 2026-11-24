import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/services/terms_service.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/keyword_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up_terms_sheet.dart';
import 'package:muntum/services/apple_auth_service.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/kakao_auth_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';
import 'package:muntum/utils/app_toast.dart';
import 'package:muntum/utils/apple_identity_diagnostics.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class InitialScreen extends StatefulWidget {
  final bool showBackButton;
  final AppleAuthService? appleAuthService;
  final KakaoAuthService? kakaoAuthService;
  final AuthService? authService;

  /// The injectable published-terms service used before account creation.
  final TermsService? termsService;

  const InitialScreen({
    super.key,
    this.showBackButton = false,
    this.appleAuthService,
    this.kakaoAuthService,
    this.authService,
    this.termsService,
  });

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  SocialAuthProvider? _activeSocialProvider;

  bool get _isAppleLoading => _activeSocialProvider == SocialAuthProvider.apple;
  bool get _isKakaoLoading => _activeSocialProvider == SocialAuthProvider.kakao;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: defaultTargetPlatform == TargetPlatform.android,
          child: Padding(
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
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
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
                    onTap: _activeSocialProvider == null
                        ? _loginWithApple
                        : null,
                  ),
                ],
                SizedBox(height: 12.h),
                ButtonSolid(
                  text: _isKakaoLoading ? '카카오 로그인 중...' : '카카오 로그인',
                  textColor: AppColors.black,
                  boxColor: const Color(0xFFFEE500),
                  leading: SvgPicture.asset(
                    'assets/icons/kakao_login.svg',
                    width: 16.r,
                    height: 16.r,
                  ),
                  onTap: _activeSocialProvider == null ? _loginWithKakao : null,
                ),
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
                    _TextAction(text: '회원가입', onTap: _startSignUp),
                  ],
                ),
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _startSignUp() async {
    final consent = await showSignUpTermsSheet(
      context,
      service: widget.termsService,
    );
    if (!mounted || consent == null) return;
    _push(SignUpScreen(signupConsent: consent));
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
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  Future<void> _loginWithApple() => _loginWithSocial(SocialAuthProvider.apple);

  Future<void> _loginWithKakao() => _loginWithSocial(SocialAuthProvider.kakao);

  Future<void> _loginWithSocial(SocialAuthProvider provider) async {
    if (_activeSocialProvider != null) return;
    setState(() => _activeSocialProvider = provider);
    final providerName = provider == SocialAuthProvider.apple ? 'Apple' : '카카오';
    var stage = provider == SocialAuthProvider.apple
        ? 'apple_authorization'
        : 'kakao_authorization';
    AppleIdentityDiagnostics? appleDiagnostics;
    try {
      final request = provider == SocialAuthProvider.apple
          ? await (widget.appleAuthService ?? AppleAuthService()).authorize()
          : await (widget.kakaoAuthService ?? KakaoAuthService()).authorize();
      if (!mounted) return;
      if (provider == SocialAuthProvider.apple) {
        appleDiagnostics = appleIdentityDiagnostics(request.token);
      }
      stage = 'social_prepare';
      final auth = widget.authService ?? AuthService();
      final prepared = await auth.prepareSocial(request);
      if (!mounted) return;
      if (prepared.authentication == null) stage = 'social_signup';
      final session =
          prepared.authentication ??
          await _completeSocialSignup(auth, request.provider, prepared);
      if (!mounted || session == null) return;
      stage = 'post_login';
      await _routeAfterLogin(session.nickname);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (!mounted || error.code == AuthorizationErrorCode.canceled) return;
      _showSocialLoginFailure(
        provider: provider,
        message: 'Apple 로그인에 실패했습니다. 다시 시도해주세요.',
        code: error.code.name,
        stage: stage,
        appleDiagnostics: appleDiagnostics,
      );
    } on KakaoLoginCanceledException {
      return;
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
        ApiException(statusCode: 404 || 405)
            when provider == SocialAuthProvider.kakao &&
                (stage == 'social_prepare' || stage == 'social_signup') =>
          '카카오 로그인 서버가 아직 준비되지 않았어요. 잠시 후 다시 시도해주세요.',
        KakaoLoginException(:final message) => message,
        ApiException(message: final message) when message.isNotEmpty => message,
        ApiException(code: 'E001') => '서버 오류가 발생했습니다.',
        _ => '$providerName 로그인에 실패했습니다. 다시 시도해주세요.',
      };
      _showSocialLoginFailure(
        provider: provider,
        message: message,
        code: switch (error) {
          ApiException(:final code) => code,
          KakaoLoginException(:final code) => code,
          _ => null,
        },
        statusCode: error is ApiException ? error.statusCode : null,
        stage: stage,
        appleDiagnostics: appleDiagnostics,
      );
    } finally {
      if (mounted) setState(() => _activeSocialProvider = null);
    }
  }

  Future<AuthSession?> _completeSocialSignup(
    AuthService auth,
    SocialAuthProvider provider,
    SocialPrepareResult prepared,
  ) async {
    final deadline = DateTime.now().add(Duration(seconds: prepared.expiresIn!));
    while (mounted) {
      final consent = await showSignUpTermsSheet(
        context,
        service: widget.termsService,
      );
      if (!mounted || consent == null) return null;
      if (!DateTime.now().isBefore(deadline)) {
        final providerName = provider == SocialAuthProvider.apple
            ? 'Apple'
            : '카카오';
        throw ApiException(
          code: 'A026',
          message: '소셜 회원가입 인증이 만료되었어요. $providerName 로그인부터 다시 시도해주세요.',
        );
      }
      try {
        return await auth.signupSocial(
          signupTicket: prepared.signupTicket!,
          provider: provider,
          signupConsent: consent,
        );
      } on ApiException catch (error) {
        if (!mounted || error.code != 'T007') rethrow;
        showAppToast(
          context,
          '약관이 변경되었어요. 최신 약관을 확인하고 다시 동의해주세요.',
          isError: true,
        );
      }
    }
    return null;
  }

  void _showSocialLoginFailure({
    required SocialAuthProvider provider,
    required String message,
    required String stage,
    String? code,
    int? statusCode,
    AppleIdentityDiagnostics? appleDiagnostics,
  }) {
    if (provider == SocialAuthProvider.apple) {
      _showAppleLoginFailure(
        message: message,
        stage: stage,
        code: code,
        statusCode: statusCode,
        appleDiagnostics: appleDiagnostics,
      );
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[muntum.kakao_login] stage=$stage code=${code ?? "unknown"} '
        'http=${statusCode ?? "unknown"}',
      );
    }
    showAppToast(
      context,
      '${code == null ? "" : "[$code] "}$message',
      isError: true,
    );
  }

  void _showAppleLoginFailure({
    required String message,
    required String stage,
    String? code,
    int? statusCode,
    AppleIdentityDiagnostics? appleDiagnostics,
  }) {
    final occurredAt = DateTime.now().toUtc();
    final timestamp = occurredAt.toIso8601String();
    if (kDebugMode) {
      debugPrint(
        '[muntum.apple_login] Apple login failed: '
        'stage=$stage code=${code ?? "unknown"} '
        'http=${statusCode ?? "unknown"} occurredAt=$timestamp '
        'sub=${appleDiagnostics?.sub ?? "unavailable"}',
        wrapWidth: null,
      );
      debugPrint(
        '[muntum.apple_login.claims] '
        'aud=${appleDiagnostics?.aud ?? "unavailable"} '
        'email=${appleDiagnostics?.email ?? "unavailable"}',
        wrapWidth: null,
      );
    }
    showAppToast(
      context,
      '${code == null ? "" : "[$code] "}$message',
      isError: true,
    );
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
