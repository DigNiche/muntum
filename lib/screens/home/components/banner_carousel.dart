import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/components/banner.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

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
            itemCount: 5,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return BannerCard();
            },
          ),
        ),
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
                left: currentIndex * (390.w / 5),
                child: Container(
                  width: 390.w / 5,
                  height: 4.h,
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
