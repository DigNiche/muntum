import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/button_solid.dart';

Future<void> showPopupWidget({
  required BuildContext context,
  required String title,
  required String description,
  required String text1,
  required String text2,
  Color? text2Color,
  required VoidCallback? onText1Tap,
  required VoidCallback? onText2Tap,
}) {
  return showDialog<void>(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
            color: AppColors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.headline1,
                textAlign: TextAlign.center,
              ),
              if (description.isNotEmpty)
                Column(
                  children: [
                    SizedBox(height: 12.h),
                    Text(
                      description,
                      style: AppTypography.body3.copyWith(
                        color: AppColors.gray700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              SizedBox(height: 20.h),
              Row(
                spacing: 8.w,
                children: [
                  Expanded(
                    child: ButtonSolid(
                      text: text1,
                      textColor: AppColors.gray700,
                      boxColor: AppColors.gray100,
                      onTap: onText1Tap,
                      padding: EdgeInsets.fromLTRB(0, 14.h, 0, 13.h),
                    ),
                  ),
                  Expanded(
                    child: ButtonSolid(
                      text: text2,
                      textColor: AppColors.white,
                      boxColor: text2Color ?? AppColors.black,
                      onTap: onText2Tap,
                      padding: EdgeInsets.fromLTRB(0, 14.h, 0, 13.h),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
