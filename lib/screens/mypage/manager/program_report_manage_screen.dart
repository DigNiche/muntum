import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/report_detail_screen.dart';
import 'package:muntum/services/suggestion_service.dart';

enum _ReportTab {
  pending(label: '미등록', apiStatus: 'PENDING'),
  approved(label: '등록완료', apiStatus: 'APPROVED');

  const _ReportTab({required this.label, required this.apiStatus});

  final String label;
  final String apiStatus;
}

class ProgramReportManageScreen extends StatefulWidget {
  const ProgramReportManageScreen({super.key});

  @override
  State<ProgramReportManageScreen> createState() =>
      _ProgramReportManageScreenState();
}

class _ProgramReportManageScreenState extends State<ProgramReportManageScreen> {
  static const _pageSize = 20;

  final _service = SuggestionService();
  final _scrollController = ScrollController();
  final List<ReportModel> _reports = [];

  _ReportTab _selectedTab = _ReportTab.pending;
  int _nextPage = 0;
  int _requestId = 0;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadReports(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasNext || _isLoadingMore) return;
    if (_scrollController.position.extentAfter < 240.h) {
      _loadReports();
    }
  }

  void _selectTab(_ReportTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    _loadReports(reset: true);
  }

  Future<void> _loadReports({bool reset = false}) async {
    if (reset) {
      _requestId += 1;
      setState(() {
        _reports.clear();
        _isLoading = true;
        _errorMessage = null;
        _nextPage = 0;
        _hasNext = true;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasNext) return;
      setState(() => _isLoadingMore = true);
    }

    final requestId = _requestId;
    final requestedTab = _selectedTab;

    try {
      final response = await _service.fetchManagerSuggestions(
        status: requestedTab.apiStatus,
        page: reset ? 0 : _nextPage,
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        if (reset) _reports.clear();
        _reports.addAll(response.content);
        _nextPage = response.page + 1;
        _hasNext = response.hasNext || !response.last;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = '프로그램 제보 목록을 불러오지 못했어요.');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openDetail(ReportModel report) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(report: report, managerMode: true),
      ),
    );
    if (mounted && changed == true) await _loadReports(reset: true);
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
            center: '프로그램 제보 관리',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
            child: Row(
              children: _ReportTab.values
                  .map(
                    (tab) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _StatusTab(
                        label: tab.label,
                        selected: _selectedTab == tab,
                        onTap: () => _selectTab(tab),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _reports.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }

    if (_errorMessage != null && _reports.isEmpty) {
      return _ReportMessageState(
        message: _errorMessage!,
        buttonText: '다시 시도',
        onTap: () => _loadReports(reset: true),
      );
    }

    if (_reports.isEmpty) {
      return _ReportMessageState(
        message: _selectedTab == _ReportTab.pending
            ? '미등록 제보가 없어요.'
            : '등록 완료된 제보가 없어요.',
      );
    }

    return RefreshIndicator(
      color: AppColors.gray900,
      onRefresh: () => _loadReports(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
        itemCount: _reports.length + 1,
        itemBuilder: (context, index) {
          if (index == _reports.length) {
            return _isLoadingMore
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gray900,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          final report = _reports[index];
          return _ReportListItem(
            report: report,
            onTap: () => _openDetail(report),
          );
        },
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? AppColors.gray900 : AppColors.lineStrong,
            width: selected ? 1.5.w : 1.w,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.button3.copyWith(
            color: selected ? AppColors.gray900 : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  const _ReportListItem({required this.report, required this.onTap});

  final ReportModel report;
  final VoidCallback onTap;

  String get _location {
    final placeName = report.place.name.trim();
    if (placeName.isNotEmpty) return placeName;
    final address = report.place.address.trim();
    return address.isNotEmpty ? address : '위치 정보 없음';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.lineNormal, width: 1.h),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.programName.isEmpty ? '제보 명' : report.programName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headline1.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 4.h),
            Text(
              report.reason.isEmpty ? '제보 이유' : report.reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption2.copyWith(color: AppColors.gray600),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/location-filled.svg',
                  width: 14.r,
                  height: 14.r,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray400,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray500,
                    ),
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

class _ReportMessageState extends StatelessWidget {
  const _ReportMessageState({
    required this.message,
    this.buttonText,
    this.onTap,
  });

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
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
          if (buttonText != null && onTap != null) ...[
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onTap,
              child: Text(
                buttonText!,
                style: AppTypography.button2.copyWith(color: AppColors.gray900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
