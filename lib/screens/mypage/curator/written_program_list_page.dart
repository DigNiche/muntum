import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/app_color_transition.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/curator/curation_action_sheet.dart';
import 'package:muntum/screens/mypage/curator/curation_detail_screen.dart';
import 'package:muntum/screens/mypage/curator/curation_write_screen.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/screens/program_detail/components/program_curations_section.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/utils/app_toast.dart';

enum _CurationTab { posts, status }

enum _StatusFilter { pending, changesRequested }

class WrittenProgramList extends StatefulWidget {
  const WrittenProgramList({super.key, this.service, this.programService});

  final CurationService? service;
  final ProgramService? programService;

  @override
  State<WrittenProgramList> createState() => _WrittenProgramListState();
}

class _WrittenProgramListState extends State<WrittenProgramList> {
  late final CurationService _service;
  late final ProgramService _programService;
  CuratorProfileModel? _profile;
  List<CurationModel> _curations = const [];
  _CurationTab _selectedTab = _CurationTab.posts;
  _StatusFilter _statusFilter = _StatusFilter.pending;
  bool _isLoading = true;
  String? _errorMessage;

  List<CurationModel> get _visibleCurations =>
      _selectedTab == _CurationTab.posts
      ? _curations
            .where((curation) => curation.publicationStatus == 'PUBLISHED')
            .toList()
      : _curations.where((curation) {
          return _statusFilter == _StatusFilter.pending
              ? _isAwaitingPublication(curation)
              : curation.status == CurationStatus.changesRequested;
        }).toList();

  bool _isAwaitingPublication(CurationModel curation) =>
      curation.status == CurationStatus.pending &&
      curation.publicationStatus != 'PUBLISHED';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CurationService();
    _programService = widget.programService ?? ProgramService();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait<Object>([
        _service.fetchMyProfile(),
        _service.fetchAllMineWithDetails(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as CuratorProfileModel;
        _curations = results[1] as List<CurationModel>;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _finishWithError(error.message);
    } catch (_) {
      _finishWithError('큐레이션을 불러오지 못했어요.');
    }
  }

  void _finishWithError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _openWriter() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CurationWriteScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _openDetail(CurationModel curation) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CurationDetailScreen(
          curation: curation,
          service: _service,
          programService: _programService,
        ),
      ),
    );
    if (!mounted || result == null) return;
    await _load();
    if (!mounted) return;
    if (result == 'deleted') {
      showAppToast(context, '글이 삭제되었습니다.');
    } else if (curation.publicationStatus == 'PUBLISHED') {
      showAppToast(context, '수정 내용이 정상 등록되었습니다.');
    } else {
      showAppToast(context, '수정이 완료되었습니다. 관리자 확인 후 등록됩니다.');
    }
  }

  Future<void> _openPostActions(CurationModel curation) async {
    final action = await showCurationActionSheet(context);
    if (!mounted || action == null) return;
    if (action == CurationAction.edit) {
      final updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CurationWriteScreen(
            service: _service,
            initialCuration: curation,
            resubmitAfterUpdate:
                curation.status == CurationStatus.changesRequested,
          ),
        ),
      );
      if (mounted && updated == true) await _load();
      return;
    }
    if (curation.status == CurationStatus.approved) {
      showAppToast(context, '승인된 글은 삭제할 수 없어요.', isError: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('작성한 글을 삭제할까요?'),
        content: const Text('삭제한 글은 복구할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.delete(curation.id);
      if (!mounted) return;
      await _load();
      if (mounted) showAppToast(context, '글이 삭제되었습니다.');
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, isError: true);
    } catch (_) {
      if (mounted) showAppToast(context, '글을 삭제하지 못했어요.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gray900,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    AppBarWidget(
                      centerType: AppBarCenterType.none,
                      leadingIcon: 'arrow_left.svg',
                      onLeadingTap: () => Navigator.pop(context),
                    ),
                    _ProfileHeader(profile: _profile),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 6.h),
                      child: _WriteButton(onTap: _openWriter),
                    ),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabsDelegate(
                  child: _CurationTabs(
                    selected: _selectedTab,
                    onSelected: (tab) => setState(() => _selectedTab = tab),
                  ),
                ),
              ),
              if (_selectedTab == _CurationTab.status && !_isLoading)
                SliverToBoxAdapter(
                  child: _StatusFilters(
                    selected: _statusFilter,
                    pendingCount: _curations
                        .where(_isAwaitingPublication)
                        .length,
                    changesCount: _curations
                        .where(
                          (item) =>
                              item.status == CurationStatus.changesRequested,
                        )
                        .length,
                    onSelected: (filter) =>
                        setState(() => _statusFilter = filter),
                  ),
                ),
              _buildSliverBody(),
              if (_selectedTab == _CurationTab.status &&
                  !_isLoading &&
                  _errorMessage == null &&
                  _visibleCurations.isNotEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ColoredBox(color: AppColors.backgroundNormal),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverBody() {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gray900),
        ),
      );
    }
    if (_errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _LoadError(message: _errorMessage!, onRetry: _load),
      );
    }
    final curations = _visibleCurations;
    if (curations.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ColoredBox(
          color: _selectedTab == _CurationTab.status
              ? AppColors.backgroundNormal
              : AppColors.white,
          child: Center(
            child: Text(
              _selectedTab == _CurationTab.posts
                  ? '아직 등록된 작성글이 없어요.'
                  : _statusFilter == _StatusFilter.pending
                  ? '등록 대기 글이 없어요.'
                  : '수정 요청 글이 없어요.',
              style: AppTypography.body2.copyWith(color: AppColors.gray500),
            ),
          ),
        ),
      );
    }
    if (_selectedTab == _CurationTab.status) {
      return SliverList.builder(
        itemCount: curations.length + 1,
        itemBuilder: (context, index) => ColoredBox(
          color: AppColors.backgroundNormal,
          child: index == curations.length
              ? SizedBox(height: 32.h)
              : Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                  child: _StatusCard(
                    curation: curations[index],
                    onTap: () => _openDetail(curations[index]),
                  ),
                ),
        ),
      );
    }
    return SliverList.separated(
      itemCount: curations.length,
      separatorBuilder: (_, _) =>
          Container(height: 8.h, color: AppColors.backgroundNormal),
      itemBuilder: (context, index) => _CurationPost(
        curation: curations[index],
        profile: _profile,
        showStatus: false,
        onOpenActions: () => _openPostActions(curations[index]),
        onChanged: _load,
        curationService: _service,
        programService: _programService,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final CuratorProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final nickname = profile?.nickname.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname?.isNotEmpty == true
                      ? nickname!
                      : AuthState.instance.nickname ?? '큐레이터',
                  style: AppTypography.headline1.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '작성글 ${profile?.totalCount ?? 0}',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          _CuratorAvatar(imageUrl: profile?.profileImageUrl, size: 48.r),
        ],
      ),
    );
  }
}

