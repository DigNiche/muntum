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
      color: AppColors.white,
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
