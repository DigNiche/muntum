import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/mock_user_data.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/keyword_screen.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/utils/app_toast.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50.h),
                    AppBarWidget(
                      centerType: AppBarCenterType.none,
                      leadingIcon: 'arrow_left.svg',
                      leadingColor: AppColors.gray200,
                      onLeadingTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(height: 32.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "닉네임\n생성하기",
                            style: AppTypography.display.copyWith(
                              color: AppColors.gray200,
                            ),
                          ),
                          SizedBox(height: 13.h),
                          Text(
                            "닉네임은 가입 후에도\n마이페이지에서 수정할 수 있어요.",
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.gray200,
                            ),
                          ),
                          SizedBox(height: 30.h),
                          TextFieldWidget(
                            hintText: '닉네임을 입력해 주세요.',
                            controller: _controller,
                            obscureText: false,
                            isError: _isError,
                            errorText: (_controller.text.length > 50)
                                ? '닉네임이 50자를 초과합니다.'
                                : '중복되는 닉네임 입니다.',
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "(${_controller.text.length}/50)",
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0.w),
              child: ButtonSolid(
                text: _isLoading ? '저장 중...' : '다음으로',
                textColor: AppColors.gray900,
                boxColor: AppColors.primary400,
                onTap: _saveNickname,
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNickname() async {
    if (_isLoading) return;
    final nickname = _controller.text.trim();
    if (nickname.isEmpty || nickname.length > 50 || nickname.contains(' ')) {
      setState(() => _isError = true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      if (ApiConfig.hasBaseUrl) {
        await UserService().updateNickname(nickname);
      } else {
        MockUserSession.instance.updateNickname(nickname);
      }
      if (!mounted) return;
      pushToScreen(context, KeywordScreen());
    } catch (error) {
      if (!mounted) return;
      setState(() => _isError = true);
      showAppToast(context, '$error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
