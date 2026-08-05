import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/animated_scrap_icon.dart';
import 'package:muntum/components/program_ended_badge.dart';
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
  final VoidCallback? onTap;

  const HorizontalCard({
    super.key,
    required this.program,
    this.entrySource = 'unknown',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
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
      child: Row(
        spacing: 16.w,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HorizontalCardImage(program: program, entrySource: entrySource),
          Expanded(child: _HorizontalCardDetails(program: program)),
        ],
      ),
    );
  }
}

class _HorizontalCardImage extends StatelessWidget {
  final ProgramModel program;
  final String entrySource;

  const _HorizontalCardImage({
    required this.program,
    required this.entrySource,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
      child: SizedBox(
        height: 147.h,
        width: 110.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            program.images.isEmpty
                ? const ColoredBox(color: Color(0xffD2F2FD))
                : program.images.first,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60.h,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x4D000000), Colors.transparent],
                  ),
                ),
              ),
            ),
            if (program.isEnded)
              ColoredBox(color: AppColors.white.withValues(alpha: 0.3)),
            Positioned(
              top: 8.h,
              right: 6.w,
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
                    final isBookmarked = ProgramScrapStore.instance.isScrapped(
                      program,
                    );
                    return AnimatedScrapIcon(
                      isScrapped: isBookmarked,
                      size: 24,
                      activeColor: AppColors.primary400,
                      inactiveColor: AppColors.white,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalCardDetails extends StatelessWidget {
  final ProgramModel program;

  const _HorizontalCardDetails({required this.program});

  @override
  Widget build(BuildContext context) {
    final titleColor = program.isEnded ? AppColors.gray800 : AppColors.gray900;
    final detailColor = program.isEnded ? AppColors.gray500 : AppColors.gray700;
    final keywordColor = program.isEnded
        ? AppColors.gray500
        : AppColors.gray600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline1.copyWith(color: titleColor),
          ),
          SizedBox(height: 8.h),
          Text(
            program.locationName,
            style: AppTypography.caption1.copyWith(color: detailColor),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 4.w,
            runSpacing: 2.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                program.cardDateText,
                style: AppTypography.caption1.copyWith(color: detailColor),
              ),
              if (program.isEnded) const ProgramEndedBadge(),
            ],
          ),
          SizedBox(height: 10.h),
          _HorizontalCardKeywords(
            keywords: program.keywords,
            textColor: keywordColor,
          ),
        ],
      ),
    );
  }
}

class _HorizontalCardKeywords extends StatelessWidget {
  final List<String> keywords;
  final Color textColor;

  const _HorizontalCardKeywords({
    required this.keywords,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    final textStyle = AppTypography.badge.copyWith(color: textColor);
    final firstThreeKeywords = keywords.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final firstThreeWidth = firstThreeKeywords.fold<double>(0, (
          width,
          keyword,
        ) {
          final painter = TextPainter(
            text: TextSpan(text: keyword, style: textStyle),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          return width + painter.width + 8.w;
        });
        final canShowAllThree =
            keywords.length <= 3 &&
            firstThreeWidth + (5.w * (firstThreeKeywords.length - 1)) <=
                constraints.maxWidth;
        final visibleKeywords = canShowAllThree
            ? firstThreeKeywords
            : keywords.take(2).toList();
        final remainingCount = keywords.length - visibleKeywords.length;
        final labels = [
          ...visibleKeywords,
          if (remainingCount > 0) '+$remainingCount',
        ];

        return Row(
          spacing: 5.w,
          children: labels.map((label) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xfff7f7f7),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(label, maxLines: 1, style: textStyle),
            );
          }).toList(),
        );
      },
    );
  }
}
