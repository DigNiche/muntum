import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';

class HorizontalCard extends StatelessWidget {
  final ProgramModel program;

  const HorizontalCard({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramDetailScreen(program: program),
          ),
        );
      },
      child: Row(
        spacing: 16.w,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
            child: SizedBox(
              height: 107.h,
              width: 80.w,
              child: program.images.isEmpty
                  ? const ColoredBox(color: Color(0xffD2F2FD))
                  : program.images.first,
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
                        program.title,
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
                  program.locationName,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  program.startEndDates,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
