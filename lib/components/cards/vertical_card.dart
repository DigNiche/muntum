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

class VerticalCard extends StatelessWidget {
  final ProgramModel program;
  final double? width;
  final String entrySource;

  const VerticalCard({
    super.key,
    required this.program,
    this.width,
    this.entrySource = 'unknown',
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
              builder: (context) => ProgramDetailScreen(
                program: program,
                entrySource: entrySource,
              ),
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
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
                // 스크랩 아이콘
                Positioned(
                  right: 8.w,
                  top: 10.h,
                  child: GestureDetector(
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
                        return SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: AnimatedScrapIcon(
                            isScrapped: isBookmarked,
                            size: 24,
                            activeColor: AppColors.primary400,
                            inactiveColor: AppColors.white,
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
                maxLines: 2,
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
              program.cardDateText,
              style: AppTypography.caption1.copyWith(color: AppColors.gray700),
            ),
            SizedBox(height: 2.0.h),
          ],
        ),
      ),
    );
  }
}
