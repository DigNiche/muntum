import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class FindInCurrentLocationButton extends StatelessWidget {
  final bool isLoading;

  const FindInCurrentLocationButton({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10110F).withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(
                color: AppColors.gray900,
                strokeWidth: 2,
              ),
            )
          else
            SvgPicture.asset(
              'assets/icons/redo.svg',
              width: 16.w,
              colorFilter: const ColorFilter.mode(
                AppColors.gray900,
                BlendMode.srcIn,
              ),
            ),
          SizedBox(width: 6.w),
          Text(
            isLoading ? '현재 위치로 검색중' : '현재 위치로 재검색',
            style: AppTypography.button3.copyWith(color: AppColors.gray900),
          ),
        ],
      ),
    );
  }
}