class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabsDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 48.h;

  @override
  double get maxExtent => 48.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: AppColors.white, child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyTabsDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.selected,
    required this.pendingCount,
    required this.changesCount,
    required this.onSelected,
  });

  final _StatusFilter selected;
  final int pendingCount;
  final int changesCount;
  final ValueChanged<_StatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundNormal,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 14.h),
        child: Row(
          children: [
            _StatusFilterChip(
              label: '등록대기 $pendingCount',
              selected: selected == _StatusFilter.pending,
              onTap: () => onSelected(_StatusFilter.pending),
            ),
            SizedBox(width: 8.w),
            _StatusFilterChip(
              label: '수정요청 $changesCount',
              selected: selected == _StatusFilter.changesRequested,
              onTap: () => onSelected(_StatusFilter.changesRequested),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.gray900 : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: AppTypography.button3.copyWith(
            color: selected ? AppColors.white : AppColors.gray500,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.curation, required this.onTap});

  final CurationModel curation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changesRequested = curation.status == CurationStatus.changesRequested;
    return Material(
      key: ValueKey('curation-status-${curation.id}'),
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      color: changesRequested
                          ? const Color(0xFFFFF0D2)
                          : AppColors.primary100,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Text(
                      changesRequested ? '수정요청' : '등록대기',
                      style: AppTypography.badge.copyWith(
                        color: changesRequested
                            ? AppColors.warning
                            : AppColors.primary800,
                      ),
                    ),
                  ),
                  if (curation.isRevisedPending) ...[
                    SizedBox(width: 5.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        '수정',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    curation.formattedCreatedAt,
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 13.h),
              Text(
                curation.programTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                curation.place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              if (changesRequested) ...[
                SizedBox(height: 16.h),
                Container(
                  height: 44.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lineStrong),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Text(
                    '확인하기',
                    style: AppTypography.button2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lineStrong),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Text(
          '+  새 글 작성하기',
          style: AppTypography.button3.copyWith(color: AppColors.gray900),
        ),
      ),
    );
  }
}

class _CurationTabs extends StatelessWidget {
  const _CurationTabs({required this.selected, required this.onSelected});

  final _CurationTab selected;
  final ValueChanged<_CurationTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lineNormal)),
      ),
      child: Row(
        children: [
          _CurationTabButton(
            label: '작성글',
            selected: selected == _CurationTab.posts,
            onTap: () => onSelected(_CurationTab.posts),
          ),
          _CurationTabButton(
            label: '작성현황',
            selected: selected == _CurationTab.status,
            onTap: () => onSelected(_CurationTab.status),
          ),
        ],
      ),
    );
  }
}

