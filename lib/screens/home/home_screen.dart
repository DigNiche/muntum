import 'dart:async';

import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/banner_carousel.dart';
import 'package:muntum/components/cards/curation_card.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/screens/home/components/vertical_card_carousel.dart';
import 'package:muntum/screens/home/search_screen.dart';
import 'package:muntum/screens/home/see_more_screen.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/analytics_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/user_preference_store.dart';

enum ScreenTypes { myNiche, entire }

class HomeScreen extends StatefulWidget {
  final ScreenTypes initialScreenType;
  final ValueChanged<ScreenTypes>? onScreenTypeChanged;

  const HomeScreen({
    super.key,
    this.initialScreenType = ScreenTypes.myNiche,
    this.onScreenTypeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScreenTypes screenType;

  @override
  void initState() {
    super.initState();
    screenType = widget.initialScreenType;
    unawaited(
      AnalyticsService.instance.logHomeTabView(
        screenType == ScreenTypes.myNiche ? 'my_taste' : 'all',
      ),
    );
  }

  void _selectScreen(ScreenTypes nextScreen) {
    if (screenType == nextScreen) return;
    setState(() => screenType = nextScreen);
    widget.onScreenTypeChanged?.call(nextScreen);
    unawaited(
      AnalyticsService.instance.logHomeTabView(
        nextScreen == ScreenTypes.myNiche ? 'my_taste' : 'all',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMyNiche = screenType == ScreenTypes.myNiche;

    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      tween: ColorTween(
        end: isMyNiche ? AppColors.backgroundDark : AppColors.white,
      ),
      builder: (context, animatedBackgroundColor, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isMyNiche
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isMyNiche ? Brightness.dark : Brightness.light,
          ),
          child: ColoredBox(
            color: animatedBackgroundColor ?? AppColors.white,
            child: Column(
              children: [
                SizedBox(height: 50.h),
                PageHeader(
                  firstText: '내취향',
                  firstTextColor: isMyNiche
                      ? AppColors.white
                      : AppColors.gray300,
                  onFirstTextTap: () {
                    _selectScreen(ScreenTypes.myNiche);
                  },
                  secondText: '전체',
                  secondTextColor: isMyNiche
                      ? AppColors.gray600
                      : AppColors.black,
                  onSecondTextTap: () {
                    _selectScreen(ScreenTypes.entire);
                  },
                  icon: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: SvgPicture.asset(
                        'assets/icons/search.svg',
                        width: 18.sp,
                        height: 18.sp,
                        colorFilter: ColorFilter.mode(
                          isMyNiche ? AppColors.white : AppColors.gray600,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  showIndicator: isMyNiche,
                ),
                Expanded(
                  child: isMyNiche ? const MyNichePage() : const EntirePage(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MyNichePage extends StatefulWidget {
  const MyNichePage({super.key});

  @override
  State<MyNichePage> createState() => _MyNichePageState();
}

class _MyNichePageState extends State<MyNichePage> {
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  String? selectedFilter;
  bool _showScrollToTopButton = false;
  List<ProgramModel> _programs = const [];
  int _nextPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingPrograms = false;
  int _programRequestId = 0;
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    UserPreferenceStore.instance.addListener(_reloadProgramsByKeyword);
    _isLoggedInFuture = _isLoggedIn();
    _loadPrograms(reset: true);
  }

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
        _nextPage = requestedPage + 1;
        _hasNextPage = response.hasMore;
      });
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
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Filter? get _selectedFilterValue {
    return ProgramType.fromLabel(selectedFilter)?.filter ??
        switch (selectedFilter) {
          '무료' => Filter.free,
          '이번주' => Filter.thisWeek,
          '예약없이' => Filter.noReservation,
          _ => null,
        };
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 200.h;
    if (shouldShow != _showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = shouldShow;
      });
    }
    if (_scrollController.position.extentAfter < 500.h) {
      _loadPrograms(reset: false);
    }
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) {
      return;
    }
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _reloadProgramsByKeyword() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoggedInFuture = _isLoggedIn();
    });
    _loadPrograms(reset: true);
  }

  void _onFilterTap(String filter) {
    setState(() {
      selectedFilter = (selectedFilter == filter ? null : filter);
      _showScrollToTopButton = false;
    });
    _loadPrograms(reset: true);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    UserPreferenceStore.instance.removeListener(_reloadProgramsByKeyword);
    super.dispose();
  }

  Widget _buildFilterChip(String text) {
    final isSelected = (selectedFilter == text);

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, loginSnapshot) {
        final isLoggedIn = loginSnapshot.data ?? false;
        if (loginSnapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gray900),
          );
        }
        if (!isLoggedIn) {
          return const _GuestMyNicheView();
        }
        return Column(
          children: [
            FilterList(
              listOfChip: [
                _buildFilterChip('무료'),
                _buildFilterChip('이번주'),
                _buildFilterChip('예약없이'),
                ...ProgramType.values.map(
                  (type) => _buildFilterChip(type.label),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Builder(
                      builder: (context) {
                        final programs = _programs;
                        if (_isLoadingPrograms && programs.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gray900,
                            ),
                          );
                        }
                        if (programs.isEmpty) {
                          return Center(
                            child: Text(
                              '조건에 맞는 프로그램이 없어요.',
                              style: AppTypography.body2.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 40.h),
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount:
                              programs.length +
                              (_isLoadingPrograms && _hasNextPage ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == programs.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              );
                            }
                            final isLast = index == programs.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLast ? 40.h : 0,
                              ),
                              child: CurationCard(
                                program: programs[index],
                                entrySource: 'my_taste',
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_showScrollToTopButton)
                    Positioned(
                      right: 20.w,
                      bottom: 20.h,
                      child: GestureDetector(
                        key: const ValueKey('my_niche_scroll_to_top'),
                        onTap: _scrollToTop,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                          width: 48.r,
                          height: 48.r,
                          child: SvgPicture.asset(
                            'assets/icons/arrow_up_2.svg',
                            width: 24.r,
                            height: 24.r,
                            fit: BoxFit.scaleDown,
                            colorFilter: const ColorFilter.mode(
                              AppColors.gray900,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuestMyNicheView extends StatelessWidget {
  const _GuestMyNicheView();

  @override
  Widget build(BuildContext context) {
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(showBackButton: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntirePage extends StatefulWidget {
  const EntirePage({super.key});

  @override
  State<EntirePage> createState() => _EntirePageState();
}

class _EntirePageState extends State<EntirePage> {
  late Future<_EntirePagePrograms> _programsFuture;

  @override
  void initState() {
    super.initState();
    _programsFuture = _loadPrograms();
  }

  Future<_EntirePagePrograms> _loadPrograms() async {
    final service = ProgramService();
    final results = await Future.wait([
      service.fetchPrograms(
        sort: ProgramSort.startDate,
        order: SortOrder.desc,
        size: 5,
      ),
      service.fetchHotKeywordPrograms(size: 8),
      service.fetchHotPrograms(size: 8),
      service.fetchClosingSoon(size: 8),
    ]);
    return _EntirePagePrograms(
      banners: results[0].content,
      all: results[1].content,
      hot: results[2].content,
      closingSoon: results[3].content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EntirePagePrograms>(
      future: _programsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gray900),
          );
        }
        if (data == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 10.h),
              BannerCarousel(programs: data.banners, entrySource: 'all_banner'),
              SizedBox(height: 48.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader1(
                    text: '모아보기',
                    buttonName: '전체보기',
                    onButtonTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SeeMoreScreen(
                            type: SeeMoreType.allPrograms,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  VerticalCardCarousel(
                    programs: data.all,
                    entrySource: 'all_collection',
                  ),
                  SectionHeader1(
                    text: '지금 주목받는',
                    buttonName: '',
                    onButtonTap: () {},
                  ),
                  SizedBox(height: 8.h),
                  VerticalCardCarousel(
                    programs: data.hot,
                    entrySource: 'all_hot',
                  ),
                  SectionHeader1(
                    text: '이번달에 끝나는',
                    buttonName: '전체보기',
                    onButtonTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SeeMoreScreen(
                            type: SeeMoreType.endingThisMonth,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  VerticalCardCarousel(
                    programs: data.closingSoon,
                    entrySource: 'all_closing_soon',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EntirePagePrograms {
  final List<ProgramModel> banners;
  final List<ProgramModel> all;
  final List<ProgramModel> hot;
  final List<ProgramModel> closingSoon;

  const _EntirePagePrograms({
    required this.banners,
    required this.all,
    required this.hot,
    required this.closingSoon,
  });
}
