import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/components/cards/banner.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerCard> banners;
  const BannerCarousel({super.key, required this.banners});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 292.5.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return widget.banners[index];
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
                left: currentIndex * (390.w / widget.banners.length),
                child: Container(
                  width: 390.w / widget.banners.length,
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