class _CurationTabButton extends StatelessWidget {
  const _CurationTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AppColorTransition(
          color: selected ? AppColors.gray900 : AppColors.gray500,
          builder: (context, textColor, _) => Container(
            height: 48.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.gray900 : Colors.transparent,
                  width: 2.h,
                ),
              ),
            ),
            child: Text(
              label,
              style: AppTypography.button3.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurationPost extends StatefulWidget {
  const _CurationPost({
    required this.curation,
    required this.profile,
    required this.showStatus,
    required this.onOpenActions,
    required this.onChanged,
    required this.curationService,
    required this.programService,
  });

  final CurationModel curation;
  final CuratorProfileModel? profile;
  final bool showStatus;
  final VoidCallback onOpenActions;
  final VoidCallback onChanged;
  final CurationService curationService;
  final ProgramService programService;

  @override
  State<_CurationPost> createState() => _CurationPostState();
}

class _CurationPostState extends State<_CurationPost> {
  bool _expanded = false;
  bool _openingProgram = false;
  ProgramModel? _linkedProgram;
  bool _linkedProgramLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadLinkedProgram();
  }

  @override
  void didUpdateWidget(covariant _CurationPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curation.programId != widget.curation.programId) {
      _linkedProgram = null;
      _linkedProgramLoadFailed = false;
      _loadLinkedProgram();
    }
  }

  Future<void> _loadLinkedProgram() async {
    final programId = widget.curation.programId;
    if (programId == null || programId.isEmpty) return;
    try {
      final program = await widget.programService.fetchProgram(programId);
      if (mounted && widget.curation.programId == programId) {
        setState(() => _linkedProgram = program);
      }
    } catch (_) {
      if (mounted) setState(() => _linkedProgramLoadFailed = true);
    }
  }

  Future<void> _openProgram() async {
    final programId = widget.curation.programId;
    if (programId == null || programId.isEmpty || _openingProgram) return;
    setState(() => _openingProgram = true);
    try {
      final program =
          _linkedProgram ??
          await widget.programService.fetchProgram(programId, authorized: true);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProgramDetailScreen(program: program, entrySource: 'my_curation'),
        ),
      );
    } catch (_) {
      if (mounted) {
        showAppToast(context, '연결된 프로그램을 열지 못했어요.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _openingProgram = false);
    }
  }

  Future<void> _openPublicCuration() async {
    final curation = widget.curation;
    final programId = curation.programId;
    if (programId == null || programId.isEmpty || _openingProgram) return;
    setState(() => _openingProgram = true);
    try {
      final program =
          _linkedProgram ?? await widget.programService.fetchProgram(programId);
      if (!mounted) return;
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PublicCurationDetailScreen(
            programId: programId,
            programTitle: program.title,
            summary: PublicCurationModel(
              id: curation.id,
              programId: programId,
              curatorId: widget.profile?.curatorId,
              curatorName: widget.profile?.nickname ?? '큐레이터',
              curatorImageUrl: widget.profile?.profileImageUrl,
              tagline: curation.tagline,
              thumbnailUrl: curation.images.firstOrNull?.imageUrl,
              content: curation.content,
              images: curation.images,
              createdAt: curation.createdAt,
            ),
            service: widget.curationService,
          ),
        ),
      );
      if (mounted && result != null) widget.onChanged();
    } catch (_) {
      if (mounted) {
        showAppToast(context, '큐레이터 글을 열지 못했어요.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _openingProgram = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final curation = widget.curation;
    return GestureDetector(
      key: ValueKey('curation-post-${curation.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: _openPublicCuration,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showStatus) ...[
              _StatusBadge(status: curation.status),
              SizedBox(height: 12.h),
            ],
            Row(
              children: [
                _CuratorAvatar(
                  imageUrl: widget.profile?.profileImageUrl,
                  size: 36.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile?.nickname ??
                            AuthState.instance.nickname ??
                            '큐레이터',
                        style: AppTypography.headline3.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        '작성일 ${curation.formattedCreatedAt}',
                        style: AppTypography.caption3.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.profile?.curatorId.isNotEmpty == true &&
                    widget.profile?.curatorId == AuthState.instance.userId)
                  GestureDetector(
                    key: ValueKey('curation-post-actions-${curation.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onOpenActions,
                    child: Padding(
                      padding: EdgeInsets.all(6.r),
                      child: Icon(
                        Icons.more_vert,
                        size: 20.r,
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 18.h),
            Text(
              curation.tagline,
              style: AppTypography.headline2.copyWith(color: AppColors.gray900),
            ),
            if (curation.content.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Text(
                curation.content,
                maxLines: _expanded ? null : 6,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: AppTypography.body3.copyWith(color: AppColors.gray800),
              ),
              SizedBox(height: 5.h),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  child: Text(
                    _expanded ? '접기' : '더보기',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              ),
            ],
            if (curation.images.isNotEmpty) ...[
              SizedBox(height: 10.h),
              SizedBox(
                height: 64.r,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: curation.images.length,
                  separatorBuilder: (_, _) => SizedBox(width: 6.w),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.network(
                      curation.images[index].imageUrl,
                      width: 64.r,
                      height: 64.r,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 64.r,
                        height: 64.r,
                        color: AppColors.gray100,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (curation.programId?.isNotEmpty == true) ...[
              SizedBox(height: 14.h),
              _LinkedProgramCard(
                title:
                    _linkedProgram?.title ??
                    (_linkedProgramLoadFailed
                        ? '프로그램 정보를 불러올 수 없어요.'
                        : '프로그램 정보를 불러오는 중'),
                place: _linkedProgram?.locationName ?? '',
                imageUrl: _linkedProgram?.imageUrls.firstOrNull,
                isLoading: _openingProgram,
                onTap: _openProgram,
              ),
            ],
            if (widget.showStatus && curation.changeRequestReason != null) ...[
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  curation.changeRequestReason!,
                  style: AppTypography.body3.copyWith(color: AppColors.gray700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkedProgramCard extends StatelessWidget {
  const _LinkedProgramCard({
    required this.title,
    required this.place,
    required this.imageUrl,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final String place;
  final String? imageUrl;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 58.h,
        padding: EdgeInsets.all(7.r),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lineStrong),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5.r),
              child: imageUrl == null
                  ? Container(
                      width: 42.r,
                      height: 42.r,
                      color: AppColors.gray100,
                    )
                  : Image.network(
                      imageUrl!,
                      width: 42.r,
                      height: 42.r,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 42.r,
                        height: 42.r,
                        color: AppColors.gray100,
                      ),
                    ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  if (place.isNotEmpty)
                    Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16.r,
                height: 16.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gray500,
                ),
              )
            else
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CurationStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      CurationStatus.pending => (AppColors.primary100, AppColors.primary800),
      CurationStatus.changesRequested => (AppColors.gray200, AppColors.gray700),
      CurationStatus.approved => (AppColors.primary100, AppColors.primary800),
      CurationStatus.unknown => (AppColors.gray100, AppColors.gray600),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        status.label,
        style: AppTypography.badge.copyWith(color: foreground),
      ),
    );
  }
}

class _CuratorAvatar extends StatelessWidget {
  const _CuratorAvatar({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/default_profile_img.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    return SizedBox(
      width: size + 4.r,
      height: size + 4.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: imageUrl?.isNotEmpty == true
                ? Image.network(
                    imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : fallback,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SvgPicture.asset(
              'assets/icons/curator_badge.svg',
              width: (size * 0.36).clamp(14.r, 20.r),
              height: (size * 0.36).clamp(14.r, 20.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: AppColors.gray600),
            ),
            SizedBox(height: 16.h),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
