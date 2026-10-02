import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/manager/curation_review_screen.dart';
import 'package:muntum/services/admin_curation_service.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/utils/app_toast.dart';

class ProgramCurationsManageScreen extends StatefulWidget {
  const ProgramCurationsManageScreen({
    super.key,
    required this.program,
    this.curationService,
    this.adminService,
  });

  final ProgramModel program;
  final CurationService? curationService;
  final AdminCurationService? adminService;

  @override
  State<ProgramCurationsManageScreen> createState() =>
      _ProgramCurationsManageScreenState();
}

class _ProgramCurationsManageScreenState
    extends State<ProgramCurationsManageScreen> {
  late final CurationService _curationService =
      widget.curationService ?? CurationService();
  late final AdminCurationService _adminService =
      widget.adminService ?? AdminCurationService();
  late Future<List<AdminCurationModel>> _curations = _loadCurations();
  final Set<String> _expanded = {};
  final Set<String> _knownIds = {};
  bool _working = false;

  Future<List<AdminCurationModel>> _loadCurations() async {
    final ids = <String>[];
    var page = 0;
    while (true) {
      final response = await _curationService.fetchProgramCurations(
        widget.program.id,
        page: page,
      );
      ids.addAll(response.content.map((item) => item.id));
      if (!response.hasMore || response.content.isEmpty) break;
      page = response.page + 1;
    }

    // The public endpoint omits unpublished change requests. The manager
    // endpoint cannot filter by program ID, so verify candidate details.
    page = 0;
    while (true) {
      final response = await _adminService.fetchList(
        status: CurationStatus.changesRequested,
        page: page,
        size: 100,
      );
      // The submitted title may differ from the linked program title. Match
      // only after loading the detail, which carries the actual program ID.
      ids.addAll(response.content.map((item) => item.curation.id));
      if (!response.hasMore || response.content.isEmpty) break;
      page = response.page + 1;
    }

    // Keep already visible cards while the public and manager lists catch up
    // immediately after a publication-state change.
    ids.addAll(_knownIds);
    final details = await Future.wait(
      ids.toSet().map((id) => _adminService.fetchDetail(id)),
    );
    final linked = details
        .where((item) => item.curation.programId == widget.program.id)
        .toList();
    _knownIds.addAll(linked.map((item) => item.curation.id));
    return linked;
  }

  void _refresh() => setState(() => _curations = _loadCurations());

  Future<void> _openReview(AdminCurationModel item) async {
    if (_working) return;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CurationReviewScreen(summary: item, service: _adminService),
      ),
    );
    if (mounted && result != null) _refresh();
  }

  Future<void> _requestChanges(AdminCurationModel item) async {
    if (_working) return;
    final selection = await showModalBottomSheet<CurationChangeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (_) => const ChangeReasonSheet(),
    );
    if (!mounted || selection == null) return;
    setState(() => _working = true);
    try {
      await _adminService.requestChanges(
        curationId: item.curation.id,
        reason: selection.reason,
        publicationStatus: selection.publicationStatus,
      );
      if (mounted) _refresh();
    } on ApiException catch (error) {
      if (mounted) {
        if (error.code == 'CURATION_CHANGE_UNVERIFIED') _refresh();
        showAppToast(context, error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context, '수정 요청을 보내지 못했어요.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: SafeArea(
      child: Column(
        children: [
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '[큐레이션] ${widget.program.title}',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<AdminCurationModel>>(
              future: _curations,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: _refresh,
                      child: const Text('큐레이션 글을 불러오지 못했어요. 다시 시도'),
                    ),
                  );
                }
                final items = snapshot.data ?? const <AdminCurationModel>[];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      '이 프로그램의 큐레이션 글이 없어요.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Container(height: 8.h, color: AppColors.backgroundNormal),
                  itemBuilder: (context, index) => _buildPost(items[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPost(AdminCurationModel item) {
    final curation = item.curation;
    final expanded = _expanded.contains(curation.id);
    final requested = curation.status == CurationStatus.changesRequested;
    final unpublished =
        requested && curation.publicationStatus == 'UNPUBLISHED';
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.white,
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CuratorAvatar(imageUrl: item.curator.profileImageUrl),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.curator.nickname,
                          style: AppTypography.headline3,
                        ),
                        Text(
                          '작성일 ${curation.formattedCreatedAt}',
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: Key('program-curation-request-${curation.id}'),
                    onPressed: _working
                        ? null
                        : requested
                        ? () => _openReview(item)
                        : () => _requestChanges(item),
                    child: Text(
                      requested ? '수정요청 1 ›' : '수정요청',
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(curation.tagline, style: AppTypography.headline1),
              SizedBox(height: 16.h),
              Text(
                curation.content,
                maxLines: expanded ? null : 8,
                overflow: expanded ? null : TextOverflow.ellipsis,
                style: AppTypography.body3,
              ),
              if (!expanded && curation.content.length > 140)
                TextButton(
                  key: Key('program-curation-more-${curation.id}'),
                  onPressed: () => setState(() => _expanded.add(curation.id)),
                  child: Text(
                    '더보기',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              if (curation.images.isNotEmpty) ...[
                SizedBox(height: 18.h),
                SizedBox(
                  height: 70.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: curation.images.length,
                    separatorBuilder: (_, _) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        curation.images[index].imageUrl,
                        width: 55.w,
                        height: 70.h,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 55.w,
                          color: AppColors.gray100,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (unpublished)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFEFEC),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              children: [
                const Icon(Icons.error, color: AppColors.error, size: 17),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '해당 글은 수정 요청으로 비공개 처리되었습니다.',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CuratorAvatar extends StatelessWidget {
  const _CuratorAvatar({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Image.asset(
      'assets/default_profile_img.jpg',
      width: 40.r,
      height: 40.r,
      fit: BoxFit.cover,
    );
    return SizedBox(
      width: 42.r,
      height: 42.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: imageUrl?.isNotEmpty == true
                ? Image.network(
                    imageUrl!,
                    width: 40.r,
                    height: 40.r,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback(),
                  )
                : fallback(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SvgPicture.asset(
              'assets/icons/curator_badge.svg',
              width: 15.r,
              height: 15.r,
            ),
          ),
        ],
      ),
    );
  }
}
