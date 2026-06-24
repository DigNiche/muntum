import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/typography.dart';

class FilterChip extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final Color? outlineColor;
  const FilterChip({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
        border: outlineColor == null ? null : Border.all(color: outlineColor!),
      ),
      child: Text(
        text,
        style: AppTypography.button3.copyWith(color: textColor),
      ),
    );
  }
}

class FilterList extends StatelessWidget {
  final List<Widget> listOfChip;
  const FilterList({super.key, required this.listOfChip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
      child: Row(spacing: 10.w, children: listOfChip),
    );
  }
}
