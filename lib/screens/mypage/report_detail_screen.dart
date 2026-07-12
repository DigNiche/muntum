import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/report_model.dart';

class ReportDetailScreen extends StatelessWidget {
  final ReportModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final placeName = report.place.name.trim();
    final placeAddress = report.place.address.trim();
    final displayPlaceName = placeName.isNotEmpty ? placeName : placeAddress;
    final displayAddress = placeAddress != displayPlaceName ? placeAddress : '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '제보 내용',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportDetailSection(
                    title: '프로그램 명',
                    body: report.programName,
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    '주소',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    displayPlaceName,
                    style: AppTypography.body3.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  if (displayAddress.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: SvgPicture.asset(
                            'assets/icons/location-filled.svg',
                            width: 16.w,
                            colorFilter: const ColorFilter.mode(
                              AppColors.gray400,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            displayAddress,
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 32.h),
                  _ReportDetailSection(title: '제보이유', body: report.reason),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailSection extends StatelessWidget {
  final String title;
  final String body;

  const _ReportDetailSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.caption2.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 14.h),
        Text(
          body,
          style: AppTypography.body3.copyWith(color: AppColors.gray900),
        ),
      ],
    );
  }
}
