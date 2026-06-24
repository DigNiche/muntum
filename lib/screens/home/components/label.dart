import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class Label extends StatelessWidget {
  final bool isAdmin;
  final Color textNonAdminColor = AppColors.primary300;
  final Color textAdminColor = AppColors.gray600;
  final Color backNonAdminColor = AppColors.dimStrong;
  final Color backAdminColor = AppColors.gray200;
  final String text;

  const Label({super.key, required this.isAdmin, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: isAdmin ? backAdminColor : backNonAdminColor,
      ),
      child: Text(
        text,
        style: AppTypography.button4.copyWith(
          color: isAdmin ? textAdminColor : textNonAdminColor,
        ),
      ),
    );
  }
}
