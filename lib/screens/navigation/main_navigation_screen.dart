import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/app_color_transition.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/bookmark/bookmark_screen.dart';
import 'package:muntum/screens/home/entire_screen.dart';
import 'package:muntum/screens/home/my_niche_screen.dart';
import 'package:muntum/screens/map/map_screen.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/mypage/report_detail_screen.dart';
import 'package:muntum/screens/mypage/reportlist_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final ReportModel? initialReportDetail;
  final ProgramModel? initialMapProgram;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialReportDetail,
    this.initialMapProgram,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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

  Widget _buildAnimatedTab({required int index, required Widget child}) {
    final isActive = _selectedIndex == index;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isActive,
        child: ExcludeSemantics(
          excluding: !isActive,
          child: AnimatedOpacity(
            duration: AppColorTransition.duration,
            curve: AppColorTransition.curve,
            opacity: isActive ? 1 : 0,
            child: TickerMode(enabled: isActive, child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool useDarkTheme) {
    final androidBottomInset = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.viewPaddingOf(context).bottom
        : 0.0;
    final navigationHeight = androidBottomInset > 0
        ? 64.h + androidBottomInset
        : 84.h;

    return SizedBox(
      height: navigationHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: AppColorTransition.duration,
            curve: AppColorTransition.curve,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: useDarkTheme
                      ? AppColors.gray900
                      : AppColors.lineNormal,
                  width: 1.sp,
                ),
              ),
              color: useDarkTheme
                  ? const Color(0xFF181818)
                  : AppColors.white.withValues(alpha: 0.93),
            ),
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: defaultTargetPlatform == TargetPlatform.android,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NavTab(
                    icon: 'interests.svg',
                    text: '내취향',
                    isActive: _selectedIndex == 0,
                    useDarkTheme: useDarkTheme,
                    onTap: () => _onTabTap(0),
                  ),
                  NavTab(
                    icon: 'page_menu_ios.svg',
                    text: '전체',
                    isActive: _selectedIndex == 1,
                    useDarkTheme: useDarkTheme,
                    onTap: () => _onTabTap(1),
                  ),
                  NavTab(
                    icon: 'location-filled.svg',
                    text: '지도',
                    isActive: _selectedIndex == 2,
                    useDarkTheme: useDarkTheme,
                    onTap: () => _onTabTap(2),
                  ),
                  NavTab(
                    icon: 'scrap-filled.svg',
                    text: '스크랩',
                    isActive: _selectedIndex == 3,
                    useDarkTheme: useDarkTheme,
                    onTap: () => _onTabTap(3),
                  ),
                  NavTab(
                    icon: 'profile-filled.svg',
                    text: '프로필',
                    isActive: _selectedIndex == 4,
                    useDarkTheme: useDarkTheme,
                    onTap: () => _onTabTap(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useDarkBottomNavigation = _selectedIndex == 0;

    return Scaffold(
      body: AnimatedContainer(
        duration: AppColorTransition.duration,
        curve: AppColorTransition.curve,
        color: useDarkBottomNavigation
            ? AppColors.backgroundDark
            : AppColors.white,
        child: Stack(
          children: [
            _buildAnimatedTab(
              index: 0,
              child: MyNicheScreen(isActive: _selectedIndex == 0),
            ),
            _buildAnimatedTab(
              index: 1,
              child: EntireScreen(isActive: _selectedIndex == 1),
            ),
            _buildAnimatedTab(
              index: 2,
              child: MapScreen(
                isActive: _selectedIndex == 2,
                initialProgram: widget.initialMapProgram,
                onBack: widget.initialMapProgram == null
                    ? null
                    : () => Navigator.pop(context),
              ),
            ),
            _buildAnimatedTab(
              index: 3,
              child: BookmarkScreen(isActive: _selectedIndex == 3),
            ),
            _buildAnimatedTab(index: 4, child: const ProfileScreen()),
          ],
        ),
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
        child: AppColorTransition(
          color: targetColor,
          builder: (context, color, child) {
            return Container(
              height: double.infinity,
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
