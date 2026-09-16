import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/curator/components/curator_application_status_badge.dart';
import 'package:muntum/screens/mypage/curator/curator_application_detail_screen.dart';
import 'package:muntum/screens/mypage/curator/curator_application_status.dart';

class CuratorApplicationHistoryScreen extends StatelessWidget {
  const CuratorApplicationHistoryScreen({super.key, required this.status});

  final CuratorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final application = status == CuratorApplicationStatus.pending
        ? CuratorApplicationViewData.pendingSample
        : CuratorApplicationViewData.rejectedSample;
    final applications = status == CuratorApplicationStatus.rejected
        ? [application, application]
        : [application];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '큐레이터 지원 내역',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 40.h),
              itemCount: applications.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.lineNormal),
              itemBuilder: (context, index) =>
                  _ApplicationHistoryItem(application: applications[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationHistoryItem extends StatelessWidget {
  const _ApplicationHistoryItem({required this.application});

  final CuratorApplicationViewData application;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              CuratorApplicationDetailScreen(application: application),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CuratorApplicationStatusBadge(status: application.status),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.programName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button1.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                SvgPicture.asset(
                  'assets/icons/arrow_right.svg',
                  width: 16.r,
                  height: 16.r,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray400,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '${application.appliedAt} 지원',
              style: AppTypography.caption2.copyWith(color: AppColors.gray500),
            ),
            if (application.rejectionReason != null) ...[
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.backgroundNormal,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, size: 14.r, color: AppColors.warning),
                        SizedBox(width: 5.w),
                        Text(
                          '미승인 사유',
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.gray700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      application.rejectionReason!,
                      style: AppTypography.body3.copyWith(
                        color: AppColors.gray800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
