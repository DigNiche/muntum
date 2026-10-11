import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/utils/tablet_text_layout.dart';

class SectionHeader1 extends StatelessWidget {
  final String text;
  final String buttonName;
  final VoidCallback onButtonTap;
  final double? horizontalPadding;
  final double? verticalPadding;
  const SectionHeader1({
    super.key,
    required this.text,
    required this.buttonName,
    required this.onButtonTap,
    this.horizontalPadding,
    this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding ?? 8.h,
        horizontal: horizontalPadding ?? 20.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppTypography.title3.copyWith(color: AppColors.gray900),
          ),
          GestureDetector(
            onTap: onButtonTap,
            child: Text(
              buttonName,
              style: AppTypography.button3.copyWith(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader2 extends StatelessWidget {
  final String text;
  final String buttonName;
  final VoidCallback? onButtonTap;
  const SectionHeader2({
    super.key,
    required this.text,
    required this.buttonName,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    final tablet = TabletTextLayout.isTablet(context);
    final title = Text(
      text,
      style: AppTypography.headline1.copyWith(color: AppColors.gray900),
    );
    final button = GestureDetector(
      onTap: onButtonTap,
      child: Text(
        buttonName,
        style: AppTypography.button3.copyWith(color: AppColors.gray500),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        height: tablet ? null : 30.h,
        constraints: tablet ? BoxConstraints(minHeight: 30.h) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tablet ? Flexible(child: title) : title,
            tablet ? Flexible(child: button) : button,
          ],
        ),
      ),
    );
  }
}

class SectionHeader3 extends StatelessWidget {
  final String text;
  final String buttonName;
  final VoidCallback? onButtonTap;
  final EdgeInsets? padding;
  const SectionHeader3({
    super.key,
    required this.text,
    required this.buttonName,
    this.onButtonTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: padding == null ? null : EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppTypography.headline2.copyWith(color: AppColors.gray900),
          ),
          GestureDetector(
            onTap: onButtonTap,
            child: Text(
              buttonName,
              style: AppTypography.button3.copyWith(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}
