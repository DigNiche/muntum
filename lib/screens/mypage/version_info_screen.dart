import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class VersionInfoScreen extends StatelessWidget {
  const VersionInfoScreen({super.key});

  static const String _version = '1.0';
  static const bool _needsUpdate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '버전정보',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 18.h),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.lineStrong, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '버전 정보',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$_version (${_needsUpdate ? '업데이트 필요' : '최신'})',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
