import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/mock_user_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/utils/program_keyword_match.dart';
import 'package:muntum/utils/program_scrap.dart';

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
                    _KeywordMatchBars(program: program),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => toggleProgramScrap(context, program),
                  child: ListenableBuilder(
                    listenable: MockBookmarkStore.instance,
                    builder: (context, _) {
                      final isBookmarked = MockBookmarkStore.instance
                          .isBookmarked(program);
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.white.withValues(alpha: 0.08),
                        ),
                        width: 48.w,
                        height: 48.h,
                        child: SvgPicture.asset(
                          isBookmarked
                              ? 'assets/icons/scrap-filled.svg'
                              : "assets/icons/scrap.svg",
                          width: 24.w,
                          height: 24.h,
                          fit: BoxFit.scaleDown,
                          color: isBookmarked
                              ? AppColors.primary400
                              : AppColors.white.withValues(alpha: 0.8),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              program.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title3.copyWith(color: AppColors.white),
            ),
            Text(
              '${program.locationName} · ${program.startEndDates}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption1.copyWith(color: AppColors.gray500),
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
      listenable: MockUserSession.instance,
      builder: (context, _) {
        final matchLevel = programKeywordMatchLevel(
          program,
          MockUserSession.instance.selectedKeywords,
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
