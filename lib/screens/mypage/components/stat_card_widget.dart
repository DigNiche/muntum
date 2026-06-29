import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String number;
  final VoidCallback onTap;
  const StatCard({
    super.key,
    required this.title,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 4.w,
                  children: [
                    Text(
                      title,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/arrow_right-small.svg',
                      width: 16.w,
                      color: AppColors.gray600,
                    ),
                  ],
                ),
                Text(number, style: AppTypography.headline1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
