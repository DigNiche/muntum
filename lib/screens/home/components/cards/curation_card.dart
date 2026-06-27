import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/label.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';

class CurationCard extends StatelessWidget {
  final bool isSecondCard;
  const CurationCard({super.key, required this.isSecondCard});

  @override
  Widget build(BuildContext context) {
    return isSecondCard ? SecondCurationCard() : FirstCurationCard();
  }
}

// My Niche Page
class SecondCurationCard extends StatelessWidget {
  const SecondCurationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProgramDetailScreen()),
        );
      },
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 467.h,
                  width: 350.w,
                  decoration: BoxDecoration(
                    color: Color(0xff9DB6BE),
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.radius_10,
                    ),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 18.h,
                    horizontal: 18.w,
                  ),
                  child: Row(
                    spacing: 6.w,
                    children: [
                      Label(labelType: LabelType.keyword, text: '그_순간에_몰입'),
                      Label(labelType: LabelType.keyword, text: '생생한_감각'),
                      Label(labelType: LabelType.keyword, text: '사진맛집'),
                    ],
                  ),
                ),
                Positioned(
                  left: 24.w,
                  right: 24.w,
                  bottom: 42.h,
                  child: Text(
                    '"한 줄 소개 내용입니다. 한 줄 소개 내용입니다."',
                    style: AppTypography.title3.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '프로그램명',
                  style: AppTypography.title3.copyWith(color: AppColors.white),
                ),
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: SvgPicture.asset(
                    "assets/icons/scrap.svg",
                    width: 14.w,
                    height: 20.h,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            Row(
              spacing: 2.w,
              children: [
                Text(
                  "장소명",
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  "·",
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  "YY.MM.DD-YY.MM.DD",
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Entire Page
class FirstCurationCard extends StatelessWidget {
  const FirstCurationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 467.h,
                width: 350.w,
                decoration: BoxDecoration(
                  color: Color(0xff9DB6BE),
                  borderRadius: BorderRadius.circular(
                    AppBorderRadius.radius_10,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 18.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 6.w,
                      children: [
                        Label(labelType: LabelType.keyword, text: '그_순간에_몰입'),
                        Label(labelType: LabelType.keyword, text: '생생한_감각'),
                        Label(labelType: LabelType.keyword, text: '사진맛집'),
                      ],
                    ),
                    SizedBox(
                      height: 24.h,
                      width: 24.w,
                      child: SvgPicture.asset(
                        "assets/icons/scrap.svg",
                        width: 14.w,
                        height: 20.h,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24.w,
                right: 24.w,
                bottom: 42.h,
                child: Text(
                  '"한 줄 소개 내용입니다. 한 줄 소개 내용입니다."',
                  style: AppTypography.title3.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '프로그램명',
            style: AppTypography.title3.copyWith(color: AppColors.gray900),
          ),

          SizedBox(height: 6.h),
          Text(
            "장소명",
            style: AppTypography.caption1.copyWith(color: AppColors.gray700),
          ),
          SizedBox(height: 2.h),
          Text(
            "YY.MM.DD-YY.MM.DD",
            style: AppTypography.caption1.copyWith(color: AppColors.gray700),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
