import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ReportContainer extends StatelessWidget {
  final VoidCallback openReportBottomSheet;

  const ReportContainer({super.key, required this.openReportBottomSheet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
        color: AppColors.gray100,
      ),
      child: GestureDetector(
        onTap: openReportBottomSheet,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SvgPicture.asset('assets/reportIcon.svg'),
            SizedBox(width: 8.w),
            Text(
              '아무도 모르는\n나만의 장소가 있다면?',
              style: AppTypography.button2.copyWith(color: AppColors.gray900),
            ),
            const Spacer(),
            ButtonSolid(
              padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 12.w),
              text: '제보하기',
              textColor: AppColors.white,
              boxColor: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}
