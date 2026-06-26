import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class RecentSearchWidget extends StatelessWidget {
  final String text;
  final VoidCallback onDelete;

  const RecentSearchWidget({
    super.key,
    required this.text,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppTypography.button3.copyWith(color: AppColors.gray800),
          ),
          GestureDetector(
            onTap: onDelete,
            child: SvgPicture.asset(
              'assets/icons/close.svg',
              width: 24.w,
              height: 24.h,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
