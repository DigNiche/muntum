import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfoScreen extends StatelessWidget {
  const VersionInfoScreen({super.key});

  Future<_VersionInfoData> _loadVersionInfo() async {
    final packageInfoFuture = PackageInfo.fromPlatform();
    final updateInfoFuture = UpdateService.instance.checkForUpdate();
    return _VersionInfoData(
      packageInfo: await packageInfoFuture,
      updateInfo: await updateInfoFuture,
    );
  }

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
          FutureBuilder<_VersionInfoData>(
            future: _loadVersionInfo(),
            builder: (context, snapshot) {
              final packageInfo = snapshot.data?.packageInfo;
              final needsUpdate = snapshot.data?.updateInfo != null;
              final versionText = packageInfo == null
                  ? '-'
                  : '${packageInfo.version} (${packageInfo.buildNumber})';

              return Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
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
                        style: AppTypography.button2.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$versionText (${needsUpdate ? '업데이트 필요' : '최신'})',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VersionInfoData {
  final PackageInfo packageInfo;
  final AppUpdateInfo? updateInfo;

  const _VersionInfoData({required this.packageInfo, required this.updateInfo});
}
