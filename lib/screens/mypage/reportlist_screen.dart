import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/report_detail_screen.dart';
import 'package:muntum/screens/mypage/report_submit_screen.dart';
import 'package:muntum/services/suggestion_service.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  late Future<List<ReportModel>> _reportsFuture;
  late Future<String> _nicknameFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
    _nicknameFuture = _loadNickname();
  }

  Future<List<ReportModel>> _loadReports() async {
    return (await SuggestionService().fetchMySuggestions(size: 100)).content;
  }

  Future<String> _loadNickname() async {
    final nickname = await TokenStore.instance.readNickname();
    final trimmed = nickname?.trim() ?? '';
    return trimmed.isEmpty ? '문화발굴단' : trimmed;
  }

  Future<void> _openReportSubmit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportSubmitScreen()),
    );
    if (mounted) {
      setState(() {
        _reportsFuture = _loadReports();
      });
    }
  }

  void _openReportDetail(ReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
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
            center: '제보내역',
            leadingIcon: 'close.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<ReportModel>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                final reports = snapshot.data ?? const <ReportModel>[];
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gray900),
                  );
                }
                if (reports.isEmpty) {
                  return _EmptyReportContent(onReportTap: _openReportSubmit);
                }
                return FutureBuilder<String>(
                  future: _nicknameFuture,
                  builder: (context, nicknameSnapshot) {
                    return Column(
                      children: [
                        Expanded(
                          child: _ReportListContent(
                            reports: reports,
                            nickname: nicknameSnapshot.data ?? '문화발굴단',
                            onReportTap: _openReportDetail,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 34.h),
                          child: ButtonSolid(
                            text: '제보하기',
                            textColor: AppColors.white,
                            boxColor: AppColors.black,
                            onTap: _openReportSubmit,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportListContent extends StatelessWidget {
  final List<ReportModel> reports;
  final String nickname;
  final ValueChanged<ReportModel> onReportTap;

  const _ReportListContent({
    required this.reports,
    required this.nickname,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '알려지지 않은 프로그램 ${reports.length}개,\n$nickname님이 👀발견했어요!',
                style: AppTypography.title3.copyWith(color: AppColors.gray900),
              ),
              SizedBox(height: 40.h),
              Text(
                '제보내역 ${reports.length}개',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              SizedBox(height: 16.h),
              _ReportListTile(report: reports[index], onTap: onReportTap),
            ],
          );
        }
        return _ReportListTile(report: reports[index], onTap: onReportTap);
      },
      separatorBuilder: (context, index) => Divider(
        height: 32.h,
        thickness: 1.h,
        color: AppColors.lineAlternative,
      ),
      itemCount: reports.length,
    );
  }
}

class _ReportListTile extends StatelessWidget {
  final ReportModel report;
  final ValueChanged<ReportModel> onTap;

  const _ReportListTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(report),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.programName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.button2.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 6.h),
            Text(
              report.place.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption1.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReportContent extends StatelessWidget {
  final VoidCallback onReportTap;

  const _EmptyReportContent({required this.onReportTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/report_submit.lottie',
              width: 140.w,
              height: 140.w,
              animate: false,
              repeat: false,
            ),
            SizedBox(height: 28.h),
            Text(
              '나만 아는 문화 프로그램을 발견했나요?',
              textAlign: TextAlign.center,
              style: AppTypography.title3.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 8.h),
            Text(
              '제보하면 문화발굴단 팀이 검토 후\n프로그램으로 등록해드려요!',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: 28.h),
            SizedBox(
              width: 84.w,
              child: ButtonSolid(
                text: '제보하기',
                textColor: AppColors.white,
                boxColor: AppColors.black,
                onTap: onReportTap,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
