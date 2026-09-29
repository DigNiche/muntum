import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/screens/mypage/manager/curation_review_screen.dart';
import 'package:muntum/services/admin_curation_service.dart';
import 'package:muntum/utils/app_toast.dart';

class CurationManageScreen extends StatefulWidget {
  const CurationManageScreen({super.key, this.service});

  final AdminCurationService? service;

  @override
  State<CurationManageScreen> createState() => _CurationManageScreenState();
}

class _CurationManageScreenState extends State<CurationManageScreen> {
  late final AdminCurationService _service;
  final _lists = <CurationStatus, List<AdminCurationModel>>{
    CurationStatus.pending: [],
    CurationStatus.changesRequested: [],
  };
  final _totals = <CurationStatus, int>{};
  final _nextPage = <CurationStatus, int>{};
  final _hasMore = <CurationStatus, bool>{};
  CurationStatus _selected = CurationStatus.pending;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminCurationService();
    _load();
  }

  Future<void> _load() async {
    final version = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pages = await Future.wait([
        _service.fetchList(status: CurationStatus.pending),
        _service.fetchList(status: CurationStatus.changesRequested),
      ]);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        for (var i = 0; i < pages.length; i++) {
          final status = i == 0
              ? CurationStatus.pending
              : CurationStatus.changesRequested;
          _lists[status] = pages[i].content;
          _totals[status] = pages[i].totalElements;
          _nextPage[status] = pages[i].page + 1;
          _hasMore[status] = pages[i].hasMore;
        }
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted && version == _requestVersion) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && version == _requestVersion) {
        setState(() {
          _error = '큐레이션 목록을 불러오지 못했어요.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final status = _selected;
    if (_loading || _loadingMore || _hasMore[status] != true) return;
    final version = _requestVersion;
    setState(() => _loadingMore = true);
    try {
      final page = await _service.fetchList(
        status: status,
        page: _nextPage[status] ?? 0,
      );
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _lists[status]!.addAll(page.content);
        _nextPage[status] = page.page + 1;
        _hasMore[status] = page.hasMore;
      });
    } catch (_) {
      // Keep loaded cards; another scroll can retry this page.
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _open(AdminCurationModel item) async {
    final changed = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CurationReviewScreen(summary: item, service: _service),
      ),
    );
    if (!mounted || changed == null) return;
    await _load();
    if (mounted) {
      showAppToast(
        context,
        changed == 'approved' ? '등록되었습니다.' : '수정 요청이 전송되었습니다.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _lists[_selected] ?? const <AdminCurationModel>[];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: Column(
                children: [
                  AppBarWidget(
                    centerType: AppBarCenterType.text,
                    center: '큐레이션 글 관리',
                    leadingIcon: 'arrow_left.svg',
                    onLeadingTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _ReviewTab(
                        label: '대기 ${_totals[CurationStatus.pending] ?? 0}',
                        selected: _selected == CurationStatus.pending,
                        onTap: () =>
                            setState(() => _selected = CurationStatus.pending),
                      ),
                      _ReviewTab(
                        label:
                            '수정 요청 ${_totals[CurationStatus.changesRequested] ?? 0}',
                        selected: _selected == CurationStatus.changesRequested,
                        onTap: () => setState(
                          () => _selected = CurationStatus.changesRequested,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.backgroundNormal,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: TextButton(
                          onPressed: _load,
                          child: Text('$_error\n다시 시도'),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.extentAfter < 240.h) {
                              _loadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              20.w,
                              16.h,
                              20.w,
                              24.h,
                            ),
                            itemCount: items.isEmpty
                                ? 1
                                : items.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (items.isEmpty) {
                                return SizedBox(
                                  height: 320.h,
                                  child: Center(
                                    child: Text(
                                      _selected == CurationStatus.pending
                                          ? '대기 중인 글이 없어요.'
                                          : '수정 요청한 글이 없어요.',
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (index == items.length) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: _ReviewCard(
                                  item: items[index],
                                  onTap: () => _open(items[index]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.gray900 : AppColors.lineNormal,
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.button3.copyWith(
            color: selected ? AppColors.gray900 : AppColors.gray500,
          ),
        ),
      ),
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item, required this.onTap});
  final AdminCurationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final curation = item.curation;
    final pending = curation.status == CurationStatus.pending;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: pending
                          ? AppColors.primary100
                          : const Color(0xFFFFF5DB),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      pending ? '대기중' : '수정요청',
                      style: AppTypography.badge.copyWith(
                        color: pending
                            ? AppColors.primary800
                            : AppColors.warning,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    curation.formattedCreatedAt,
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _CardField(label: '프로그램명', value: curation.programTitle),
              _CardField(label: '장소', value: curation.place),
              _CardField(label: '큐레이터', value: item.curator.nickname),
              if (pending) ...[
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  height: 40.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lineNormal),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Text('확인하기', style: AppTypography.button3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Row(
      children: [
        SizedBox(
          width: 82.w,
          child: Text(
            label,
            style: AppTypography.caption1.copyWith(color: AppColors.gray500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body3.copyWith(color: AppColors.gray900),
          ),
        ),
      ],
    ),
  );
}
