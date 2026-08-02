import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ProgramEndedBadge extends StatelessWidget {
  const ProgramEndedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.gray800,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        '종료',
        style: AppTypography.caption3.copyWith(color: AppColors.white),
      ),
    );
  }
}
