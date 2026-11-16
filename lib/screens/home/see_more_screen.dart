import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/components/scroll_to_top_button.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/screens/home/components/program_type_tabs.dart';
import 'package:muntum/screens/mypage/audience/keyword_change_screen.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/user_preference_store.dart';

enum SeeMoreType { allPrograms, endingThisMonth, myTaste }

class SeeMoreScreen extends StatefulWidget {
  final SeeMoreType type;
  final Filter? initialFilter;

  /// Overrides the service used by the personalized list and its keywords.
  final TasteService? tasteService;

  const SeeMoreScreen({
    super.key,
    required this.type,
    this.initialFilter,
    this.tasteService,
  });

  String get title => switch (type) {
    SeeMoreType.allPrograms => '유형별 모아보기',
    SeeMoreType.endingThisMonth => '이번달에 끝나는',
    SeeMoreType.myTaste => '내 취향 모아보기',
  };

  @override
  State<SeeMoreScreen> createState() => _SeeMoreScreenState();
}

class _SeeMoreScreenState extends State<SeeMoreScreen> {
  static const int _pageSize = 20;

  Filter? _selectedFilter;
  Filter? _selectedDetailFilter;
  final ScrollController _scrollController = ScrollController();
  List<ProgramModel> _programs = const [];
  int _nextPage = 0;
  int _totalElements = 0;
  bool _hasNextPage = true;
  bool _isLoading = false;
  bool _showScrollToTopButton = false;
  int _requestId = 0;
  bool _loadFailed = false;
  bool _keywordsExpanded = false;
  bool _wasLoggedIn = false;

