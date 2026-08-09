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
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up_complete_screen.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/utils/app_toast.dart';

enum SignUpPasswordResult { restartEmailVerification }

class SignUpPasswordScreen extends StatefulWidget {
  final String email;
  final String signupToken;
  final AuthService? authService;

  const SignUpPasswordScreen({
    super.key,
    required this.email,
    required this.signupToken,
    this.authService,
  });

  @override
  State<SignUpPasswordScreen> createState() => _SignUpPasswordScreenState();
}

class _SignUpPasswordScreenState extends State<SignUpPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late final AuthService _authService;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordError = false;
  bool _isConfirmPasswordError = false;
  bool _isLoading = false;

  bool get _isValidPassword => RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
  ).hasMatch(_passwordController.text);

  bool get _canSubmit =>
      _isValidPassword &&
      _passwordController.text == _confirmPasswordController.text;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _passwordController.addListener(_handlePasswordChanged);
    _confirmPasswordController.addListener(_handlePasswordChanged);
    _passwordFocusNode.addListener(_refresh);
    _confirmPasswordFocusNode.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocusNode.requestFocus();
    });
  }

  void _handlePasswordChanged() {
    setState(() {
      _isPasswordError = false;
      _isConfirmPasswordError = false;
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_handlePasswordChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_handlePasswordChanged)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_refresh)
      ..dispose();
    _confirmPasswordFocusNode
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
                      '비밀번호를\n설정해주세요',
                      style: AppTypography.display.copyWith(
                        color: AppColors.gray200,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    TextFieldWidget(
                      hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      isError: _isPasswordError,
                      errorText: '영문, 숫자, 특수문자 포함 8자 이상이어야 합니다.',
                      suffixIcon: _VisibilityButton(
                        isVisible: !_obscurePassword,
                        isError: _isPasswordError,
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextFieldWidget(
                      hintText: '비밀번호를 재입력해 주세요.',
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: _obscureConfirmPassword,
                      isError: _isConfirmPasswordError,
                      errorText: '비밀번호가 일치하지 않습니다.',
                      suffixIcon: _VisibilityButton(
                        isVisible: !_obscureConfirmPassword,
                        isError: _isConfirmPasswordError,
                        onTap: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ButtonSolid(
                text: _isLoading ? '가입 중...' : '가입하기',
                textColor: _canSubmit && !_isLoading
                    ? AppColors.gray900
                    : AppColors.gray700,
                boxColor: _canSubmit && !_isLoading
                    ? AppColors.primary400
                    : const Color(0x1AF5F5F3),
                onTap: _canSubmit && !_isLoading ? _submit : null,
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isPasswordError = !_isValidPassword;
      _isConfirmPasswordError =
          _passwordController.text != _confirmPasswordController.text;
    });
    if (!_canSubmit || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signup(
        email: widget.email,
        password: _passwordController.text,
        signupToken: widget.signupToken,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignUpCompleteScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException && error.code == 'A022') {
        Navigator.pop(context, SignUpPasswordResult.restartEmailVerification);
        return;
      }
      final message = switch (error) {
        ApiException(code: 'A001') => '이미 가입된 이메일입니다.',
        ApiException(code: '007') => '회원가입 정보를 다시 확인해주세요.',
        ApiException(message: final message) when message.isNotEmpty => message,
        _ => '회원가입에 실패했습니다. 다시 시도해주세요.',
      };
      showAppToast(context, message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _VisibilityButton extends StatelessWidget {
  final bool isVisible;
  final bool isError;
  final VoidCallback onTap;

  const _VisibilityButton({
    required this.isVisible,
    required this.isError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        isVisible
            ? 'assets/icons/visibility.svg'
            : 'assets/icons/visibility-false.svg',
        width: 20.w,
        colorFilter: ColorFilter.mode(
          isError
              ? AppColors.gray700
              : isVisible
              ? AppColors.primary400
              : AppColors.gray600,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
