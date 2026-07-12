import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/home/home_screen.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';

class ReportCompleteScreen extends StatelessWidget {
  final ReportModel report;

  const ReportCompleteScreen({super.key, required this.report});

  void _goToEntireHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(
          initialIndex: 0,
          initialHomeScreenType: ScreenTypes.entire,
        ),
      ),
      (route) => false,
    );
  }

  void _goToReportDetail(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MainNavigationScreen(initialIndex: 3, initialReportDetail: report),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 50.h),
              AppBarWidget(
                centerType: AppBarCenterType.none,
                leadingIcon: 'close.svg',
                onLeadingTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/lottie/report_complete.lottie',
                      width: 140.w,
                      height: 140.w,
                      repeat: false,
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      '제보해주셔서 감사해요!',
                      style: AppTypography.title4.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '관리자 검토 후 등록될 예정이에요.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 152.h),
            ],
          ),
          Positioned(
            left: 20.w,
            right: 20.w,
            bottom: 48.h,
            child: Column(
              children: [
                ButtonSolid(
                  text: '홈으로',
                  textColor: AppColors.white,
                  boxColor: AppColors.black,
                  onTap: () => _goToEntireHome(context),
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                ),
                SizedBox(height: 14.h),
                GestureDetector(
                  onTap: () => _goToReportDetail(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      '제보 내용 확인하기',
                      style: AppTypography.button3.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
