import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/utils/app_toast.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _currentFocusNode = FocusNode();
  final FocusNode _newFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  bool _currentObscureText = true;
  bool _newObscureText = true;
  bool _confirmObscureText = true;
  bool _currentPasswordError = false;
  bool _newPasswordError = false;
  bool _confirmPasswordError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(() {
      setState(() => _currentPasswordError = false);
    });
    _newPasswordController.addListener(() {
      setState(() => _newPasswordError = false);
    });
    _confirmPasswordController.addListener(() {
      setState(() => _confirmPasswordError = false);
    });
    for (final focusNode in [
      _currentFocusNode,
      _newFocusNode,
      _confirmFocusNode,
    ]) {
      focusNode.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocusNode.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _currentPasswordController.text.isNotEmpty &&
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      !_isSaving;

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }

  Future<void> _submit() async {
    if (!_canSave) return;
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _isSaving = true;
      _currentPasswordError = false;
      _newPasswordError = false;
      _confirmPasswordError = false;
    });

    final nextPasswordError = !_isValidPassword(newPassword);
    final nextConfirmError = newPassword != confirmPassword;
    if (nextPasswordError || nextConfirmError) {
      setState(() {
        _newPasswordError = nextPasswordError;
        _confirmPasswordError = nextConfirmError;
        _isSaving = false;
      });
      return;
    }

    try {
      if (ApiConfig.hasBaseUrl) {
        await UserService().changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }
      if (!mounted) return;
      showAppToast(context, '비밀번호가 변경되었습니다.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentPasswordError = true;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '비밀번호 변경',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
            trailing: GestureDetector(
              onTap: _canSave ? _submit : null,
              behavior: HitTestBehavior.opaque,
              child: Text(
                _isSaving ? '저장 중' : '저장',
                style: AppTypography.button2.copyWith(
                  color: _canSave ? AppColors.gray900 : AppColors.gray400,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
              child: Column(
                children: [
                  _PasswordChangeField(
                    hintText: '현재 비밀번호',
                    controller: _currentPasswordController,
                    focusNode: _currentFocusNode,
                    obscureText: _currentObscureText,
                    isError: _currentPasswordError,
                    errorText: '비밀번호가 일치하지 않습니다.',
                    onVisibilityTap: () {
                      setState(
                        () => _currentObscureText = !_currentObscureText,
                      );
                    },
                    onClearTap: () => _currentPasswordController.clear(),
                  ),
                  SizedBox(height: 16.h),
                  _PasswordChangeField(
                    hintText: '새 비밀번호',
                    controller: _newPasswordController,
                    focusNode: _newFocusNode,
                    obscureText: _newObscureText,
                    isError: _newPasswordError,
                    errorText: '비밀번호가 조건에 맞지 않습니다.(8자 이상)',
                    onVisibilityTap: () {
                      setState(() => _newObscureText = !_newObscureText);
                    },
                    onClearTap: () => _newPasswordController.clear(),
                  ),
                  SizedBox(height: 16.h),
                  _PasswordChangeField(
                    hintText: '새 비밀번호',
                    controller: _confirmPasswordController,
                    focusNode: _confirmFocusNode,
                    obscureText: _confirmObscureText,
                    isError: _confirmPasswordError,
                    errorText: '비밀번호가 일치하지 않습니다.',
                    onVisibilityTap: () {
                      setState(
                        () => _confirmObscureText = !_confirmObscureText,
                      );
                    },
                    onClearTap: () => _confirmPasswordController.clear(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordChangeField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final bool isError;
  final String errorText;
  final VoidCallback onVisibilityTap;
  final VoidCallback onClearTap;

  const _PasswordChangeField({
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.isError,
    required this.errorText,
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
              hintText: hintText,
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
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: BorderSide(color: borderColor, width: 1.w),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: BorderSide(color: borderColor, width: 1.w),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                borderSide: BorderSide(color: borderColor, width: 1.w),
              ),
            ),
          ),
        ),
        if (isError) ...[
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  errorText,
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
}
