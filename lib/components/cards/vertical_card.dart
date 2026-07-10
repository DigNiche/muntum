import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/mock_user_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/utils/program_scrap.dart';

class VerticalCard extends StatelessWidget {
  final ProgramModel program;
  final double? width;
  final int titleMaxLines;

  const VerticalCard({
    super.key,
    required this.program,
    this.width,
    this.titleMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 160.w;
    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramDetailScreen(program: program),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
                  child: SizedBox(
                    height: 213.h,
                    width: cardWidth,
                    child: program.images.isEmpty
                        ? const ColoredBox(color: Color(0xffD1F3FD))
                        : program.images.first,
                  ),
                ),
                // 그라데이션
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.radius_8,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => toggleProgramScrap(context, program),
                    child: ListenableBuilder(
                      listenable: MockBookmarkStore.instance,
                      builder: (context, _) {
                        final isBookmarked = MockBookmarkStore.instance
                            .isBookmarked(program);
                        return Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 15.h,
                            horizontal: 15.w,
                          ),
                          child: SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: SvgPicture.asset(
                              isBookmarked
                                  ? 'assets/icons/scrap-filled.svg'
                                  : "assets/icons/scrap.svg",
                              width: 14.w,
                              height: 20.h,
                              color: isBookmarked
                                  ? AppColors.primary400
                                  : AppColors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0.r),
              child: Text(
                program.title,
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline1.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              program.locationName,
              style: AppTypography.caption1.copyWith(color: AppColors.gray700),
            ),
            SizedBox(height: 2.h),
            Text(
              program.startEndDates,
              style: AppTypography.caption1.copyWith(color: AppColors.gray700),
            ),
            SizedBox(height: 2.0.h),
          ],
        ),
      ),
    );
  }
}
