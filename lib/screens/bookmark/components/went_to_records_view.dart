import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/services/program_reaction_service.dart';

class WentToRecordsView extends StatefulWidget {
  final bool isActive;

  const WentToRecordsView({super.key, this.isActive = true});

  @override
  State<WentToRecordsView> createState() => _WentToRecordsViewState();
}

class _WentToRecordsViewState extends State<WentToRecordsView> {
  static const _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<_WentToRecord> _records = [];
  final Map<ProgramReaction, int> _nextPages = {
    ProgramReaction.like: 0,
    ProgramReaction.dislike: 0,
  };
  final Map<ProgramReaction, bool> _hasNextPages = {
    ProgramReaction.like: true,
    ProgramReaction.dislike: true,
  };

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageIfNeeded);
    _loadRecords(reset: true);
  }

  @override
  void didUpdateWidget(covariant WentToRecordsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadRecords(reset: true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadNextPageIfNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 300.h) {
      return;
    }
    _loadRecords();
  }

  Future<void> _loadRecords({bool reset = false}) async {
    if (_isLoading ||
        (!reset && !_hasNextPages.values.any((hasNext) => hasNext))) {
      return;
    }

    if (reset) {
      _requestId++;
      for (final reaction in ProgramReaction.values) {
        _nextPages[reaction] = 0;
        _hasNextPages[reaction] = true;
      }
    }
    final requestId = _requestId;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        _fetchReactionPage(ProgramReaction.like),
        _fetchReactionPage(ProgramReaction.dislike),
      ]);
      if (!mounted || requestId != _requestId) return;

      final pageRecords = _interleaveRecords(
        responses[0]?.content ?? const [],
        responses[1]?.content ?? const [],
      );
      final recordsByProgramId = <String, _WentToRecord>{
        if (!reset)
          for (final record in _records) record.program.id: record,
        for (final record in pageRecords) record.program.id: record,
      };

      setState(() {
        _records
          ..clear()
          ..addAll(recordsByProgramId.values);
        _hasLoaded = true;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = '다녀온 기록을 불러오지 못했어요.';
        _hasLoaded = true;
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<PageResponse<ProgramModel>?> _fetchReactionPage(
    ProgramReaction reaction,
  ) async {
    if (_hasNextPages[reaction] != true) return null;
    final requestedPage = _nextPages[reaction] ?? 0;
    final response = await ProgramReactionService().fetchMyPrograms(
      reaction: reaction,
      page: requestedPage,
      size: _pageSize,
    );
    _nextPages[reaction] = response.page + 1;
    _hasNextPages[reaction] = response.hasMore;
    return response;
  }

  List<_WentToRecord> _interleaveRecords(
    List<ProgramModel> likedPrograms,
    List<ProgramModel> dislikedPrograms,
  ) {
    final records = <_WentToRecord>[];
    final longestLength = likedPrograms.length > dislikedPrograms.length
        ? likedPrograms.length
        : dislikedPrograms.length;
    for (var index = 0; index < longestLength; index++) {
      if (index < likedPrograms.length) {
        records.add(
          _WentToRecord(
            program: likedPrograms[index],
            reaction: ProgramReaction.like,
          ),
        );
      }
      if (index < dislikedPrograms.length) {
        records.add(
          _WentToRecord(
            program: dislikedPrograms[index],
            reaction: ProgramReaction.dislike,
          ),
        );
      }
    }
    return records;
  }

  Future<void> _openProgram(_WentToRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailScreen(
          program: record.program,
          entrySource: record.reaction == ProgramReaction.like
              ? 'went_to_like'
              : 'went_to_dislike',
        ),
      ),
    );
    if (mounted) await _loadRecords(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_hasLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }
    if (_errorMessage != null && _records.isEmpty) {
      return _WentToMessage(
        message: _errorMessage!,
        actionText: '다시 시도',
        onAction: () => _loadRecords(reset: true),
      );
    }
    if (_records.isEmpty) {
      return const _WentToMessage(message: '다녀온 기록이 없어요.');
    }

    return RefreshIndicator(
      color: AppColors.gray900,
      onRefresh: () => _loadRecords(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        itemCount: _records.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _records.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gray900),
              ),
            );
          }
          return _WentToRecordCard(
            record: _records[index],
            isLast: index == _records.length - 1,
            onTap: () => _openProgram(_records[index]),
          );
        },
      ),
    );
  }
}

class _WentToRecord {
  final ProgramModel program;
  final ProgramReaction reaction;

  const _WentToRecord({required this.program, required this.reaction});
}

class _WentToRecordCard extends StatelessWidget {
  final _WentToRecord record;
  final bool isLast;
  final VoidCallback onTap;

  const _WentToRecordCard({
    required this.record,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 40.w,
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.radius_8,
                      ),
                      child: SizedBox(
                        width: 40.w,
                        height: 53.h,
                        child: record.program.images.isEmpty
                            ? const ColoredBox(color: AppColors.gray200)
                            : record.program.images.first,
                      ),
                    ),
                  ),
                  if (!isLast) ...[
                    SizedBox(height: 20.h),
                    Expanded(
                      child: Container(width: 1.w, color: AppColors.lineStrong),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.radius_8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.program.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headline1.copyWith(
                              color: AppColors.gray900,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _ReactionLabel(reaction: record.reaction),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SvgPicture.asset(
                      'assets/icons/edit.svg',
                      width: 16.r,
                      height: 16.r,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gray400,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionLabel extends StatelessWidget {
  final ProgramReaction reaction;

  const _ReactionLabel({required this.reaction});

  @override
  Widget build(BuildContext context) {
    final isLiked = reaction == ProgramReaction.like;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20.r,
          height: 20.r,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gray900,
          ),
          child: SvgPicture.asset(
            isLiked
                ? 'assets/icons/thumb_up_filled.svg'
                : 'assets/icons/thumb_down_filled.svg',
            width: 10.r,
            height: 10.r,
            colorFilter: const ColorFilter.mode(
              AppColors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          isLiked ? '좋았어요' : '아쉬웠어요',
          style: AppTypography.caption1.copyWith(color: AppColors.gray900),
        ),
      ],
    );
  }
}

class _WentToMessage extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _WentToMessage({this.message = '', this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTypography.button2.copyWith(color: AppColors.gray400),
          ),
          if (actionText != null && onAction != null) ...[
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText!,
                style: AppTypography.button2.copyWith(color: AppColors.gray900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
