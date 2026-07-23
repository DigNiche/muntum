import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ProgramAttendancePrompt extends StatelessWidget {
  const ProgramAttendancePrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
        color: AppColors.gray100,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이 프로그램 다녀오셨나요?',
                style: AppTypography.button2.copyWith(color: AppColors.gray900),
              ),
              Text(
                '평가하고 취향을 기록해보세요!',
                style: AppTypography.button3.copyWith(color: AppColors.gray600),
              ),
            ],
          ),
          Transform.rotate(
            angle: pi / 2,
            child: SvgPicture.asset(
              'assets/icons/arrow_left.svg',
              width: 16.r,
              height: 16.r,
            ),
          ),
        ],
      ),
    );
  }
}
