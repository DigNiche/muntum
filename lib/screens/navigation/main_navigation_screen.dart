import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/bookmark/bookmark_screen.dart';
import 'package:muntum/screens/home/home_screen.dart';
import 'package:muntum/screens/map/map_screen.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/mypage/report_detail_screen.dart';
import 'package:muntum/screens/mypage/reportlist_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final ScreenTypes initialHomeScreenType;
  final ReportModel? initialReportDetail;
  final ProgramModel? initialMapProgram;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialHomeScreenType = ScreenTypes.myNiche,
    this.initialReportDetail,
    this.initialMapProgram,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  late ScreenTypes _homeScreenType;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _homeScreenType = widget.initialHomeScreenType;
    if (widget.initialReportDetail != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportListScreen()),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReportDetailScreen(report: widget.initialReportDetail!),
          ),
        );
      });
    }
  }

  void _onTabTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onHomeScreenTypeChanged(ScreenTypes screenType) {
    if (_homeScreenType == screenType) return;
    setState(() => _homeScreenType = screenType);
  }

  Widget _buildBottomNavigationBar(bool useDarkTheme) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: useDarkTheme ? AppColors.gray900 : AppColors.lineNormal,
                width: 1.sp,
              ),
            ),
            color: useDarkTheme
                ? const Color(0xFF181818)
                : AppColors.white.withValues(alpha: 0.93),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NavTab(
                icon: 'explore-filled.svg',
                text: '발견',
                isActive: _selectedIndex == 0,
                useDarkTheme: useDarkTheme,
                onTap: () => _onTabTap(0),
              ),
              NavTab(
                icon: 'location-filled.svg',
                text: '지도',
                isActive: _selectedIndex == 1,
                useDarkTheme: useDarkTheme,
                onTap: () => _onTabTap(1),
              ),
              NavTab(
                icon: 'scrap-filled.svg',
                text: '스크랩',
                isActive: _selectedIndex == 2,
                useDarkTheme: useDarkTheme,
                onTap: () => _onTabTap(2),
              ),
              NavTab(
                icon: 'profile-filled.svg',
                text: '프로필',
                isActive: _selectedIndex == 3,
                useDarkTheme: useDarkTheme,
                onTap: () => _onTabTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useDarkBottomNavigation =
        _selectedIndex == 0 && _homeScreenType == ScreenTypes.myNiche;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            initialScreenType: widget.initialHomeScreenType,
            onScreenTypeChanged: _onHomeScreenTypeChanged,
          ),
          MapScreen(
            isActive: _selectedIndex == 1,
            initialProgram: widget.initialMapProgram,
            onBack: widget.initialMapProgram == null
                ? null
                : () => Navigator.pop(context),
          ),
          BookmarkScreen(isActive: _selectedIndex == 2),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: widget.initialMapProgram == null
          ? _buildBottomNavigationBar(useDarkBottomNavigation)
          : null,
    );
  }
}

class NavTab extends StatelessWidget {
  final String icon;
  final String text;
  final bool isActive;
  final bool useDarkTheme;
  final VoidCallback onTap;

  const NavTab({
    super.key,
    required this.icon,
    required this.text,
    required this.isActive,
    required this.useDarkTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final targetColor = isActive
        ? (useDarkTheme ? AppColors.white : AppColors.black)
        : (useDarkTheme ? AppColors.gray600 : AppColors.gray500);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          tween: ColorTween(end: targetColor),
          builder: (context, animatedColor, child) {
            final color = animatedColor ?? targetColor;
            return Container(
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
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    text,
                    style: AppTypography.caption3.copyWith(color: color),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
