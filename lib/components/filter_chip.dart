import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/typography.dart';

class FilterChipWidget extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final Color? outlineColor;
  final bool? hasShadow;
  const FilterChipWidget({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    this.outlineColor,
    this.hasShadow,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShowShadow = hasShadow == true;
    final chip = Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
      decoration: shouldShowShadow
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
              border: outlineColor == null
                  ? null
                  : Border.all(color: outlineColor!),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10110F).withValues(alpha: 0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            )
          : BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
              border: outlineColor == null
                  ? null
                  : Border.all(color: outlineColor!),
            ),
      child: Text(
        text,
        style: AppTypography.button3.copyWith(color: textColor),
      ),
    );

    if (!shouldShowShadow) {
      return chip;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 10.h),
      child: chip,
    );
  }
}
