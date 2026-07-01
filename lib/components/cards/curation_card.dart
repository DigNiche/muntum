import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';

class CurationCard extends StatelessWidget {
  final ProgramModel program;

  const CurationCard({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    return SecondCurationCard(program: program);
  }
}

// My Niche Page
class SecondCurationCard extends StatelessWidget {
  final ProgramModel program;

  const SecondCurationCard({super.key, required this.program});

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
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.radius_10,
                          ),
                          child: SizedBox(
                            height: 386.67.h,
                            width: 290.w,
                            child: program.images.isEmpty
                                ? const ColoredBox(color: Color(0xff9DB6BE))
                                : program.images.first,
                          ),
                        ),
                        // 그라데이션
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 200.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.radius_10,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24.w,
                          right: 24.w,
                          bottom: 42.h,
                          child: Text(
                            '"${program.oneLineDescription}"',
                            style: AppTypography.title3.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 4.h,
                      children: [
                        Container(
                          width: 4.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: AppColors.primary400,
                          ),
                        ),
                        Container(
                          width: 4.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: AppColors.primary400,
                          ),
                        ),
                        Container(
                          width: 4.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: AppColors.primary400.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: 48.w,
                  height: 48.h,
                  child: SvgPicture.asset(
                    "assets/icons/scrap.svg",
                    width: 24.w,
                    height: 24.h,
                    fit: BoxFit.scaleDown,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              program.title,
              style: AppTypography.title3.copyWith(color: AppColors.white),
            ),
            Row(
              spacing: 2.w,
              children: [
                Text(
                  program.locationName,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  "·",
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  program.startEndDates,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
