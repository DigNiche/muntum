import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';

class SignUpCompleteScreen extends StatelessWidget {
  const SignUpCompleteScreen({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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
                  style: AppTypography.title4.copyWith(color: AppColors.white),
                ),
                SizedBox(height: 8.h),
                Text(
                  '가입한 계정 정보로\n다시 로그인을 진행해주세요.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body2.copyWith(color: AppColors.gray500),
                ),
                const Spacer(),
                ButtonSolid(
                  text: '로그인 하기',
                  textColor: AppColors.gray900,
                  boxColor: AppColors.primary400,
                  onTap: () => _goToLogin(context),
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
