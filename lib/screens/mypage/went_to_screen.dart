import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/services/program_reaction_service.dart';

class WentToScreen extends StatefulWidget {
  const WentToScreen({super.key});

  @override
  State<WentToScreen> createState() => _WentToScreenState();
}

class _WentToScreenState extends State<WentToScreen> {
  static const _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final Map<ProgramReaction, _ReactionProgramsState> _states = {
    ProgramReaction.like: _ReactionProgramsState(),
    ProgramReaction.dislike: _ReactionProgramsState(),
  };
  ProgramReaction _selectedReaction = ProgramReaction.like;

  _ReactionProgramsState get _currentState => _states[_selectedReaction]!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageIfNeeded);
    _loadPrograms(reaction: _selectedReaction, reset: true);
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
    _loadPrograms(reaction: _selectedReaction, reset: false);
  }

  Future<void> _loadPrograms({
    required ProgramReaction reaction,
    required bool reset,
  }) async {
    final state = _states[reaction]!;
    if (state.isLoading || (!reset && !state.hasNextPage)) return;
    final requestId = reset ? ++state.requestId : state.requestId;
    final requestedPage = reset ? 0 : state.nextPage;

    setState(() {
      state.isLoading = true;
      state.errorMessage = null;
      if (reset) {
        state.programs.clear();
        state.nextPage = 0;
        state.hasNextPage = true;
      }
    });

    try {
      final response = await ProgramReactionService().fetchMyPrograms(
        reaction: reaction,
        page: requestedPage,
        size: _pageSize,
      );
      if (!mounted || requestId != state.requestId) return;
      final programs = <String, ProgramModel>{
        if (!reset)
          for (final program in state.programs) program.id: program,
        for (final program in response.content) program.id: program,
      }.values.toList();
      setState(() {
        state.programs
          ..clear()
          ..addAll(programs);
        state.nextPage = requestedPage + 1;
        state.hasNextPage = response.hasMore;
        state.hasLoaded = true;
      });
    } catch (_) {
      if (!mounted || requestId != state.requestId) return;
      setState(() {
        state.errorMessage = '기록을 불러오지 못했어요.';
        state.hasLoaded = true;
      });
    } finally {
      if (mounted && requestId == state.requestId) {
        setState(() => state.isLoading = false);
      }
    }
  }

  void _selectReaction(ProgramReaction reaction) {
    if (_selectedReaction == reaction) return;
    setState(() => _selectedReaction = reaction);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    final state = _states[reaction]!;
    if (!state.hasLoaded) {
      _loadPrograms(reaction: reaction, reset: true);
    }
  }

  Future<void> _openProgram(ProgramModel program) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailScreen(
          program: program,
          entrySource: _selectedReaction == ProgramReaction.like
              ? 'went_to_like'
              : 'went_to_dislike',
        ),
      ),
    );
    if (!mounted) return;
    for (final state in _states.values) {
      state.hasLoaded = false;
    }
    await _loadPrograms(reaction: _selectedReaction, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentState;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.none,
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 26.h),
            child: Text(
              '다녀온\n프로그램 기록',
              style: AppTypography.title3.copyWith(color: AppColors.gray900),
            ),
          ),
          _WentToTabs(
            selectedReaction: _selectedReaction,
            onLikedTap: () => _selectReaction(ProgramReaction.like),
            onDislikedTap: () => _selectReaction(ProgramReaction.dislike),
          ),
          Expanded(child: _buildPrograms(state)),
        ],
      ),
    );
  }

  Widget _buildPrograms(_ReactionProgramsState state) {
    if (state.isLoading && state.programs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }
    if (state.errorMessage != null && state.programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage!,
              style: AppTypography.button2.copyWith(color: AppColors.gray400),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () =>
                  _loadPrograms(reaction: _selectedReaction, reset: true),
              child: Text(
                '다시 시도',
                style: AppTypography.button2.copyWith(color: AppColors.gray900),
              ),
            ),
          ],
        ),
      );
    }
    if (state.programs.isEmpty) {
      return Center(
        child: Text(
          '기록한 프로그램이 없어요.',
          style: AppTypography.button2.copyWith(color: AppColors.gray400),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.gray900,
      onRefresh: () => _loadPrograms(reaction: _selectedReaction, reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
        itemCount: state.programs.length + (state.isLoading ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: 16.h),
        itemBuilder: (context, index) {
          if (index == state.programs.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gray900),
              ),
            );
          }
          final program = state.programs[index];
          return HorizontalCard(
            program: program,
            entrySource: _selectedReaction == ProgramReaction.like
                ? 'went_to_like'
                : 'went_to_dislike',
            onTap: () => _openProgram(program),
          );
        },
      ),
    );
  }
}

class _ReactionProgramsState {
  final List<ProgramModel> programs = [];
  int nextPage = 0;
  int requestId = 0;
  bool hasNextPage = true;
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;
}

class _WentToTabs extends StatelessWidget {
  final ProgramReaction selectedReaction;
  final VoidCallback onLikedTap;
  final VoidCallback onDislikedTap;

  const _WentToTabs({
    required this.selectedReaction,
    required this.onLikedTap,
    required this.onDislikedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lineNormal)),
      ),
      child: Row(
        children: [
          _WentToTab(
            text: '좋았어요',
            isSelected: selectedReaction == ProgramReaction.like,
            onTap: onLikedTap,
          ),
          _WentToTab(
            text: '아쉬웠어요',
            isSelected: selectedReaction == ProgramReaction.dislike,
            onTap: onDislikedTap,
          ),
        ],
      ),
    );
  }
}

class _WentToTab extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _WentToTab({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom: BorderSide(color: AppColors.gray900, width: 2.h),
                  )
                : null,
          ),
          child: Text(
            text,
            style: AppTypography.button2.copyWith(
              color: isSelected ? AppColors.gray900 : AppColors.gray500,
            ),
          ),
        ),
      ),
    );
  }
}
