import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/bookmark/bookmark_screen.dart';
import 'package:muntum/screens/home/home_screen.dart';
import 'package:muntum/screens/map/map_screen.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/mypage/report_detail_screen.dart';
import 'package:muntum/screens/mypage/reportlist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final ScreenTypes initialHomeScreenType;
  final ReportModel? initialReportDetail;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialHomeScreenType = ScreenTypes.myNiche,
    this.initialReportDetail,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const String _pendingMyNicheCoachmarkKey =
      'pending_my_niche_coachmark';
  static const String _seenMyNicheCoachmarkKey = 'seen_my_niche_coachmark';

  late int _selectedIndex;
  late ScreenTypes _homeScreenType;
  bool _showMyNicheCoachmark = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _homeScreenType = widget.initialHomeScreenType;
    _loadCoachmarkState();
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

  Future<void> _loadCoachmarkState() async {
    final prefs = await SharedPreferences.getInstance();
    final isPending = prefs.getBool(_pendingMyNicheCoachmarkKey) ?? false;
    final hasSeen = prefs.getBool(_seenMyNicheCoachmarkKey) ?? false;
    if (!mounted || !isPending || hasSeen || widget.initialIndex != 0) return;
    setState(() => _showMyNicheCoachmark = true);
  }

  Future<void> _dismissMyNicheCoachmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingMyNicheCoachmarkKey, false);
    await prefs.setBool(_seenMyNicheCoachmarkKey, true);
    if (!mounted) return;
    setState(() => _showMyNicheCoachmark = false);
  }

  @override
  Widget build(BuildContext context) {
    final useDarkBottomNavigation =
        _selectedIndex == 0 && _homeScreenType == ScreenTypes.myNiche;

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeScreen(
                initialScreenType: widget.initialHomeScreenType,
                onScreenTypeChanged: _onHomeScreenTypeChanged,
              ),
              MapScreen(isActive: _selectedIndex == 1),
              BookmarkScreen(isActive: _selectedIndex == 2),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: useDarkBottomNavigation
                          ? AppColors.gray900
                          : AppColors.lineNormal,
                      width: 1.sp,
                    ),
                  ),
                  color: useDarkBottomNavigation
                      ? const Color(0xFF181818).withValues(alpha: 0.97)
                      : AppColors.white.withValues(alpha: 0.93),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NavTab(
                      icon: 'explore-filled.svg',
                      text: '발견',
                      isActive: _selectedIndex == 0,
                      useDarkTheme: useDarkBottomNavigation,
                      onTap: () => _onTabTap(0),
                    ),
                    NavTab(
                      icon: 'location-filled.svg',
                      text: '지도',
                      isActive: _selectedIndex == 1,
                      useDarkTheme: useDarkBottomNavigation,
                      onTap: () => _onTabTap(1),
                    ),
                    NavTab(
                      icon: 'scrap-filled.svg',
                      text: '스크랩',
                      isActive: _selectedIndex == 2,
                      useDarkTheme: useDarkBottomNavigation,
                      onTap: () => _onTabTap(2),
                    ),
                    NavTab(
                      icon: 'profile-filled.svg',
                      text: '프로필',
                      isActive: _selectedIndex == 3,
                      useDarkTheme: useDarkBottomNavigation,
                      onTap: () => _onTabTap(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showMyNicheCoachmark && _selectedIndex == 0)
          _MyNicheCoachmarkOverlay(onDismiss: _dismissMyNicheCoachmark),
      ],
    );
  }
}

class _MyNicheCoachmarkOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const _MyNicheCoachmarkOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final highlightRect = Rect.fromLTWH(
      MediaQuery.of(context).size.width - 120.w,
      175.h,
      96.w,
      96.w,
    );
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CoachmarkDimPainter(
                    cutoutRect: highlightRect,
                    color: AppColors.black.withValues(alpha: 0.76),
                  ),
                ),
              ),
              Positioned(
                left: highlightRect.left,
                top: highlightRect.top,
                width: highlightRect.width,
                height: highlightRect.height,
                child: CustomPaint(
                  painter: _DashedCirclePainter(color: AppColors.primary400),
                ),
              ),
              Positioned(
                top: 230.h,
                right: 125.w,
                width: 60.w,
                height: 42.h,
                child: CustomPaint(
                  painter: _CoachmarkArrowPainter(color: AppColors.primary200),
                ),
              ),
              Positioned(
                top: 280.h,
                right: 42.w,
                child: Text(
                  '막대가 많이 채워질 수록\n내가 선택한 키워드와 일치하는 프로그램이에요.',
                  textAlign: TextAlign.start,
                  style: AppTypography.button3.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachmarkDimPainter extends CustomPainter {
  final Rect cutoutRect;
  final Color color;

  const _CoachmarkDimPainter({required this.cutoutRect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = color);
    canvas.drawOval(
      cutoutRect.deflate(1),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CoachmarkDimPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect || oldDelegate.color != color;
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = Offset.zero & size;
    const dashCount = 48;
    const dashRatio = 0.58;
    for (var i = 0; i < dashCount; i++) {
      final start = (2 * math.pi / dashCount) * i;
      final sweep = (2 * math.pi / dashCount) * dashRatio;
      canvas.drawArc(rect.deflate(1), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CoachmarkArrowPainter extends CustomPainter {
  final Color color;

  const _CoachmarkArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.38,
        size.width * 0.50,
        size.height * 0.26,
        size.width * 0.82,
        size.height * 0.40,
      );
    canvas.drawPath(path, paint);

    final arrowTip = Offset(size.width * 0.82, size.height * 0.40);
    canvas.drawLine(
      arrowTip,
      Offset(size.width * 0.66, size.height * 0.18),
      paint,
    );
    canvas.drawLine(
      arrowTip,
      Offset(size.width * 0.66, size.height * 0.54),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoachmarkArrowPainter oldDelegate) {
    return oldDelegate.color != color;
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
