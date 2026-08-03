import 'dart:async';

import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/cards/curation_card.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/screens/home/components/my_niche_keyword_cta.dart';
import 'package:muntum/screens/home/search_screen.dart';
import 'package:muntum/screens/mypage/keyword_change_screen.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/services/analytics_service.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/keyword_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';
import 'package:muntum/utils/app_toast.dart';

class MyNicheScreen extends StatefulWidget {
  final bool isActive;

  const MyNicheScreen({super.key, required this.isActive});

  @override
  State<MyNicheScreen> createState() => _MyNicheScreenState();
}

class _MyNicheScreenState extends State<MyNicheScreen> {
  static const int _pageSize = 20;
  static const double _pageViewportFraction = 320 / 390;
  static const double _activeCardWidth = 310;
  static const double _activeCardHeight = 414;
  static const double _sideCardWidth = 290;
  static const double _sideCardHeight = 386.67;
  static const double _carouselHeight = 484;
  static const double _ctaOffset = 85;
  static const double _lastCardRevealOffset = 146;

  late final PageController _pageController;
  late Future<bool> _isLoggedInFuture;

  String? _selectedFilter;
  List<ProgramModel> _programs = const [];
  Set<String> _availableKeywords = const {};
  Set<String> _selectedKeywords = const {};
  int _currentProgramIndex = 0;
  int _totalPrograms = 0;
  int _nextPage = 0;
  int _programRequestId = 0;
  bool _hasNextPage = true;
  bool _isLoadingPrograms = false;
  double? _dragStartPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _pageViewportFraction);
    UserPreferenceStore.instance.addListener(_reloadProgramsByKeyword);
    _isLoggedInFuture = _initialize();
    if (widget.isActive) _logTabView();
  }

  @override
  void didUpdateWidget(covariant MyNicheScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _logTabView();
  }

  @override
  void dispose() {
    _pageController.dispose();
    UserPreferenceStore.instance.removeListener(_reloadProgramsByKeyword);
    super.dispose();
  }

  void _logTabView() {
    unawaited(AnalyticsService.instance.logHomeTabView('my_taste'));
  }

  bool get _hasSelectedAllKeywords =>
      _availableKeywords.isNotEmpty &&
      _selectedKeywords.containsAll(_availableKeywords);

  double get _visiblePage => _pageController.hasClients
      ? (_pageController.page ?? _currentProgramIndex.toDouble())
      : _currentProgramIndex.toDouble();

  Future<PageResponse<ProgramModel>> _loadProgramsPage(int page) async {
    final selectedFilterValue = _selectedFilterValue;
    final isLoggedIn = await _isLoggedIn();
    if (!isLoggedIn) {
      return ProgramService().fetchPrograms(
        chip: selectedFilterValue,
        page: page,
        size: _pageSize,
      );
    }
    return TasteService().fetchTastePrograms(
      chip: selectedFilterValue?.apiChip,
      page: page,
      size: _pageSize,
    );
  }

  Future<void> _loadPrograms({required bool reset}) async {
    if (!reset && (_isLoadingPrograms || !_hasNextPage)) return;
    final requestId = reset ? ++_programRequestId : _programRequestId;
    final requestedPage = reset ? 0 : _nextPage;
    setState(() {
      _isLoadingPrograms = true;
      if (reset) {
        _programs = const [];
        _currentProgramIndex = 0;
        _totalPrograms = 0;
        _nextPage = 0;
        _hasNextPage = true;
      }
    });
    try {
      final response = await _loadProgramsPage(requestedPage);
      if (!mounted || requestId != _programRequestId) return;
      final merged = <String, ProgramModel>{
        if (!reset)
          for (final program in _programs) program.id: program,
        for (final program in response.content) program.id: program,
      }.values.toList();
      setState(() {
        _programs = merged;
        _totalPrograms = response.totalElements > 0
            ? response.totalElements
            : merged.length;
        _nextPage = requestedPage + 1;
        _hasNextPage = response.hasMore;
      });
      if (reset) _jumpToFirstProgram();
    } on ApiException catch (error) {
      if (error.statusCode != 401 && error.code != 'A008') rethrow;
      await TokenStore.instance.clear();
      ProgramScrapStore.instance.clear(notify: false);
      UserPreferenceStore.instance.clear();
      if (!mounted) return;
      setState(() => _isLoggedInFuture = Future.value(false));
    } finally {
      if (mounted && requestId == _programRequestId) {
        setState(() => _isLoadingPrograms = false);
      }
    }
  }

  Future<bool> _isLoggedIn() async {
    final accessToken = TokenStore.instance.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) return true;
    final refreshToken = await TokenStore.instance.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      return await AuthService().refresh() != null;
    } catch (_) {
      await TokenStore.instance.clear();
      return false;
    }
  }

  Future<bool> _initialize() async {
    final isLoggedIn = await _isLoggedIn();
    if (!isLoggedIn) return false;
    await Future.wait([_loadPrograms(reset: true), _loadKeywordStatus()]);
    return TokenStore.instance.accessToken?.isNotEmpty == true;
  }

  Future<void> _loadKeywordStatus() async {
    try {
      final availableKeywordsFuture = KeywordService().fetchTaggedKeywords();
      final selectedKeywordsFuture = TasteService().fetchMyKeywords();
      final availableResult = await availableKeywordsFuture;
      final selectedResult = await selectedKeywordsFuture;
      final availableKeywords = availableResult
          .map((keyword) => keyword.name.trim())
          .where((keyword) => keyword.isNotEmpty)
          .toSet();
      final selectedKeywords = selectedResult.selectedKeywords
          .map((keyword) => keyword.name.trim())
          .where((keyword) => keyword.isNotEmpty)
          .toSet();
      UserPreferenceStore.instance.updateKeywords(selectedKeywords);
      if (!mounted) return;
      setState(() {
        _availableKeywords = availableKeywords;
        _selectedKeywords = selectedKeywords;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedKeywords = UserPreferenceStore.instance.selectedKeywords;
      });
    }
  }

  Filter? get _selectedFilterValue {
    return ProgramType.fromLabel(_selectedFilter)?.filter ??
        switch (_selectedFilter) {
          '무료' => Filter.free,
          '이번주' => Filter.thisWeek,
          '예약없이' => Filter.noReservation,
          _ => null,
        };
  }

  void _jumpToFirstProgram() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });
  }

  Future<void> _returnToFirstProgram() async {
    if (!_pageController.hasClients || _currentProgramIndex == 0) return;
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _onProgramPageChanged(int index) {
    setState(() => _currentProgramIndex = index);
    if (index >= _programs.length - 3) {
      _loadPrograms(reset: false);
    }
  }

  bool _onCarouselScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dragStartPage = _visiblePage;
    } else if (notification is ScrollEndNotification) {
      _dragStartPage = null;
    }
    return false;
  }

  void _reloadProgramsByKeyword() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoggedInFuture = _isLoggedIn();
      _selectedKeywords = UserPreferenceStore.instance.selectedKeywords;
    });
    _loadPrograms(reset: true);
  }

  Future<void> _openKeywordChangeScreen() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const KeywordChangeScreen(
          initiallyEditing: true,
          popAfterSave: true,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    await _loadKeywordStatus();
    if (!mounted) return;
    showAppToast(context, '키워드가 저장되었습니다.');
  }

  void _onFilterTap(String filter) {
    setState(() {
      _selectedFilter = (_selectedFilter == filter ? null : filter);
    });
    _loadPrograms(reset: true);
  }

  Widget _buildFilterChip(String text) {
    final isSelected = (_selectedFilter == text);

    return GestureDetector(
      onTap: () {
        _onFilterTap(text);
      },
      child: FilterChipWidget(
        text: text,
        textColor: isSelected ? AppColors.black : AppColors.gray400,
        backgroundColor: isSelected
            ? AppColors.primary400
            : const Color(0x0fffffff),
      ),
    );
  }

  Widget _buildProgramKeywords(ProgramModel program) {
    final selectedKeywords = UserPreferenceStore.instance.selectedKeywords
        .map((keyword) => keyword.trim())
        .toSet();
    final keywords = program.keywords.take(3).toList();
    if (keywords.isEmpty) return SizedBox(height: 58.h);

    return SizedBox(
      width: _activeCardWidth.w,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 6.w,
          runSpacing: 6.h,
          children: keywords.map((keyword) {
            final isMatched = selectedKeywords.contains(keyword.trim());
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: isMatched
                      ? AppColors.primary400.withValues(alpha: 50)
                      : AppColors.white.withAlpha(8),
                ),
              ),
              child: Text(
                keyword,
                style: AppTypography.caption3.copyWith(
                  color: isMatched ? AppColors.primary400 : AppColors.gray500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProgramProgress() {
    final total = _totalPrograms > 0 ? _totalPrograms : _programs.length;
    final current = total == 0 ? 0 : (_currentProgramIndex + 1).clamp(1, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 152.w,
          height: 2.h,
          child: ColoredBox(
            color: AppColors.gray800,
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final progress = total == 0
                    ? 0.0
                    : ((_visiblePage + 1) / total).clamp(0.0, 1.0);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(
                    color: AppColors.white,
                    child: SizedBox(width: 152.w * progress, height: 2.h),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          key: const ValueKey('my_niche_return_to_first'),
          behavior: HitTestBehavior.opaque,
          onTap: _returnToFirstProgram,
          child: Padding(
            padding: EdgeInsets.all(4.r),
            child: Icon(
              Icons.keyboard_double_arrow_left_rounded,
              size: 16.r,
              color: AppColors.gray500,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text.rich(
          TextSpan(
            text: '$current', // Default base text
            style: AppTypography.headline2.copyWith(color: AppColors.white),
            children: <TextSpan>[
              TextSpan(
                text: '/$total',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return PageHeader(
      title: SvgPicture.asset(
        'assets/icons/myniche_icon.svg',
        width: 43.w,
        height: 31.h,
      ),
      icon: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        ),
        child: SizedBox(
          width: 24.w,
          height: 24.h,
          child: SvgPicture.asset(
            'assets/icons/search.svg',
            width: 18.sp,
            height: 18.sp,
            colorFilter: const ColorFilter.mode(
              AppColors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary400),
          );
        }
        if (snapshot.data != true) return _buildGuestContent();
        return _buildAuthenticatedContent();
      },
    );
  }

  Widget _buildGuestContent() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/bottom_sheet/login_dark.svg',
              width: 140.w,
              height: 140.w,
            ),
            SizedBox(height: 32.h),
            Text(
              '당신의 취향을 발견해보세요',
              textAlign: TextAlign.center,
              style: AppTypography.title4.copyWith(color: AppColors.white),
            ),
            SizedBox(height: 8.h),
            Text(
              '취향 기반 추천을 위해 로그인이 필요해요.',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: 36.h),
            IntrinsicWidth(
              child: ButtonSolid(
                padding: EdgeInsets.fromLTRB(20.w, 11.h, 20.w, 10.h),
                text: '로그인하기',
                textColor: AppColors.gray900,
                boxColor: AppColors.primary400,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const InitialScreen(showBackButton: true),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedContent() {
    return Column(
      children: [
        FilterList(
          verticalPadding: 10,
          listOfChip: [
            _buildFilterChip('무료'),
            _buildFilterChip('이번주'),
            _buildFilterChip('예약없이'),
            ...ProgramType.values.map((type) => _buildFilterChip(type.label)),
          ],
        ),
        Expanded(child: _buildProgramArea()),
      ],
    );
  }

  Widget _buildProgramArea() {
    if (_isLoadingPrograms && _programs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary400),
      );
    }
    if (_programs.isEmpty) return _buildEmptyPrograms();

    return Column(
      children: [
        SizedBox(height: 12.h),
        SizedBox(height: _carouselHeight.h, child: _buildCarousel()),
        SizedBox(height: 20.h),
        _buildProgramProgress(),
        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildEmptyPrograms() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: 120.h),
        Center(
          child: Text(
            '조건에 맞는 프로그램이 없어요.',
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
        ),
        if (!_hasSelectedAllKeywords)
          Padding(
            padding: EdgeInsets.only(top: 64.h, bottom: 80.h),
            child: MyNicheKeywordCta(onTap: _openKeywordChangeScreen),
          ),
      ],
    );
  }

  Widget _buildCarousel() {
    final showKeywordCta = !_hasSelectedAllKeywords && !_hasNextPage;

    return NotificationListener<ScrollNotification>(
      onNotification: _onCarouselScroll,
      child: PageView.builder(
        controller: _pageController,
        padEnds: true,
        physics: _CarouselPagePhysics(dragStartPage: () => _dragStartPage),
        onPageChanged: _onProgramPageChanged,
        itemCount: _programs.length + (showKeywordCta ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _programs.length) {
            return Transform.translate(
              offset: Offset(_ctaOffset.w, 0),
              child: MyNicheKeywordCta(onTap: _openKeywordChangeScreen),
            );
          }
          return _buildProgramPage(
            program: _programs[index],
            index: index,
            showKeywordCta: showKeywordCta,
          );
        },
      ),
    );
  }

  Widget _buildProgramPage({
    required ProgramModel program,
    required int index,
    required bool showKeywordCta,
  }) {
    final keywords = RepaintBoundary(child: _buildProgramKeywords(program));

    return AnimatedBuilder(
      animation: _pageController,
      child: RepaintBoundary(
        child: CurationCard(program: program, entrySource: 'my_taste'),
      ),
      builder: (context, card) {
        final distance = (_visiblePage - index).abs().clamp(0.0, 1.0);
        final scaleX = 1 - (1 - _sideCardWidth / _activeCardWidth) * distance;
        final scaleY = 1 - (1 - _sideCardHeight / _activeCardHeight) * distance;
        final isLastProgram = index == _programs.length - 1;
        final ctaReveal = showKeywordCta && isLastProgram
            ? (_visiblePage - index).clamp(0.0, 1.0)
            : 0.0;

        return Transform.translate(
          offset: Offset(_lastCardRevealOffset.w * ctaReveal, 0),
          child: Column(
            children: [
              SizedBox(
                width: _activeCardWidth.w,
                height: _activeCardHeight.h,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                  child: card,
                ),
              ),
              SizedBox(height: 16.h),
              keywords,
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: AppColors.backgroundDark,
        child: Column(
          children: [
            SizedBox(height: 50.h),
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}

class _CarouselPagePhysics extends PageScrollPhysics {
  final double? Function() dragStartPage;

  const _CarouselPagePhysics({required this.dragStartPage, super.parent});

  @override
  _CarouselPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _CarouselPagePhysics(
      dragStartPage: dragStartPage,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final startPage = dragStartPage();
    if (startPage == null || position is! PageMetrics) {
      return super.createBallisticSimulation(position, velocity);
    }

    final currentPage = position.page ?? startPage;
    final pageDelta = currentPage - startPage;
    if (pageDelta.abs() < 0.08) {
      return super.createBallisticSimulation(position, velocity);
    }

    final lastPage =
        position.maxScrollExtent /
        (position.viewportDimension * position.viewportFraction);
    final targetPage = (startPage.round() + pageDelta.sign)
        .clamp(0, lastPage.round())
        .toDouble();
    final targetPixels =
        targetPage * position.viewportDimension * position.viewportFraction;

    if (targetPixels == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}
