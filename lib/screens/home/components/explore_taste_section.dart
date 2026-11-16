import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/components/program_curator_badge.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/screens/home/see_more_screen.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/user_preference_store.dart';

/// Shows a swipeable preview of the existing taste recommendations.
class ExploreTasteSection extends StatefulWidget {
  /// Creates the recommendation section with an optional alternate data source.
  const ExploreTasteSection({super.key, this.loadPrograms});

  /// Overrides the recommendation request, for example in widget tests.
  final Future<PageResponse<ProgramModel>> Function()? loadPrograms;

  @override
  State<ExploreTasteSection> createState() => _ExploreTasteSectionState();
}

class _ExploreTasteSectionState extends State<ExploreTasteSection>
    with AutomaticKeepAliveClientMixin {
  static const _previewLimit = 8;
  late Future<PageResponse<ProgramModel>> _programs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _programs = _load();
    UserPreferenceStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    UserPreferenceStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final request = _load();
    setState(() {
      _programs = request;
    });
  }

  void _openAllPrograms() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const SeeMoreScreen(type: SeeMoreType.myTaste),
      ),
    );
  }

  Future<PageResponse<ProgramModel>> _load() async {
    final override = widget.loadPrograms;
    if (override != null) return override();
    if (AuthState.instance.isLoggedIn) {
      try {
        return await TasteService().fetchTastePrograms(size: _previewLimit);
      } on ApiException catch (error) {
        if (error.statusCode != 401 && error.code != 'A008') rethrow;
      }
    }
    return ProgramService().fetchPrograms(size: _previewLimit);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader1(
            text: '내 취향 모아보기',
            buttonName: '전체보기',
            onButtonTap: _openAllPrograms,
            horizontalPadding: 0,
            verticalPadding: 0,
          ),
          SizedBox(height: 16.h),
          FutureBuilder<PageResponse<ProgramModel>>(
            future: _programs,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AspectRatio(
                      aspectRatio: 350 / 430,
                      child: Semantics(
                        label: '추천 프로그램 불러오는 중',
                        child: SkeletonBlock(height: 430.h, radius: 12.r),
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: _refresh,
                  child: const Text('추천을 불러오지 못했어요. 다시 시도'),
                );
              }
              final result = snapshot.data;
              if (result == null || result.content.isEmpty) {
                return Text(
                  '아직 추천 프로그램이 없어요.',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray600,
                  ),
                );
              }
              return _TastePager(
                key: ObjectKey(result),
                programs: result.content.take(_previewLimit).toList(),
                total: math.max(result.totalElements, result.content.length),
                onSeeAll: _openAllPrograms,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TastePager extends StatefulWidget {
  const _TastePager({
    super.key,
    required this.programs,
    required this.total,
    required this.onSeeAll,
  });

  final List<ProgramModel> programs;
  final int total;
  final VoidCallback onSeeAll;

  @override
  State<_TastePager> createState() => _TastePagerState();
}

class _TastePagerState extends State<_TastePager> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _posterAt(int index) => widget
      .programs[math.min(index, widget.programs.length - 1)]
      .imageUrls
      .firstOrNull;

  Widget _buildBackground(BuildContext context, Widget? child) {
    final position = (_controller.hasClients ? _controller.page ?? 0.0 : 0.0)
        .clamp(0.0, widget.programs.length.toDouble());
    final current = _posterAt(position.floor());
    final next = _posterAt(position.ceil());
    final fraction = position - position.floor();
    if (current == next || MediaQuery.disableAnimationsOf(context)) {
      return _TasteBackdrop(url: fraction < 0.5 ? current : next);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _TasteBackdrop(url: current),
        Opacity(
          opacity: fraction,
          child: _TasteBackdrop(url: next),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AspectRatio(
          aspectRatio: 350 / 430,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Follow the swipe without moving the background or rounding each page.
                AnimatedBuilder(
                  animation: _controller,
                  builder: _buildBackground,
                ),
                ColoredBox(color: AppColors.black.withValues(alpha: 0.25)),
                PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) => setState(() {
                    _currentPage = index;
                  }),
                  itemCount: widget.programs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == widget.programs.length) {
                      return Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onSeeAll,
                          child: _TasteSummary(total: widget.total),
                        ),
                      );
                    }
                    final program = widget.programs[index];
                    return _TasteCard(
                      program: program,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ProgramDetailScreen(
                            program: program,
                            entrySource: 'my_taste',
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (_currentPage < widget.programs.length)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 32.r,
                    child: IgnorePointer(
                      child: Text.rich(
                        TextSpan(
                          text: '${_currentPage + 1}',
                          children: [
                            TextSpan(
                              text: '/${widget.programs.length}',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.30),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TasteBackdrop extends StatelessWidget {
  const _TasteBackdrop({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: ColoredBox(
        color: AppColors.gray800,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 25,
            sigmaY: 25,
            tileMode: TileMode.clamp,
          ),
          child: _Poster(url: url),
        ),
      ),
    ),
  );
}

class _TasteCard extends StatelessWidget {
  const _TasteCard({required this.program, required this.onTap});

  final ProgramModel program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 56.h, 16.w, 52.h),
      child: Column(
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 160.r),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _Poster(
                          url: program.imageUrls.firstOrNull,
                          fit: BoxFit.contain,
                        ),
                        if (program.hasCurator)
                          Positioned(
                            bottom: 4.r,
                            left: 4.r,
                            child: ProgramCuratorBadge(size: 24.r),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.title4.copyWith(color: AppColors.white),
                ),
                SizedBox(height: 8.r),
                Text(
                  program.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.white,
                  ),
                ),
                Text(
                  program.cardDateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TasteSummary extends StatelessWidget {
  const _TasteSummary({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: const BoxDecoration(
            color: AppColors.black,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/curator_note_next_arrow.svg',
            width: 16.r,
            height: 16.r,
            colorFilter: const ColorFilter.mode(
              AppColors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          '내 취향 프로그램 $total개 전체보기',
          textAlign: TextAlign.center,
          style: AppTypography.headline1.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(color: AppColors.gray800);
    final source = url;
    if (source == null || source.isEmpty) return fallback;
    return Image.network(source, fit: fit, errorBuilder: (_, _, _) => fallback);
  }
}
