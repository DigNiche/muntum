import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/screens/mypage/manager/curator_application_review_screen.dart';
import 'package:muntum/services/curator_application_service.dart';

class CuratorApplicationManageScreen extends StatefulWidget {
  const CuratorApplicationManageScreen({super.key, this.service});

  final CuratorApplicationService? service;

  @override
  State<CuratorApplicationManageScreen> createState() =>
      _CuratorApplicationManageScreenState();
}

class _CuratorApplicationManageScreenState
    extends State<CuratorApplicationManageScreen> {
  late final CuratorApplicationService _service;
  var _selectedStatus = CuratorApplicationStatus.pending;
  List<CuratorApplicationModel> _pending = const [];
  List<CuratorApplicationModel> _rejected = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<CuratorApplicationModel> get _selectedApplications =>
      _selectedStatus == CuratorApplicationStatus.pending
      ? _pending
      : _rejected;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CuratorApplicationService();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchAllForManager(status: CuratorApplicationStatus.pending),
        _service.fetchAllForManager(status: CuratorApplicationStatus.rejected),
      ]);
      if (!mounted) return;
      setState(() {
        _pending = results[0];
        _rejected = results[1];
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '지원 목록을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail(CuratorApplicationModel application) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CuratorApplicationReviewScreen(
          applicationId: application.id,
          initialApplication: application,
          service: _service,
        ),
      ),
    );
    if (changed == true && mounted) await _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNormal,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.white,
            child: Column(
              children: [
                SizedBox(height: 50.h),
                AppBarWidget(
                  centerType: AppBarCenterType.text,
                  leadingIcon: 'arrow_left.svg',
                  center: '큐레이터 관리',
                  onLeadingTap: () => Navigator.pop(context),
                ),
                _StatusTabs(
                  selectedStatus: _selectedStatus,
                  pendingCount: _pending.length,
                  rejectedCount: _rejected.length,
                  onChanged: (status) =>
                      setState(() => _selectedStatus = status),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }
    if (_errorMessage != null) {
      return _MessageState(message: _errorMessage!, onTap: _loadApplications);
    }
    if (_selectedApplications.isEmpty) {
      return Center(
        child: Text(
          _selectedStatus == CuratorApplicationStatus.pending
              ? '대기 중인 지원서가 없어요.'
              : '반려된 지원서가 없어요.',
          style: AppTypography.body2.copyWith(color: AppColors.gray500),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.gray900,
      onRefresh: _loadApplications,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 40.h),
        itemCount: _selectedApplications.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final application = _selectedApplications[index];
          return _ApplicationCard(
            application: application,
            onTap: () => _openDetail(application),
          );
        },
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.selectedStatus,
    required this.pendingCount,
    required this.rejectedCount,
    required this.onChanged,
  });

  final CuratorApplicationStatus selectedStatus;
  final int pendingCount;
  final int rejectedCount;
  final ValueChanged<CuratorApplicationStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab(
          status: CuratorApplicationStatus.pending,
          label: '대기 $pendingCount',
        ),
        _tab(
          status: CuratorApplicationStatus.rejected,
          label: '반려 $rejectedCount',
        ),
      ],
    );
  }

  Widget _tab({
    required CuratorApplicationStatus status,
    required String label,
  }) {
    final selected = selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(status),
        child: Column(
          children: [
            SizedBox(height: 13.h),
            Text(
              label,
              style: AppTypography.button3.copyWith(
                color: selected ? AppColors.gray900 : AppColors.gray400,
              ),
            ),
            SizedBox(height: 13.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.h,
              color: selected ? AppColors.gray900 : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.onTap});

  final CuratorApplicationModel application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final applicant = application.applicant;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(status: application.status),
                Text(
                  application.formattedCreatedAt,
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _ApplicantAvatar(imageUrl: applicant?.profileImageUrl),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant?.nickname ?? '닉네임 미설정',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.button3.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        applicant?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption3.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CuratorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final pending = status == CuratorApplicationStatus.pending;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: pending ? AppColors.primary100 : AppColors.gray100,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        pending ? '대기중' : '반려',
        style: AppTypography.badge.copyWith(
          color: pending ? AppColors.primary800 : AppColors.gray600,
        ),
      ),
    );
  }
}

class _ApplicantAvatar extends StatelessWidget {
  const _ApplicantAvatar({required this.imageUrl});

  final String? imageUrl;
  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/default_profile_img.jpg',
      width: size.r,
      height: size.r,
      fit: BoxFit.cover,
    );
    final url = imageUrl?.trim();
    return ClipOval(
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              width: size.r,
              height: size.r,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onTap});

  final String message;
  final VoidCallback onTap;

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
          SizedBox(height: 12.h),
          TextButton(onPressed: onTap, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
