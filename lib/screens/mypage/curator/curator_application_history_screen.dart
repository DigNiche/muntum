import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/screens/mypage/curator/components/curator_application_status_badge.dart';
import 'package:muntum/screens/mypage/curator/curator_application_detail_screen.dart';
import 'package:muntum/services/curator_application_service.dart';
import 'package:muntum/utils/app_toast.dart';

class CuratorApplicationHistoryScreen extends StatefulWidget {
  const CuratorApplicationHistoryScreen({super.key, this.service});

  final CuratorApplicationService? service;

  @override
  State<CuratorApplicationHistoryScreen> createState() =>
      _CuratorApplicationHistoryScreenState();
}

class _CuratorApplicationHistoryScreenState
    extends State<CuratorApplicationHistoryScreen> {
  late final CuratorApplicationService _service;
  late Future<List<CuratorApplicationModel>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CuratorApplicationService();
    _applicationsFuture = _load();
  }

  Future<List<CuratorApplicationModel>> _load() async {
    final page = await _service
        .fetchMine(size: 50)
        .timeout(const Duration(seconds: 15));
    return page.content;
  }

  void _retry() {
    setState(() => _applicationsFuture = _load());
  }

  Future<void> _refresh() async {
    try {
      final applications = await _load();
      if (!mounted) return;
      setState(() {
        _applicationsFuture = Future.value(applications);
      });
    } catch (_) {
      if (mounted) {
        showAppToast(context, '새로고침하지 못했어요. 잠시 후 다시 시도해주세요.', isError: true);
      }
    }
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
            center: '큐레이터 지원 내역',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<CuratorApplicationModel>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gray900),
                  );
                }
                if (snapshot.hasError) {
                  return _HistoryMessage(
                    message: '지원 내역을 불러오지 못했어요.',
                    buttonText: '다시 시도',
                    onTap: _retry,
                  );
                }
                final applications = snapshot.data ?? const [];
                if (applications.isEmpty) {
                  return const _HistoryMessage(message: '아직 지원 내역이 없어요.');
                }
                return RefreshIndicator(
                  color: AppColors.gray900,
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
                    itemCount: applications.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.lineNormal),
                    itemBuilder: (context, index) => _ApplicationHistoryItem(
                      application: applications[index],
                      onChanged: _retry,
                      service: _service,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationHistoryItem extends StatelessWidget {
  const _ApplicationHistoryItem({
    required this.application,
    required this.onChanged,
    required this.service,
  });

  final CuratorApplicationModel application;
  final VoidCallback onChanged;
  final CuratorApplicationService service;

  @override
  Widget build(BuildContext context) {
    final displayTitle = application.programName.isEmpty
        ? '큐레이터 지원서'
        : application.programName;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CuratorApplicationDetailScreen(
              applicationId: application.id,
              initialApplication: application,
              service: service,
            ),
          ),
        );
        if (changed == true) onChanged();
      },
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
                    displayTitle,
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
              '${application.formattedCreatedAt} 지원',
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

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.message, this.buttonText, this.onTap});

  final String message;
  final String? buttonText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
          if (buttonText != null) ...[
            SizedBox(height: 16.h),
            TextButton(onPressed: onTap, child: Text(buttonText!)),
          ],
        ],
      ),
    );
  }
}
