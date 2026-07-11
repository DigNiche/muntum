import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';

class BannerCard extends StatelessWidget {
  final ProgramModel program;

  const BannerCard({super.key, required this.program});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 292.5.h,
                width: 390.w,
                child: program.images.isEmpty
                    ? const ColoredBox(color: Color(0xff9DB6BE))
                    : program.images.first,
              ),
              // 그라데이션
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
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
              // 프로그램명
              Positioned(
                left: 20.w,
                bottom: 48.h,
                child: Text(
                  program.title,
                  style: AppTypography.title3.copyWith(color: AppColors.white),
                ),
              ),
              // 장소명 · 날짜
              Positioned(
                left: 20.w,
                bottom: 24.h,
                child: Row(
                  spacing: 2.w,
                  children: [
                    Text(
                      program.locationName,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      '·',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      program.cardDateText,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
