import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/program_curator_badge.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/screens/mypage/curator/curation_action_sheet.dart';
import 'package:muntum/screens/mypage/curator/curation_write_screen.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/current_user_profile_image_store.dart';
import 'package:muntum/utils/app_toast.dart';

class ProgramCurationsSection extends StatefulWidget {
  const ProgramCurationsSection({
    super.key,
    required this.programId,
    required this.programTitle,
    this.service,
  });

  final String programId;
  final String programTitle;
  final CurationService? service;

  @override
  State<ProgramCurationsSection> createState() =>
      _ProgramCurationsSectionState();
}

class _ProgramCurationsSectionState extends State<ProgramCurationsSection> {
  late final CurationService _service = widget.service ?? CurationService();
  late Future<List<PublicCurationModel>> _curations;
  final Map<String, Future<PublicCurationModel>> _details = {};
  final ScrollController _cardsController = ScrollController();

  @override
  void dispose() {
    _cardsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _curations = _load();
  }

  @override
  void didUpdateWidget(covariant ProgramCurationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programId != widget.programId) {
      _details.clear();
      _curations = _load();
      if (_cardsController.hasClients) _cardsController.jumpTo(0);
    }
  }

  void _scrollToCard(int index, double cardWidth) {
    if (!_cardsController.hasClients) return;
    final target = ((cardWidth + 12.w) * index).clamp(
      0.0,
      _cardsController.position.maxScrollExtent,
    );
    _cardsController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<PublicCurationModel> _detailFor(PublicCurationModel summary) =>
      _details.putIfAbsent(
        summary.id,
        () => _service.fetchProgramCurationDetail(widget.programId, summary.id),
      );

  Future<List<PublicCurationModel>> _load() async {
    if (widget.programId.isEmpty) return const [];
    try {
      final page = await _service.fetchProgramCurations(widget.programId);
      return page.content;
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PublicCurationModel>>(
      future: _curations,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <PublicCurationModel>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final cardWidth = 300.w.clamp(
          0.0,
          MediaQuery.sizeOf(context).width - 40.w,
        );
        final cardHeight = cardWidth * 395 / 300;
        Widget cardFor(PublicCurationModel item, {required int index}) =>
            SizedBox(
              width: cardWidth,
              child: FutureBuilder<PublicCurationModel>(
                future: _detailFor(item),
                builder: (context, detailSnapshot) => _CurationNoteCard(
                  curation: detailSnapshot.data == null
                      ? item
                      : item.mergeDetails(detailSnapshot.data!),
                  cardHeight: cardHeight,
                  showNextArrow: index < items.length - 1,
                  showPreviousArrow: index > 0,
                  onNextArrowTap: () => _scrollToCard(index + 1, cardWidth),
                  onPreviousArrowTap: () => _scrollToCard(index - 1, cardWidth),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicCurationDetailScreen(
                        programId: widget.programId,
                        programTitle: widget.programTitle,
                        summary: item,
                        service: _service,
                      ),
                    ),
                  ),
                ),
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.backgroundNormal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 18.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '큐레이터',
                          style: AppTypography.title3.copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: SvgPicture.asset(
                            'assets/curator_note_font.svg',
                            key: const ValueKey('curator-note-title-svg'),
                            width: 39.w,
                            height: 21.h,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: cardHeight,
                    child: items.length == 1
                        ? Center(child: cardFor(items.single, index: 0))
                        : ListView.separated(
                            controller: _cardsController,
                            padding: EdgeInsets.only(
                              left: 20.w,
                              right: math.max(
                                20.w,
                                MediaQuery.sizeOf(context).width -
                                    cardWidth -
                                    20.w,
                              ),
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, _) => SizedBox(width: 12.w),
                            itemBuilder: (context, index) =>
                                cardFor(items[index], index: index),
                          ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CurationNoteCard extends StatelessWidget {
  const _CurationNoteCard({
    required this.curation,
    required this.cardHeight,
    required this.showNextArrow,
    required this.showPreviousArrow,
    required this.onNextArrowTap,
    required this.onPreviousArrowTap,
    required this.onTap,
  });

  final PublicCurationModel curation;
  final double cardHeight;
  final bool showNextArrow;
  final bool showPreviousArrow;
  final VoidCallback onNextArrowTap;
  final VoidCallback onPreviousArrowTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageHeight = cardHeight * 0.55;
    return Material(
      key: ValueKey('curation-note-${curation.id}'),
      color: AppColors.gray900,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CurationImage(url: curation.thumbnailUrl),
                      if (showPreviousArrow)
                        Positioned(
                          left: 8.w,
                          bottom: 7.h,
                          child: IconButton(
                            key: const ValueKey('curator-note-previous-arrow'),
                            onPressed: onPreviousArrowTap,
                            icon: Transform.rotate(
                              angle: math.pi,
                              child: SvgPicture.asset(
                                'assets/icons/curator_note_next_arrow.svg',
                              ),
                            ),
                          ),
                        ),
                      if (showNextArrow)
                        Positioned(
                          right: 8.w,
                          bottom: 7.h,
                          child: IconButton(
                            key: const ValueKey('curator-note-next-arrow'),
                            onPressed: onNextArrowTap,
                            icon: SvgPicture.asset(
                              'assets/icons/curator_note_next_arrow.svg',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(18.w, 28.h, 18.w, 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.gray900,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10.r),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/curator_by_font.svg',
                              key: const ValueKey('curator-by-font-svg'),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              curation.curatorName,
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          curation.tagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline1.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        if (curation.content.isNotEmpty)
                          Text(
                            curation.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 18.w,
              top: imageHeight - 20.r,
              child: _NoteCuratorAvatar(
                curatorId: curation.curatorId,
                imageUrl: curation.curatorImageUrl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCuratorAvatar extends StatelessWidget {
  const _NoteCuratorAvatar({required this.curatorId, required this.imageUrl});

  final String? curatorId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/default_profile_img.jpg',
      width: 40.r,
      height: 40.r,
      fit: BoxFit.cover,
    );
    return AnimatedBuilder(
      animation: CurrentUserProfileImageStore.instance,
      builder: (context, _) {
        final resolvedUrl = CurrentUserProfileImageStore.instance.resolve(
          userId: curatorId,
          apiImageUrl: imageUrl,
        );
        return ClipOval(
          child: resolvedUrl?.isNotEmpty == true
              ? Image.network(
                  resolvedUrl!,
                  width: 40.r,
                  height: 40.r,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                )
              : fallback,
        );
      },
    );
  }
}

class PublicCurationDetailScreen extends StatefulWidget {
  const PublicCurationDetailScreen({
    super.key,
    required this.programId,
    required this.programTitle,
    required this.summary,
    this.service,
  });

  final String programId;
  final String programTitle;
  final PublicCurationModel summary;
  final CurationService? service;

  @override
  State<PublicCurationDetailScreen> createState() =>
      _PublicCurationDetailScreenState();
}

class _PublicCurationDetailScreenState
    extends State<PublicCurationDetailScreen> {
  late final CurationService _service = widget.service ?? CurationService();
  late final Future<PublicCurationModel> _detail = _service
      .fetchProgramCurationDetail(widget.programId, widget.summary.id);

  Future<void> _showAuthorActions() async {
    final action = await showCurationActionSheet(context);
    if (!mounted || action == null) return;
    try {
      final mine = await _service.fetchMyDetail(widget.summary.id);
      if (!mounted) return;
      if (action == CurationAction.edit) {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CurationWriteScreen(
              service: _service,
              initialCuration: mine,
              resubmitAfterUpdate:
                  mine.status == CurationStatus.changesRequested,
            ),
          ),
        );
        if (mounted && updated == true) Navigator.pop(context, 'updated');
        return;
      }
      if (mine.status == CurationStatus.approved) {
        showAppToast(context, '승인된 글은 삭제할 수 없어요.', isError: true);
        return;
      }
      final confirmed = await showConfirmationPopupWidget(
        context: context,
        title: '작성한 글을 삭제할까요?',
        description: '삭제한 글은 복구할 수 없어요.',
        confirmText: '삭제',
        confirmColor: AppColors.error,
      );
      if (!confirmed || !mounted) return;
      await _service.delete(mine.id);
      if (mounted) Navigator.pop(context, 'deleted');
    } catch (_) {
      if (mounted) showAppToast(context, '글을 처리하지 못했어요.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.gray900,
        title: Text(
          widget.programTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headline1.copyWith(color: AppColors.gray900),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<PublicCurationModel>(
        future: _detail,
        builder: (context, snapshot) {
          final detail = snapshot.data == null
              ? widget.summary
              : widget.summary.mergeDetails(snapshot.data!);
          final imageUrls = detail.images.isNotEmpty
              ? detail.images.map((image) => image.imageUrl).toList()
              : detail.thumbnailUrl == null
              ? const <String>[]
              : <String>[detail.thumbnailUrl!];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.tagline,
                        key: const ValueKey('curation-detail-title'),
                        style: AppTypography.title3.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        children: [
                          _DetailCuratorAvatar(
                            curatorId: detail.curatorId,
                            imageUrl: detail.curatorImageUrl,
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.curatorName,
                                style: AppTypography.headline3.copyWith(
                                  color: AppColors.gray900,
                                ),
                              ),
                              if (detail.formattedCreatedAt.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  '작성일 ${detail.formattedCreatedAt}',
                                  style: AppTypography.caption2.copyWith(
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Spacer(),
                          if (detail.curatorId != null &&
                              detail.curatorId == AuthState.instance.userId)
                            GestureDetector(
                              key: const ValueKey('public-curation-actions'),
                              behavior: HitTestBehavior.opaque,
                              onTap: _showAuthorActions,
                              child: Padding(
                                padding: EdgeInsets.all(8.r),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 20.r,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (imageUrls.isNotEmpty) ...[
                  SizedBox(height: 28.h),
                  SizedBox(
                    height: 320.w,
                    child: ListView.separated(
                      key: const ValueKey('curation-detail-images'),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      separatorBuilder: (_, _) => SizedBox(width: 12.w),
                      itemBuilder: (_, index) => ClipRRect(
                        key: ValueKey('curation-detail-image-$index'),
                        borderRadius: BorderRadius.circular(8.r),
                        child: SizedBox(
                          width: 240.w,
                          child: _CurationImage(url: imageUrls[index]),
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 50.h),
                  child: Text(
                    snapshot.hasError && detail.content.isEmpty
                        ? '큐레이션 내용을 불러오지 못했어요.'
                        : detail.content,
                    key: const ValueKey('curation-detail-content'),
                    style: AppTypography.body3.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailCuratorAvatar extends StatelessWidget {
  const _DetailCuratorAvatar({required this.curatorId, required this.imageUrl});

  final String? curatorId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/default_profile_img.jpg',
      width: 40.r,
      height: 40.r,
      fit: BoxFit.cover,
    );
    return AnimatedBuilder(
      animation: CurrentUserProfileImageStore.instance,
      builder: (context, _) {
        final resolvedUrl = CurrentUserProfileImageStore.instance.resolve(
          userId: curatorId,
          apiImageUrl: imageUrl,
        );
        return SizedBox(
          width: 42.r,
          height: 42.r,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: resolvedUrl?.isNotEmpty == true
                    ? Image.network(
                        resolvedUrl!,
                        width: 40.r,
                        height: 40.r,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      )
                    : fallback,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: ProgramCuratorBadge(size: 14.r),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurationImage extends StatelessWidget {
  const _CurationImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.gray100,
        child: Center(
          child: Icon(Icons.image_outlined, color: AppColors.gray400),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.gray100,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.gray400),
        ),
      ),
    );
  }
}
