import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class SectionHeader1 extends StatelessWidget {
  final String text;
  final String buttonName;
  const SectionHeader1({
    super.key,
    required this.text,
    required this.buttonName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      width: 350.w,
      height: 44.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppTypography.title3.copyWith(color: AppColors.gray900),
          ),
          Text(
            buttonName,
            style: AppTypography.caption1.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class SectionHeader2 extends StatelessWidget {
  final String text;
  final String buttonName;
  final VoidCallback? onButtonTap;
  const SectionHeader2({
    super.key,
    required this.text,
    required this.buttonName,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0.w),
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        height: 30.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTypography.headline1.copyWith(color: AppColors.gray900),
            ),
            GestureDetector(
              onTap: onButtonTap,
              child: Text(
                buttonName,
                style: AppTypography.button3.copyWith(color: AppColors.gray500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
