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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            program.images.isEmpty
                ? const ColoredBox(color: Color(0xFF9DB6BE))
                : program.images.first,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x1A000000),
                    Color(0xD9000000),
                  ],
                  stops: [0.42, 0.62, 1],
                ),
              ),
            ),
            Positioned(
              top: 16.h,
              right: 14.w,
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
                    final isScrapped = ProgramScrapStore.instance.isScrapped(
                      program,
                    );
                    return AnimatedScrapIcon(
                      isScrapped: isScrapped,
                      size: 24.r,
                      activeColor: AppColors.primary400,
                      inactiveColor: AppColors.white,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 24.w,
              right: 24.w,
              bottom: 28.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title2.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    program.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    program.cardDateText,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
