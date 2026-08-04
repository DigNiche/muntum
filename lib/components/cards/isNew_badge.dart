import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class IsNewBadge extends StatelessWidget {
  const IsNewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.primary500,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        'NEW',
        style: AppTypography.badge.copyWith(color: AppColors.black),
      ),
    );
  }
}
