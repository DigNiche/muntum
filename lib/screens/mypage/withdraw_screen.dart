import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/services/apple_auth_service.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';
import 'package:muntum/utils/app_toast.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: TokenStore.instance.readAuthProvider(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == 'APPLE'
            ? const WithdrawAppleScreen()
            : const WithdrawPasswordScreen();
      },
    );
  }
}

class WithdrawAppleScreen extends StatefulWidget {
  const WithdrawAppleScreen({super.key});

  @override
  State<WithdrawAppleScreen> createState() => _WithdrawAppleScreenState();
}

class _WithdrawAppleScreenState extends State<WithdrawAppleScreen> {
  bool _isAuthenticating = false;
  bool _isWithdrawing = false;

  Future<void> _authenticateWithApple() async {
    if (_isAuthenticating || _isWithdrawing) return;
    setState(() => _isAuthenticating = true);
    try {
      final authorization = await AppleAuthService().authorize();
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
      await _showWithdrawConfirmation(authorization);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (!mounted || error.code == AuthorizationErrorCode.canceled) return;
      showAppToast(context, 'Apple 본인인증에 실패했습니다. 다시 시도해주세요.', isError: true);
    } catch (error) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('Apple withdrawal authentication failed: $error');
      }
      showAppToast(context, 'Apple 본인인증에 실패했습니다. 다시 시도해주세요.', isError: true);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _showWithdrawConfirmation(
    SocialLoginRequest authorization,
  ) async {
    await showPopupWidget(
      context: context,
      title: '정말 탈퇴하시겠습니까?',
      description: '모든 활동 정보가 삭제되며, 복구할 수 없습니다.',
      text1: '아니요',
      text2: '탈퇴하기',
      text2Color: AppColors.error,
      onText1Tap: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
      onText2Tap: () async {
        Navigator.of(context, rootNavigator: true).pop();
        await _withdraw(authorization);
      },
    );
  }

  Future<void> _withdraw(SocialLoginRequest authorization) async {
    if (_isWithdrawing) return;
    setState(() => _isWithdrawing = true);
    try {
      await AppleAuthService().withdraw(authorization: authorization);
      await TokenStore.instance.clear();
      ProgramScrapStore.instance.clear(notify: false);
      UserPreferenceStore.instance.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WithdrawCompleteScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error', isError: true);
      setState(() => _isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '회원 탈퇴',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
            child: Text(
              '안전한 탈퇴를 위해\n본인확인이 필요해요.',
              style: AppTypography.title1.copyWith(color: AppColors.black),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 0),
            child: ButtonSolid(
              leading: Text(
                '',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20.sp,
                  height: 1,
                ),
              ),
              text: _isAuthenticating || _isWithdrawing
                  ? 'Apple로 확인 중...'
                  : 'Apple로 본인인증',
              textColor: AppColors.black,
              boxColor: AppColors.white,
              border: BoxBorder.all(color: AppColors.gray200, width: 1.w),
              onTap: _authenticateWithApple,
            ),
          ),
        ],
      ),
    );
  }
}

class WithdrawPasswordScreen extends StatefulWidget {
  const WithdrawPasswordScreen({super.key});

  @override
  State<WithdrawPasswordScreen> createState() => _WithdrawPasswordScreenState();
}

