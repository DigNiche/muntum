import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class CurationManageScreen extends StatelessWidget {
  const CurationManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNormal,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.white,
            child: Column(
              children: [
                SizedBox(height: 50.h),
                AppBarWidget(
                  centerType: AppBarCenterType.text,
                  leadingIcon: 'arrow_left.svg',
                  center: '큐레이션 글 관리',
                  onLeadingTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '큐레이션 관리 UI를 준비 중이에요.',
                style: AppTypography.body2.copyWith(color: AppColors.gray500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
