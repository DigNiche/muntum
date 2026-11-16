import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/utils/program_card_layout.dart';
import 'package:muntum/screens/home/components/banner_carousel.dart';
import 'package:muntum/screens/home/components/explore_taste_section.dart';
import 'package:muntum/screens/home/components/program_type_tabs.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/screens/home/components/two_row_horizontal_card_carousel.dart';
import 'package:muntum/screens/home/components/vertical_card_carousel.dart';
import 'package:muntum/screens/home/search_screen.dart';
import 'package:muntum/screens/home/see_more_screen.dart';
import 'package:muntum/services/analytics_service.dart';
import 'package:muntum/services/program_service.dart';

class EntireScreen extends StatefulWidget {
  final bool isActive;

  /// Whether to show Explore instead of the existing second-tab content.
  final bool isExplore;

  const EntireScreen({
    super.key,
    required this.isActive,
    this.isExplore = false,
  });

  @override
  State<EntireScreen> createState() => _EntireScreenState();
}

class _EntireScreenState extends State<EntireScreen> {
  static const double _collectionProgramsHeight = 370;

  Future<_EntireScreenPrograms>? _programsFuture;
  Filter? _selectedCollectionFilter;
  List<ProgramModel> _filteredCollectionPrograms = const [];
  bool _isLoadingCollection = false;
  int _collectionRequestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _activate();
  }

  @override
  void didUpdateWidget(covariant EntireScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _activate();
  }

  void _activate() {
    _programsFuture ??= _loadPrograms();
    unawaited(
      AnalyticsService.instance.logHomeTabView(
        widget.isExplore ? 'explore' : 'all',
      ),
    );
  }

  Future<void> _selectCollectionFilter(Filter? filter) async {
    if (_selectedCollectionFilter == filter) return;

    final requestId = ++_collectionRequestId;
    setState(() {
      _selectedCollectionFilter = filter;
      _filteredCollectionPrograms = const [];
      _isLoadingCollection = filter != null;
    });
    if (filter == null) return;

    try {
      final page = await ProgramService().fetchHotKeywordPrograms(
        programType: ProgramType.fromFilter(filter),
        includeEnded: false,
        size: 8,
      );
      if (!mounted || requestId != _collectionRequestId) return;
      setState(() => _filteredCollectionPrograms = page.content);
    } catch (_) {
      if (!mounted || requestId != _collectionRequestId) return;
      setState(() => _filteredCollectionPrograms = const []);
    } finally {
      if (mounted && requestId == _collectionRequestId) {
        setState(() => _isLoadingCollection = false);
      }
    }
  }

  Widget _buildCollectionPrograms(List<ProgramModel> allPrograms) {
    if (_isLoadingCollection) {
      return SizedBox(
        height: _collectionProgramsHeight.h,
        child: _buildExploreCollectionSkeleton(),
      );
    }

    final programs = _selectedCollectionFilter == null
        ? allPrograms
        : _filteredCollectionPrograms;
    return SizedBox(
      height: ProgramCardLayout.collectionHeight(context, programs),
      child: VerticalCardCarousel(
        programs: programs,
        entrySource: 'all_collection',
      ),
    );
  }

  Future<_EntireScreenPrograms> _loadPrograms() async {
    final service = ProgramService();
    final results = await Future.wait([
      if (!widget.isExplore) service.fetchBannerPrograms(),
      service.fetchHotKeywordPrograms(includeEnded: false, size: 8),
      service.fetchHotPrograms(size: 8),
      service.fetchClosingSoon(size: 8),
    ]);
    return _EntireScreenPrograms(
      banners: widget.isExplore ? const [] : results.first.content,
      all: results[results.length - 3].content,
      hot: results[results.length - 2].content,
      closingSoon: results.last.content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: Colors.transparent,
        child: Column(
          children: [
            SizedBox(
              height: widget.isExplore
                  ? MediaQuery.paddingOf(context).top
                  : 50.h,
            ),
            PageHeader(
              title: Text(
                widget.isExplore ? '탐색' : '전체',
                style: AppTypography.title2.copyWith(
                  color: widget.isExplore ? AppColors.gray900 : AppColors.black,
                ),
              ),
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
                      widget.isExplore ? AppColors.gray900 : AppColors.gray600,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<_EntireScreenPrograms>(
                future: _programsFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (widget.isExplore) {
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (_programsFuture != null)
                          const ExploreTasteSection(),
                        SizedBox(height: 32.h),
                        Divider(
                          height: 8.h,
                          thickness: 8.h,
                          color: AppColors.lineNormal,
                        ),
                        SizedBox(height: 24.h),
                        if (data != null) _buildProgramSections(context, data),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          _buildExploreCollectionSkeleton(),
                      ],
                    );
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return ListView(
                      padding: EdgeInsets.only(top: 8.h),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Semantics(
                            label: '추천 프로그램 불러오는 중',
                            child: SkeletonBlock(height: 467.h, radius: 8.r),
                          ),
                        ),
                        SizedBox(height: 56.h),
                        _buildExploreCollectionSkeleton(),
                      ],
                    );
                  }
                  if (data == null) return const SizedBox.shrink();
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      SizedBox(height: 8.h),
                      BannerCarousel(
                        programs: data.banners,
                        entrySource: 'all_banner',
                      ),
                      SizedBox(height: 56.h),
                      _buildProgramSections(context, data),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCollectionSkeleton() {
    return Semantics(
      label: '프로그램 불러오는 중',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          spacing: 12.w,
          children: List.generate(
            2,
            (_) => Expanded(
              child: Column(
                spacing: 8.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(
                    width: double.infinity,
                    height: 200.h,
                    radius: 8.r,
                  ),
                  SkeletonBlock(width: 120.w, height: 16.h),
                  SkeletonBlock(width: 85.w, height: 12.h),
                  SkeletonBlock(width: 105.w, height: 12.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramSections(
    BuildContext context,
    _EntireScreenPrograms data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader1(
          text: '유형별 모아보기',
          buttonName: widget.isExplore ? '' : '전체보기',
          onButtonTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeeMoreScreen(
                  type: SeeMoreType.allPrograms,
                  initialFilter: _selectedCollectionFilter,
                ),
              ),
            );
          },
        ),
        ProgramTypeTabs(
          selectedFilter: _selectedCollectionFilter,
          onSelected: _selectCollectionFilter,
        ),
        SizedBox(height: 16.h),
        _buildCollectionPrograms(data.all),
        SectionHeader1(text: '🔥인기 있는', buttonName: '', onButtonTap: () {}),
        SizedBox(height: 8.h),
        TwoRowHorizontalCardCarousel(
          programs: data.hot,
          entrySource: 'all_hot',
        ),
        SectionHeader1(
          text: '이번달에 끝나는',
          buttonName: widget.isExplore ? '' : '전체보기',
          onButtonTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const SeeMoreScreen(type: SeeMoreType.endingThisMonth),
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
    );
  }
}

class _EntireScreenPrograms {
  final List<ProgramModel> banners;
  final List<ProgramModel> all;
  final List<ProgramModel> hot;
  final List<ProgramModel> closingSoon;

  const _EntireScreenPrograms({
    required this.banners,
    required this.all,
    required this.hot,
    required this.closingSoon,
  });
}
