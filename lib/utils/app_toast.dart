import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

void showAppToast(
  BuildContext context,
  String message, {
  bool isError = false,
  bool showIcon = true,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.fromLTRB(32.w, 0, 32.w, 34.h),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.dimStrong.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
          ),
          child: Row(
            children: [
              if (showIcon)
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isError ? AppColors.error : AppColors.primary500,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    isError
                        ? 'assets/icons/error.svg'
                        : 'assets/icons/check.svg',
                    width: 14.r,
                    color: AppColors.white,
                  ),
                ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.button3.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
