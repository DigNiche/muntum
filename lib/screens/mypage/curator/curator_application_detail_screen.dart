import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/curator/components/curator_application_status_badge.dart';
import 'package:muntum/screens/mypage/curator/curator_application_status.dart';

class CuratorApplicationDetailScreen extends StatelessWidget {
  const CuratorApplicationDetailScreen({super.key, required this.application});

  final CuratorApplicationViewData application;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '지원 내용',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 40.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.lineNormal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CuratorApplicationStatusBadge(
                          status: application.status,
                        ),
                        Text(
                          '${application.appliedAt} 지원',
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _DetailSection(
                      title: '프로그램명',
                      content: application.programName,
                    ),
                    const _SectionDivider(),
                    _DetailSection(title: '한줄소개', content: application.summary),
                    const _SectionDivider(),
                    _DetailSection(
                      title: '소개글',
                      content: application.introduction,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.button3.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: AppTypography.body1.copyWith(color: AppColors.gray900),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: const Divider(height: 1, color: AppColors.lineNormal),
    );
  }
}
