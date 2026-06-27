import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/cards/horizontal.dart';
import 'package:muntum/screens/home/components/filter_chip.dart';
import 'package:muntum/screens/home/components/searchbar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _searchbarController = TextEditingController();

  @override
  void dispose() {
    _searchbarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(),
          onMapReady: (controller) {
            print('네이버 맵 로딩됨!');
          },
        ),
        Column(
          children: [
            SizedBox(height: 50.h),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
              child: SearchBarWidget(
                controller: _searchbarController,
                backgroundColor: AppColors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                spacing: 8.w,
                children: [
                  FilterChipWidget(
                    hasShadow: true,
                    text: '🔥지금핫한',
                    textColor: AppColors.gray800,
                    backgroundColor: AppColors.white,
                    outlineColor: AppColors.lineNormal,
                  ),
                  FilterChipWidget(
                    hasShadow: true,
                    text: '무료',
                    textColor: AppColors.gray800,
                    backgroundColor: AppColors.white,
                    outlineColor: AppColors.lineNormal,
                  ),
                  FilterChipWidget(
                    hasShadow: true,
                    text: '이번주',
                    textColor: AppColors.gray800,
                    backgroundColor: AppColors.white,
                    outlineColor: AppColors.lineNormal,
                  ),
                  FilterChipWidget(
                    hasShadow: true,
                    text: '예약없이',
                    textColor: AppColors.gray800,
                    backgroundColor: AppColors.white,
                    outlineColor: AppColors.lineNormal,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20.w,
          bottom: 184.h,
          child: Container(
            width: 48.w,
            height: 48.w,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10110F).withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/icons/mylocation.svg',
              width: 20.w,
              color: AppColors.gray900,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _MapProgramBottomPanel(),
        ),
      ],
    );
  }
}

class _MapProgramBottomPanel extends StatelessWidget {
  const _MapProgramBottomPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.radius_10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10110F).withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32.h,
            child: Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.gray400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Text(
            '프로그램 n개',
            style: AppTypography.headline2.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 12.h),
          const HorizontalCard(programName: '프로그램1'),
        ],
      ),
    );
  }
}
