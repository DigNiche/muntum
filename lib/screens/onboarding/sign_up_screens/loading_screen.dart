import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/navigation/main_navigation_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const int _initialPage = 5;
  static const Duration _animationDuration = Duration(milliseconds: 700);

  static const List<Color> _cardColors = [
    Color(0xFFD8D8D8),
    Color(0xFFB7C9C8),
    Color(0xFFDCC5B8),
    Color(0xFFB8B1A8),
    Color(0xFFC7B9A8),
    Color(0xFFAEB9C8),
    Color(0xFFD6C5A7),
  ];

  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = _initialPage;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.34,
    );
    _carouselTimer = Timer.periodic(Duration(milliseconds: 1500), (_) {
      _moveToNextCard();
    });
    _navigationTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    });
  }

  Future<void> _moveToNextCard() async {
    if (!mounted || !_pageController.hasClients) {
      return;
    }
    await _pageController.animateToPage(
      _currentPage + 1,
      duration: _animationDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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
        body: Stack(
          children: [
            Positioned(
              top: 275.h,
              left: 20.w,
              right: 20.w,
              child: Text(
                '문틈님의 취향에 맞는 프로그램을\n찾고 있어요.',
                textAlign: TextAlign.center,
                style: AppTypography.title4.copyWith(color: AppColors.white),
              ),
            ),
            Positioned(
              top: 370.h,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 160.h,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    _currentPage = page;
                  },
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        final page = _pageController.hasClients
                            ? (_pageController.page ?? _currentPage.toDouble())
                            : _currentPage.toDouble();

                        final distance = (index - page).clamp(-1.0, 1.0);
                        final progress = distance.abs();

                        final scale = 1 - (progress * 0.42);
                        final verticalOffset = progress * 16.h;
                        final opacity = 1 - (progress * 0.25);

                        return Transform.translate(
                          offset: Offset(0, verticalOffset),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015)
                              ..rotateY(-distance * 0.28)
                              ..scaleByDouble(scale, scale, scale, 1),
                            child: Opacity(opacity: opacity, child: child),
                          ),
                        );
                      },
                      child: Center(
                        child: Container(
                          width: 120.w,
                          height: 160.h,
                          decoration: BoxDecoration(
                            color: _cardColors[index % _cardColors.length],
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
