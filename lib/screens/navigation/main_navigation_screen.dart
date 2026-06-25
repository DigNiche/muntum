import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: AppColors.lineNormal, width: 1.0.sp),
          color: AppColors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavTab(icon: 'explore-filled.svg', text: '발견', isActive: true),
            NavTab(icon: 'location-filled.svg', text: '지도', isActive: false),
            NavTab(icon: 'scrap-filled.svg', text: '스크랩', isActive: false),
            NavTab(icon: 'profile-filled.svg', text: '프로필', isActive: false),
          ],
        ),
      ),
    );
  }
}

class NavTab extends StatelessWidget {
  final String icon;
  final String text;
  final bool isActive;

  final Color activeColor = AppColors.gray900;
  final Color nonActiveColor = AppColors.gray500;
  const NavTab({
    super.key,
    required this.icon,
    required this.text,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 84.h,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          children: [
            SvgPicture.asset(
              'assets/icons/$icon',
              height: 24.sp,
              width: 24.sp,
              color: isActive ? activeColor : nonActiveColor,
            ),
            SizedBox(height: 2.h),
            Text(
              text,
              style: AppTypography.caption3.copyWith(
                color: isActive ? activeColor : nonActiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