class _WithdrawPasswordScreenState extends State<WithdrawPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscureText = true;
  bool _isError = false;
  bool _isVerifying = false;
  bool _isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() => _isError = false));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _passwordController.text.isNotEmpty && !_isVerifying && !_isWithdrawing;

  Future<void> _confirmWithdraw() async {
    if (!_canContinue) return;
    setState(() {
      _isVerifying = true;
      _isError = false;
    });

    final password = _passwordController.text;
    try {
      final email = await TokenStore.instance.readEmail();
      if (email == null || email.isEmpty) {
        throw Exception('로그인 정보를 확인할 수 없어요. 다시 로그인해주세요.');
      }
      await AuthService().login(email: email, password: password);
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isVerifying = false;
      });
      return;
    }

    setState(() => _isVerifying = false);
    await showPopupWidget(
      context: context,
      title: '정말 탈퇴하시겠습니까?',
      description: '모든 활동 정보가 삭제되며, 복구할 수 없습니다.',
      text1: '아니요',
      text2: _isWithdrawing ? '탈퇴 중...' : '탈퇴하기',
      text2Color: AppColors.error,
      onText1Tap: () {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context);
      },
      onText2Tap: () async {
        Navigator.of(context, rootNavigator: true).pop();
        await _withdraw(password);
      },
    );
  }

  Future<void> _withdraw(String password) async {
    if (_isWithdrawing) return;
    setState(() => _isWithdrawing = true);
    try {
      await UserService().withdraw(password: password);
      await TokenStore.instance.clear();
      ProgramScrapStore.instance.clear(notify: false);
      UserPreferenceStore.instance.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WithdrawCompleteScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error');
      setState(() => _isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '회원 탈퇴',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 0),
            child: Text(
              '가입한 계정의\n비밀번호를 입력해 주세요.',
              style: AppTypography.title3.copyWith(color: AppColors.gray900),
            ),
          ),
          SizedBox(height: 48.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _WithdrawPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscureText,
              isError: _isError,
              onVisibilityTap: () {
                setState(() => _obscureText = !_obscureText);
              },
              onClearTap: () => _passwordController.clear(),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 48.h),
            child: ButtonSolid(
              text: _isVerifying ? '확인 중...' : '확인',
              textColor: _canContinue ? AppColors.white : AppColors.gray400,
              boxColor: _canContinue ? AppColors.black : AppColors.gray100,
              onTap: _confirmWithdraw,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final bool isError;
  final VoidCallback onVisibilityTap;
  final VoidCallback onClearTap;

  const _WithdrawPasswordField({
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.isError,
    required this.onVisibilityTap,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    final borderColor = isError
        ? AppColors.error.withValues(alpha: 0.65)
        : focusNode.hasFocus
        ? AppColors.primary400
        : AppColors.lineStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48.h,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            cursorColor: AppColors.gray900,
            style: AppTypography.body1.copyWith(color: AppColors.gray900),
            decoration: InputDecoration(
              hintText: '비밀번호를 입력해 주세요.',
              hintStyle: AppTypography.body1.copyWith(color: AppColors.gray300),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasText)
                      GestureDetector(
                        onTap: onClearTap,
                        child: SvgPicture.asset(
                          'assets/icons/circle_close.svg',
                          width: 20.w,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gray400,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    if (!isError) ...[
                      if (hasText) SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: onVisibilityTap,
                        child: SvgPicture.asset(
                          obscureText
                              ? 'assets/icons/visibility-false.svg'
                              : 'assets/icons/visibility.svg',
                          width: 20.w,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gray400,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: BorderSide(color: borderColor, width: 1.5.w),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: BorderSide(color: borderColor, width: 1.5.w),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: BorderSide(color: borderColor, width: 1.5.w),
              ),
            ),
          ),
        ),
        if (isError) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/error.svg',
                width: 16.w,
                colorFilter: const ColorFilter.mode(
                  AppColors.error,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '비밀번호가 일치하지 않아요',
                style: AppTypography.caption2.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class WithdrawCompleteScreen extends StatelessWidget {
  const WithdrawCompleteScreen({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          const Spacer(),
          Text(
            '탈퇴가 완료됐어요',
            textAlign: TextAlign.center,
            style: AppTypography.title4.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 24.h),
          Text(
            '그동안 문틈을 이용해주셔서 감사합니다.',
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 48.h),
            child: ButtonSolid(
              text: '완료',
              textColor: AppColors.white,
              boxColor: AppColors.black,
              onTap: () => _goToLogin(context),
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
        ],
      ),
    );
  }
}
