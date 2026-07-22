import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ClusterMarkerIcon extends StatelessWidget {
  final int count;

  const ClusterMarkerIcon({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: const BoxDecoration(
        color: AppColors.gray900,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: AppTypography.headline1.copyWith(color: AppColors.white),
      ),
    );
  }
}
