import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';

class BannerCard extends StatelessWidget {
  final ProgramModel program;
  final String entrySource;

  const BannerCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 467.h,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                program.imageUrls.isEmpty
                    ? const ColoredBox(color: Color(0xff9DB6BE))
                    : Image.network(
                        program.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(color: Color(0xff9DB6BE)),
                      ),
                // 그라데이션
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 160.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                // 프로그램명
                Positioned(
                  left: 20.w,
                  right: 20.w,
                  bottom: 42.h,
                  child: Column(
                    spacing: 4.h,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      // 장소명 · 날짜
                      Text(
                        '${program.locationName} · ${program.cardDateText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
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
