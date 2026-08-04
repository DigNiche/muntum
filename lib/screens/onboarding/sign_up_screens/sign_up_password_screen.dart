import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up_complete_screen.dart';

class SignUpPasswordScreen extends StatefulWidget {
  final String email;

  const SignUpPasswordScreen({super.key, required this.email});

  @override
  State<SignUpPasswordScreen> createState() => _SignUpPasswordScreenState();
}

class _SignUpPasswordScreenState extends State<SignUpPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordError = false;
  bool _isConfirmPasswordError = false;

  bool get _isValidPassword => RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
  ).hasMatch(_passwordController.text);

  bool get _canSubmit =>
      _isValidPassword &&
      _passwordController.text == _confirmPasswordController.text;

  @override
  void initState() {
    super.initState();
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
                text: '가입하기',
                textColor: _canSubmit ? AppColors.gray900 : AppColors.gray700,
                boxColor: _canSubmit
                    ? AppColors.primary400
                    : const Color(0x1AF5F5F3),
                onTap: _canSubmit ? _validatePassword : null,
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  void _validatePassword() {
    setState(() {
      _isPasswordError = !_isValidPassword;
      _isConfirmPasswordError =
          _passwordController.text != _confirmPasswordController.text;
    });

    // TODO: 회원가입 API 배포 후 email, password, signupToken을 전달합니다.
    // if valid
    pushToScreen(context, SignUpCompleteScreen());
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
