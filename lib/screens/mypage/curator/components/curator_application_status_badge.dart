import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/curator/curator_application_status.dart';

class CuratorApplicationStatusBadge extends StatelessWidget {
  const CuratorApplicationStatusBadge({super.key, required this.status});

  final CuratorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == CuratorApplicationStatus.pending;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isPending ? AppColors.primary200 : AppColors.gray200,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.label,
        style: AppTypography.badge.copyWith(
          color: isPending ? AppColors.gray800 : AppColors.gray600,
        ),
      ),
    );
  }
}
