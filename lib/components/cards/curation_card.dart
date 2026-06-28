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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppBorderRadius.radius_10,
                  ),
                  child: SizedBox(
                    height: 467.h,
                    width: 350.w,
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
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 18.h,
                    horizontal: 18.w,
                  ),
                  child: Wrap(
                    runSpacing: 6.h,
                    spacing: 6.w,
                    children: program.keywords
                        .take(3)
                        .map(
                          (keyword) => Label(
                            labelType: LabelType.keyword,
                            text: keyword.replaceAll(' ', '_'),
                          ),
                        )
                        .toList(),
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
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  program.title,
                  style: AppTypography.title3.copyWith(color: AppColors.white),
                ),
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: SvgPicture.asset(
                    "assets/icons/scrap.svg",
                    width: 14.w,
                    height: 20.h,
                    color: AppColors.white,
                  ),
                ),
              ],
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
