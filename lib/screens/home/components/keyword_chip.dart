import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/typography.dart';

class KeywordChip extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color outlineColor;
  const KeywordChip({
    super.key,
    required this.text,
    required this.textColor,
    required this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
      decoration: BoxDecoration(
        border: Border.all(color: outlineColor, width: 1.w),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: AppTypography.button3.copyWith(color: textColor),
      ),
    );
  }
}
