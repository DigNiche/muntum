import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class VerticalCard extends StatelessWidget {
  const VerticalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 213.h,
              width: 160.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                color: Color(0xffD1F3FD),
              ),
            ),
            // 그라데이션
            Positioned(
              left: 0,
              right: 0,
              child: Container(
                height: 100.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.15),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: SvgPicture.asset(
                    "assets/icons/scrap.svg",
                    width: 14.w,
                    height: 20.h,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.all(4.0.r),
          child: Text(
            "프로그램명",
            style: AppTypography.headline1.copyWith(color: AppColors.gray900),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          "장소명",
          style: AppTypography.caption1.copyWith(color: AppColors.gray700),
        ),
        SizedBox(height: 2.h),
        Text(
          "YY.MM.DD-YY.MM.DD",
          style: AppTypography.caption1.copyWith(color: AppColors.gray700),
        ),
        SizedBox(height: 2.0.h),
      ],
    );
  }
}
