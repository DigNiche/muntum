import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/announcement_model.dart';
import 'package:muntum/screens/mypage/announcement_detail_screen.dart';
import 'package:muntum/screens/mypage/manager/announcement_edit_screen.dart';
import 'package:muntum/services/announcement_service.dart';
import 'package:muntum/utils/app_toast.dart';

enum _AnnouncementAction { edit, delete }

class AnnouncementManageScreen extends StatefulWidget {
  const AnnouncementManageScreen({super.key});

  @override
  State<AnnouncementManageScreen> createState() =>
      _AnnouncementManageScreenState();
}

class _AnnouncementManageScreenState extends State<AnnouncementManageScreen> {
  static const int _pageSize = 20;

  final _service = AnnouncementService();
  final _scrollController = ScrollController();
  final List<AnnouncementModel> _announcements = [];
  int _nextPage = 0;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAnnouncements(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasNext || _isLoadingMore) return;
    if (_scrollController.position.extentAfter < 200.h) {
      _loadAnnouncements();
    }
  }

  Future<void> _loadAnnouncements({bool reset = false}) async {
    if (reset) {
      setState(() {
        _announcements.clear();
        _nextPage = 0;
        _hasNext = true;
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasNext) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _service.fetchAnnouncements(
        page: reset ? 0 : _nextPage,
        size: _pageSize,
        manager: true,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _announcements.clear();
        _announcements.addAll(
          response.content.where(
            (announcement) => announcement.deletedAt == null,
          ),
        );
        _nextPage = response.page + 1;
        _hasNext = response.hasMore;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '$error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AnnouncementEditScreen()),
    );
    if (mounted && created == true) await _loadAnnouncements(reset: true);
  }

  Future<void> _showActions(AnnouncementModel announcement) async {
    final action = await showModalBottomSheet<_AnnouncementAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.dimMedium,
      builder: (sheetContext) => _AnnouncementActionSheet(
        onEdit: () => Navigator.pop(sheetContext, _AnnouncementAction.edit),
        onDelete: () => Navigator.pop(sheetContext, _AnnouncementAction.delete),
      ),
    );
    if (!mounted || action == null) return;

    if (action == _AnnouncementAction.edit) {
      AnnouncementModel detail = announcement;
      try {
        detail = await _service.fetchAnnouncement(
          announcement.id,
          authorized: true,
        );
      } catch (error) {
        if (mounted) showAppToast(context, '$error', isError: true);
        return;
      }
      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => AnnouncementEditScreen(announcement: detail),
        ),
      );
      if (mounted && saved == true) await _loadAnnouncements(reset: true);
      return;
    }

    await showPopupWidget(
      context: context,
      title: '공지사항을 삭제할까요?',
      description: '삭제된 데이터는 복구할 수 없어요.',
      text1: '취소',
      text2: '삭제',
      text2Color: AppColors.error,
      onText1Tap: () => Navigator.pop(context),
      onText2Tap: () {
        Navigator.pop(context);
        _delete(announcement);
      },
    );
  }

  Future<void> _delete(AnnouncementModel announcement) async {
    try {
      await _service.deleteAnnouncement(announcement.id);
      if (!mounted) return;
      setState(
        () => _announcements.removeWhere((item) => item.id == announcement.id),
      );
      showAppToast(context, '공지사항이 삭제되었습니다.');
    } catch (error) {
      if (mounted) showAppToast(context, '$error', isError: true);
    }
  }

  void _openDetail(AnnouncementModel announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(announcement: announcement),
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
            leadingIcon: 'arrow_left.svg',
            center: '공지사항 관리',
            onLeadingTap: () => Navigator.pop(context),
            trailing: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openCreate,
              child: SizedBox(
                width: 24.r,
                height: 24.r,
                child: SvgPicture.asset(
                  'assets/icons/plus.svg',
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray900,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _announcements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }
    if (_errorMessage != null && _announcements.isEmpty) {
      return _AnnouncementMessage(
        message: '공지사항을 불러오지 못했어요.',
        onTap: () => _loadAnnouncements(reset: true),
      );
    }
    if (_announcements.isEmpty) {
      return const _AnnouncementMessage(message: '등록된 공지사항이 없어요.');
    }

    return RefreshIndicator(
      color: AppColors.gray900,
      onRefresh: () => _loadAnnouncements(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
        itemCount: _announcements.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _announcements.length) {
            return Padding(
              padding: EdgeInsets.all(16.r),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gray900),
              ),
            );
          }
          final announcement = _announcements[index];
          return _AnnouncementItem(
            announcement: announcement,
            onTap: () => _openDetail(announcement),
            onMoreTap: () => _showActions(announcement),
          );
        },
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({
    required this.announcement,
    required this.onTap,
    required this.onMoreTap,
  });

  final AnnouncementModel announcement;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.lineNormal, width: 1.h),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    _formatDate(announcement.createdAt),
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onMoreTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 0, 20.h),
                child: Icon(
                  Icons.more_vert,
                  size: 20.r,
                  color: AppColors.gray400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.year}년 ${local.month.toString().padLeft(2, '0')}월 '
        '${local.day.toString().padLeft(2, '0')}일';
  }
}

class _AnnouncementActionSheet extends StatelessWidget {
  const _AnnouncementActionSheet({
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        24.h,
        20.w,
        MediaQuery.paddingOf(context).bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionText(text: '수정하기', onTap: onEdit),
          _ActionText(text: '삭제하기', onTap: onDelete),
        ],
      ),
    );
  }
}

class _ActionText extends StatelessWidget {
  const _ActionText({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Text(
          text,
          style: AppTypography.body1.copyWith(color: AppColors.gray900),
        ),
      ),
    );
  }
}

class _AnnouncementMessage extends StatelessWidget {
  const _AnnouncementMessage({required this.message, this.onTap});

  final String message;
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
          if (onTap != null) ...[
            SizedBox(height: 12.h),
            TextButton(onPressed: onTap, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}
