import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/services/update_service.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppUpdateInfo updateInfo,
  required Future<void> Function() onUpdate,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !updateInfo.isRequired,
    builder: (dialogContext) {
      return PopScope(
        canPop: !updateInfo.isRequired,
        child: Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            width: 316.w,
            padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  updateInfo.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline1.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  updateInfo.message,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTypography.body3.copyWith(color: AppColors.gray700),
                ),
                SizedBox(height: 20.h),
                Row(
                  spacing: 8.w,
                  children: [
                    if (!updateInfo.isRequired)
                      Expanded(
                        child: ButtonSolid(
                          text: '나중에',
                          textColor: AppColors.gray700,
                          boxColor: AppColors.gray100,
                          padding: EdgeInsets.fromLTRB(0, 14.h, 0, 13.h),
                          onTap: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    Expanded(
                      child: ButtonSolid(
                        text: '지금 업데이트',
                        textColor: AppColors.white,
                        boxColor: AppColors.black,
                        padding: EdgeInsets.fromLTRB(0, 14.h, 0, 13.h),
                        onTap: () async {
                          if (!updateInfo.isRequired) {
                            Navigator.pop(dialogContext);
                          }
                          await onUpdate();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
