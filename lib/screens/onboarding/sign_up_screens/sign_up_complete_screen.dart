import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';

class SignUpCompleteScreen extends StatelessWidget {
  const SignUpCompleteScreen({super.key});

  void _goToNickname(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const NicknameScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 48.h),
              child: Column(
                children: [
                  const Spacer(),
                  Lottie.asset(
                    'assets/lottie/signup_complete.lottie',
                    width: 140.w,
                    height: 140.w,
                    repeat: false,
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    '회원가입이 완료되었어요!',
                    textAlign: TextAlign.center,
                    style: AppTypography.title4.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '닉네임과 취향 키워드를 설정하고\n나에게 맞는 프로그램을 만나보세요.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  const Spacer(),
                  ButtonSolid(
                    text: '취향 설정하기',
                    textColor: AppColors.gray900,
                    boxColor: AppColors.primary400,
                    onTap: () => _goToNickname(context),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