  bool get _isTaste => widget.type == SeeMoreType.myTaste;
  late final _tasteService = widget.tasteService ?? TasteService();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _scrollController.addListener(_handleScroll);
    if (_isTaste) {
      UserPreferenceStore.instance.addListener(_reloadTaste);
      AuthState.instance.addListener(_handleTasteAuth);
      _wasLoggedIn = AuthState.instance.isLoggedIn;
      _loadTasteKeywords();
    }
    _loadPrograms(reset: true);
  }

  void _handleTasteAuth() {
    final loggedIn = AuthState.instance.isLoggedIn;
    if (loggedIn == _wasLoggedIn) return;
    _wasLoggedIn = loggedIn;
    _reloadTaste();
    if (loggedIn) _loadTasteKeywords();
  }

  Future<void> _loadTasteKeywords() async {
    if (!AuthState.instance.isLoggedIn) return;
    try {
      final result = await _tasteService.fetchMyKeywords();
      if (!mounted || !AuthState.instance.isLoggedIn) return;
      UserPreferenceStore.instance.updateKeywords(
        result.selectedKeywords.map((keyword) => keyword.name),
      );
    } on Exception {
      // Keep the last known keywords if the request fails.
    }
  }

  void _reloadTaste() {
    _loadPrograms(reset: true);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _openKeywordEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthState.instance.isLoggedIn
            ? const KeywordChangeScreen(
                initiallyEditing: true,
                popAfterSave: true,
              )
            : const InitialScreen(showBackButton: true),
      ),
    );
  }

  Future<void> _loadPrograms({required bool reset}) async {
    if (!reset && (_isLoading || !_hasNextPage)) return;
    final requestId = reset ? ++_requestId : _requestId;
    final requestedPage = reset ? 0 : _nextPage;
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      if (reset) {
        _programs = const [];
        _nextPage = 0;
        _totalElements = 0;
        _hasNextPage = true;
      }
    });
    final service = ProgramService();
    try {
      final page = _isTaste
          ? await _fetchTastePage(requestedPage)
          : widget.type == SeeMoreType.endingThisMonth
          ? await service.fetchClosingSoon(
              chip: _selectedFilter,
              page: requestedPage,
              size: _pageSize,
            )
          : await service.fetchHotKeywordPrograms(
              programType: _selectedFilter == null
                  ? null
                  : ProgramType.fromFilter(_selectedFilter!),
              chip: _selectedDetailFilter,
              page: requestedPage,
              size: _pageSize,
            );
      if (!mounted || requestId != _requestId) return;
      final merged = <String, ProgramModel>{
        if (!reset)
          for (final program in _programs) program.id: program,
        for (final program in page.content) program.id: program,
      }.values.toList();
      setState(() {
        _programs = merged;
        _nextPage = requestedPage + 1;
        _totalElements = page.totalElements;
        _hasNextPage = page.hasMore;
      });
    } on Exception {
      if (mounted && requestId == _requestId) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<PageResponse<ProgramModel>> _fetchTastePage(int page) async {
    final filter = _selectedFilter;
    if (AuthState.instance.isLoggedIn) {
      try {
        return await _tasteService.fetchTastePrograms(
          chip: filter?.apiChip,
          page: page,
          size: _pageSize,
        );
      } on ApiException catch (error) {
        if (error.statusCode != 401 && error.code != 'A008') rethrow;
      }
    }
    return ProgramService().fetchPrograms(
      chip: filter,
      page: page,
      size: _pageSize,
    );
  }

  void _handleScroll() {
    final shouldShowScrollToTopButton = _scrollController.offset > 200.h;
    if (shouldShowScrollToTopButton != _showScrollToTopButton) {
      setState(() => _showScrollToTopButton = shouldShowScrollToTopButton);
    }
    if (!_loadFailed && _scrollController.position.extentAfter < 400.h) {
      _loadPrograms(reset: false);
    }
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectFilter(Filter? filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _showScrollToTopButton = false;
    });
    _loadPrograms(reset: true);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _selectDetailFilter(Filter? filter) {
    if (_selectedDetailFilter == filter) return;
    setState(() {
      _selectedDetailFilter = filter;
      _showScrollToTopButton = false;
    });
    _loadPrograms(reset: true);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    if (_isTaste) {
      UserPreferenceStore.instance.removeListener(_reloadTaste);
      AuthState.instance.removeListener(_handleTasteAuth);
    }
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTypeTabs = widget.type == SeeMoreType.allPrograms;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50.h),
                AppBarWidget(
                  centerType: AppBarCenterType.text,
                  leadingIcon: 'arrow_left.svg',
                  onLeadingTap: () => Navigator.pop(context),
                  center: widget.title,
                ),
                if (showTypeTabs)
                  ProgramTypeTabs(
                    selectedFilter: _selectedFilter,
                    onSelected: _selectFilter,
                  ),
                if (_isTaste) _buildTasteFilters(),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final programs = _programs;
                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              20.w,
                              showTypeTabs
                                  ? 12.h
                                  : _isTaste
                                  ? 0
                                  : 14.h,
                              20.w,
                              programs.isEmpty ? 0 : 24.h,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                if (showTypeTabs) ...[
                                  ProgramDetailFilterChips(
                                    selectedFilter: _selectedDetailFilter,
                                    onSelected: _selectDetailFilter,
                                  ),
                                  SizedBox(height: 12.h),
                                ],
                                if (_isTaste) _buildTasteKeywords(),
                                if (!showTypeTabs && !_isTaste)
                                  Text(
                                    '프로그램 ${_totalElements > 0 ? _totalElements : programs.length}개',
                                    style: AppTypography.headline2.copyWith(
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                SizedBox(
                                  height: _isTaste
                                      ? 20.h
                                      : showTypeTabs
                                      ? 12.h
                                      : 16.h,
                                ),
                                for (
                                  var index = 0;
                                  index < programs.length;
                                  index++
                                ) ...[
                                  HorizontalCard(
                                    program: programs[index],
                                    highlightedKeywords: _isTaste
                                        ? UserPreferenceStore
                                              .instance
                                              .selectedKeywords
                                        : const {},
                                    entrySource: switch (widget.type) {
                                      SeeMoreType.myTaste => 'my_taste',
                                      SeeMoreType.allPrograms =>
                                        'all_collection',
                                      SeeMoreType.endingThisMonth =>
                                        'all_closing_soon',
                                    },
                                  ),
                                  if (index != programs.length - 1)
                                    SizedBox(height: _isTaste ? 20.h : 16.h),
                                ],
                                if (_loadFailed && programs.isNotEmpty)
                                  TextButton(
                                    onPressed: () =>
                                        _loadPrograms(reset: false),
                                    child: const Text('다시 시도'),
                                  ),
                                if (_isLoading && programs.isNotEmpty) ...[
                                  SizedBox(height: 16.h),
                                  const ProgramListSkeleton(count: 1),
                                ],
                                if (_isLoading && programs.isEmpty)
                                  const ProgramListSkeleton(),
                              ]),
                            ),
                          ),
                          if (programs.isEmpty && !_isLoading)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: _loadFailed
                                    ? TextButton(
                                        onPressed: () =>
                                            _loadPrograms(reset: true),
                                        child: const Text('다시 시도'),
                                      )
                                    : Text(
                                        '조건에 맞는 프로그램이 없어요.',
                                        style: AppTypography.body2.copyWith(
                                          color: AppColors.gray500,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_showScrollToTopButton)
              Positioned(
                right: 20.w,
                bottom: 24.h,
                child: ScrollToTopButton(onTap: _scrollToTop),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasteFilters() {
    final filters = {
      Filter.free: '무료',
      Filter.thisWeek: '이번주',
      Filter.noReservation: '예약없이',
      for (final type in ProgramType.values) type.filter: type.label,
    };
    return FilterList(
      verticalPadding: 20,
      listOfChip: [
        for (final entry in filters.entries)
          GestureDetector(
            onTap: () =>
                _selectFilter(_selectedFilter == entry.key ? null : entry.key),
            child: FilterChipWidget(
              text: entry.value,
              textColor: _selectedFilter == entry.key
                  ? AppColors.white
                  : AppColors.gray800,
              backgroundColor: _selectedFilter == entry.key
                  ? AppColors.gray900
                  : AppColors.white,
              outlineColor: AppColors.lineStrong,
            ),
          ),
      ],
    );
  }

  Widget _buildTasteKeywords() {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    const curve = Cubic(0.23, 1, 0.32, 1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundNormal,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _keywordsExpanded,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  setState(() => _keywordsExpanded = !_keywordsExpanded),
              child: AnimatedPadding(
                duration: duration,
                curve: curve,
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  14.h,
                  16.w,
                  _keywordsExpanded ? 4.h : 20.h,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/heart_filled.svg',
                      width: 20.r,
                      height: 20.r,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        '내 취향 키워드',
                        style: AppTypography.headline2.copyWith(
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _keywordsExpanded ? 0.5 : 0,
                      duration: duration,
                      curve: curve,
                      child: SvgPicture.asset(
                        'assets/icons/arrow_down.svg',
                        width: 16.r,
                        height: 16.r,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _keywordsExpanded ? 1 : 0),
            duration: duration,
            curve: curve,
            builder: (context, progress, child) {
              if (progress == 0) return const SizedBox.shrink();
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: progress,
                  child: IgnorePointer(
                    ignoring: !_keywordsExpanded || progress < 1,
                    child: ExcludeSemantics(
                      excluding: !_keywordsExpanded || progress < 1,
                      child: Opacity(opacity: progress, child: child),
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '선택할수록 내 취향에 꼭 맞는 피드가 완성돼요.',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      for (final keyword
                          in UserPreferenceStore.instance.selectedKeywords)
                        FilterChipWidget(
                          text: keyword,
                          textColor: AppColors.gray800,
                          backgroundColor: AppColors.white,
                        ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  ButtonSolid(
                    text: '더 찾아보기',
                    textStyle: AppTypography.button2,
                    textColor: AppColors.white,
                    boxColor: AppColors.black,
                    onTap: _openKeywordEditor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
