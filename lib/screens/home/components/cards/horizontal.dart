import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class HorizontalCard extends StatelessWidget {
  final String programName;
  const HorizontalCard({super.key, required this.programName});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16.w,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 107.h,
          width: 80.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
            color: Color(0xffD2F2FD),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      programName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline1.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/scrap.svg',
                    width: 24.w,
                    color: AppColors.gray400,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                '장소명',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'YY.MM.DD-YY.MM.DD',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
