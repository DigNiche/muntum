import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/bookmark/bookmark_screen.dart';
import 'package:muntum/screens/home/home_screen.dart';
import 'package:muntum/screens/map/map_screen.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onTabTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          MapScreen(isActive: _selectedIndex == 1),
          const BookmarkScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: AppColors.lineNormal, width: 1.0.sp),
          color: AppColors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavTab(
              icon: 'explore-filled.svg',
              text: '발견',
              isActive: _selectedIndex == 0,
              onTap: () => _onTabTap(0),
            ),
            NavTab(
              icon: 'location-filled.svg',
              text: '지도',
              isActive: _selectedIndex == 1,
              onTap: () => _onTabTap(1),
            ),
            NavTab(
              icon: 'scrap-filled.svg',
              text: '스크랩',
              isActive: _selectedIndex == 2,
              onTap: () => _onTabTap(2),
            ),
            NavTab(
              icon: 'profile-filled.svg',
              text: '프로필',
              isActive: _selectedIndex == 3,
              onTap: () => _onTabTap(3),
            ),
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
  final VoidCallback onTap;

  final Color activeColor = AppColors.gray900;
  final Color nonActiveColor = AppColors.gray500;
  const NavTab({
    super.key,
    required this.icon,
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 84.h,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              SizedBox(
                width: 24.w,
                height: 24.h,
                child: SvgPicture.asset(
                  'assets/icons/$icon',
                  height: 20.sp,
                  width: 20.sp,
                  colorFilter: ColorFilter.mode(
                    isActive ? activeColor : nonActiveColor,
                    BlendMode.srcIn,
                  ),
                ),
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
      ),
    );
  }
}
