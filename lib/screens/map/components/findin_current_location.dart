import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class FindInCurrentLocationButton extends StatelessWidget {
  const FindInCurrentLocationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10110F).withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/redo.svg',
            width: 16.w,
            color: AppColors.gray900,
          ),
          SizedBox(width: 6.w),
          Text(
            '현재 위치로 재검색',
            style: AppTypography.button3.copyWith(color: AppColors.gray900),
          ),
        ],
      ),
    );
  }
}
