import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/mock_user_data.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/utils/app_toast.dart';

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

  bool get _canContinue => _passwordController.text.isNotEmpty && !_isVerifying;

  Future<void> _goToReason() async {
    if (!_canContinue) return;
    setState(() {
      _isVerifying = true;
      _isError = false;
    });

    final password = _passwordController.text;
    try {
      if (ApiConfig.hasBaseUrl) {
        final email = await TokenStore.instance.readEmail();
        if (email == null || email.isEmpty) {
          throw Exception('로그인 정보를 확인할 수 없어요. 다시 로그인해주세요.');
        }
        await AuthService().login(email: email, password: password);
      }
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isVerifying = false;
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawReasonScreen(password: password),
      ),
    );
    if (mounted) {
      setState(() => _isVerifying = false);
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
              onTap: _goToReason,
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

class WithdrawReasonScreen extends StatefulWidget {
  final String password;

  const WithdrawReasonScreen({super.key, required this.password});

  @override
  State<WithdrawReasonScreen> createState() => _WithdrawReasonScreenState();
}

class _WithdrawReasonScreenState extends State<WithdrawReasonScreen> {
  final List<String> _reasons = const [
    '더 이상 사용하지 않아요',
    '원하는 프로그램이 없어요',
    '앱 사용이 불편해요',
    '기타',
  ];
  final Set<String> _selectedReasons = {};
  bool _isWithdrawing = false;

  bool get _canSubmit => _selectedReasons.isNotEmpty && !_isWithdrawing;

  Future<void> _confirmWithdraw() async {
    if (!_canSubmit) return;
    await showPopupWidget(
      context: context,
      title: '정말 탈퇴하시겠습니까?',
      description: '모든 활동 정보가 삭제되며, 복구할 수 없습니다.',
      text1: '아니요',
      text2: _isWithdrawing ? '탈퇴 중...' : '탈퇴하기',
      text2Color: AppColors.error,
      onText1Tap: () => Navigator.pop(context),
      onText2Tap: () async {
        Navigator.pop(context);
        await _withdraw();
      },
    );
  }

  Future<void> _withdraw() async {
    if (_isWithdrawing) return;
    setState(() => _isWithdrawing = true);
    try {
      if (ApiConfig.hasBaseUrl) {
        await UserService().withdraw(password: widget.password);
      }
      MockUserSession.instance.logout();
      await TokenStore.instance.clear();
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
            padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 40.h),
            child: Text(
              '탈퇴하시는\n이유가 무엇인가요?',
              style: AppTypography.title3.copyWith(color: AppColors.gray900),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: _reasons.length,
              separatorBuilder: (context, index) => SizedBox(height: 28.h),
              itemBuilder: (context, index) {
                final reason = _reasons[index];
                final isSelected = _selectedReasons.contains(reason);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedReasons.remove(reason);
                      } else {
                        _selectedReasons.add(reason);
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        reason,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, size: 20.sp, color: AppColors.gray900)
                      else
                        SizedBox(width: 20.w, height: 20.w),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: ButtonSolid(
              text: _isWithdrawing ? '탈퇴 중...' : '탈퇴하기',
              textColor: AppColors.white,
              boxColor: _canSubmit ? AppColors.black : AppColors.gray300,
              onTap: _canSubmit ? _confirmWithdraw : null,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 36.h),
            child: ButtonSolid(
              text: '조금 더 이용하기',
              textColor: AppColors.gray700,
              boxColor: AppColors.white,
              border: Border.all(color: AppColors.lineStrong, width: 1.w),
              onTap: () => Navigator.pop(context),
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
        ],
      ),
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
            style: AppTypography.title3.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 14.h),
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
