import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/animated_scrap_icon.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/utils/program_scrap.dart';

class HorizontalCard extends StatelessWidget {
  final ProgramModel program;
  final String entrySource;

  const HorizontalCard({
    super.key,
    required this.program,
    this.entrySource = 'unknown',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProgramDetailScreen(program: program, entrySource: entrySource),
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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => toggleProgramScrap(
                        context,
                        program,
                        entrySource: entrySource,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: ListenableBuilder(
                          listenable: ProgramScrapStore.instance,
                          builder: (context, _) {
                            final isBookmarked = ProgramScrapStore.instance
                                .isScrapped(program);
                            return AnimatedScrapIcon(
                              isScrapped: isBookmarked,
                              size: 24,
                              activeColor: AppColors.primary400,
                              inactiveColor: AppColors.gray400,
                            );
                          },
                        ),
                      ),
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
                  program.cardDateText,
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
