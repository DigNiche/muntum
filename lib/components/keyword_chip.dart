import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class KeywordChip extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color outlineColor;
  final bool showCloseIcon;
  final VoidCallback? onCloseTap;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? boxColor;

  const KeywordChip({
    super.key,
    required this.text,
    required this.textColor,
    required this.outlineColor,
    this.showCloseIcon = false,
    this.onCloseTap,
    this.padding,
    this.textStyle,
    this.boxColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
      decoration: BoxDecoration(
        border: Border.all(color: outlineColor, width: 1.w),
        borderRadius: BorderRadius.circular(999.r),
        color: boxColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: (textStyle ?? AppTypography.button3).copyWith(
              color: textColor,
            ),
          ),
          if (showCloseIcon) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onCloseTap,
              child: SvgPicture.asset(
                'assets/icons/close.svg',
                width: 16.w,
                height: 16.h,
                colorFilter: const ColorFilter.mode(
                  AppColors.gray500,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
