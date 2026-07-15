import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/components/cards/banner.dart';
import 'package:muntum/models/program_model.dart';

class BannerCarousel extends StatefulWidget {
  final List<ProgramModel> programs;
  final String entrySource;

  const BannerCarousel({
    super.key,
    required this.programs,
    this.entrySource = 'all_banner',
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.programs.isEmpty
        ? 0
        : widget.programs.length * 1000;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programs.length != widget.programs.length) {
      currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.programs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 292.5.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index % widget.programs.length;
              });
            },
            itemBuilder: (context, index) {
              return BannerCard(
                program: widget.programs[index % widget.programs.length],
                entrySource: widget.entrySource,
              );
            },
          ),
        ),
        // Progress Bar
        SizedBox(
          height: 2.h,
          child: Stack(
            children: [
              // 회색 전체 선
              Container(
                width: 390.w,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // 현재 위치
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                left: currentIndex * (390.w / widget.programs.length),
                child: Container(
                  width: 390.w / widget.programs.length,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: AppColors.gray900,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
