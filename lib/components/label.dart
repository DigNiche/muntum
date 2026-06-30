import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

enum LabelType { admin, keyword, etc }

class Label extends StatelessWidget {
  final LabelType labelType;
  final Color textKeywordColor = AppColors.white;
  final Color textAdminColor = AppColors.gray600;
  final Color textETCColor = AppColors.white;
  final Color backKeywordColor = AppColors.black;
  final Color backAdminColor = AppColors.gray200;
  final Color backETCColor = AppColors.gray900;
  final String text;

  const Label({super.key, required this.labelType, required this.text});

  Color get backgroundColor {
    switch (labelType) {
      case LabelType.admin:
        return backAdminColor;
      case LabelType.keyword:
        return backKeywordColor;
      case LabelType.etc:
        return backETCColor;
    }
  }

  Color get textColor {
    switch (labelType) {
      case LabelType.admin:
        return textAdminColor;
      case LabelType.keyword:
        return textKeywordColor;
      case LabelType.etc:
        return textETCColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (labelType) {
      case LabelType.keyword:
        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            color: backgroundColor,
          ),
          child: Text(
            text,
            style: AppTypography.button4.copyWith(color: textColor),
          ),
        );
      case LabelType.admin:
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            color: backgroundColor,
          ),
          child: Text(
            text,
            style: AppTypography.caption3.copyWith(color: textColor),
          ),
        );
      case LabelType.etc:
        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            color: backgroundColor,
          ),
          child: Text(
            text,
            style: AppTypography.caption2.copyWith(color: textColor),
          ),
        );
    }
  }
}
