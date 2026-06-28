import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';

class BannerCard extends StatelessWidget {
  const BannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProgramDetailScreen()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 292.5.h,
                width: 390.w,
                decoration: BoxDecoration(color: Color(0xff9DB6BE)),
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
                  '프로그램명',
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
                      '장소명',
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
                      'YY.MM.DD-YY.MM.DD',
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
