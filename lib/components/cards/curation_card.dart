import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/animated_scrap_icon.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';
import 'package:muntum/utils/program_keyword_match.dart';
import 'package:muntum/utils/program_scrap.dart';

class CurationCard extends StatelessWidget {
  final ProgramModel program;
  final String entrySource;

  const CurationCard({
    super.key,
    required this.program,
    this.entrySource = 'my_taste',
  });

  @override
  Widget build(BuildContext context) {
    return SecondCurationCard(program: program, entrySource: entrySource);
  }
}

// My Niche Page
class SecondCurationCard extends StatelessWidget {
  final ProgramModel program;
  final String entrySource;

  const SecondCurationCard({
    super.key,
    required this.program,
    this.entrySource = 'my_taste',
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
                    SizedBox(width: 8.w),
                    _KeywordMatchBars(program: program),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => toggleProgramScrap(
                    context,
                    program,
                    entrySource: entrySource,
                  ),
                  child: ListenableBuilder(
                    listenable: ProgramScrapStore.instance,
                    builder: (context, _) {
                      final isBookmarked = ProgramScrapStore.instance
                          .isScrapped(program);
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.white.withValues(alpha: 0.08),
                        ),
                        width: 48.r,
                        height: 48.r,
                        child: Center(
                          child: AnimatedScrapIcon(
                            isScrapped: isBookmarked,
                            size: 24.r,
                            activeColor: AppColors.primary400,
                            inactiveColor: AppColors.white.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 290.w),
              child: Text(
                program.title,
                style: AppTypography.title3.copyWith(color: AppColors.white),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              program.locationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption2.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: 4.h),
            Text(
              program.cardDateText,
              style: AppTypography.caption2.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordMatchBars extends StatelessWidget {
  final ProgramModel program;

  const _KeywordMatchBars({required this.program});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserPreferenceStore.instance,
      builder: (context, _) {
        final matchLevel = programKeywordMatchLevel(
          program,
          UserPreferenceStore.instance.selectedKeywords,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 4.h,
          children: List.generate(3, (index) {
            final isMatched = index < matchLevel;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 4.w,
              height: 20.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: AppColors.primary400.withValues(
                  alpha: isMatched ? 1 : 0.2,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
