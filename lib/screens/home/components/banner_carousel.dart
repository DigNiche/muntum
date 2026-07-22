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

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        height: 467.h,
        child: Stack(
          children: [
            Positioned.fill(
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
            Positioned(
              left: 20.w,
              bottom: 20.h,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.programs.length, (index) {
                  final isActive = index == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 6.r,
                    height: 6.r,
                    margin: EdgeInsets.only(
                      right: index == widget.programs.length - 1 ? 0 : 4.w,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
