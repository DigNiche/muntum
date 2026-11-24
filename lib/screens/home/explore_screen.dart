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
import 'package:muntum/screens/home/components/explore_taste_section.dart';
import 'package:muntum/screens/home/components/program_type_tabs.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/screens/home/components/two_row_horizontal_card_carousel.dart';
import 'package:muntum/screens/home/components/vertical_card_carousel.dart';
import 'package:muntum/screens/home/search_screen.dart';
import 'package:muntum/screens/home/see_more_screen.dart';
import 'package:muntum/services/analytics_service.dart';
import 'package:muntum/services/program_service.dart';

class ExploreScreen extends StatefulWidget {
  final bool isActive;

  const ExploreScreen({super.key, required this.isActive});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const double _collectionProgramsHeight = 370;

  Future<_ExplorePrograms>? _programsFuture;
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
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _activate();
  }

  void _activate() {
    _programsFuture ??= _loadPrograms();
    unawaited(AnalyticsService.instance.logHomeTabView('explore'));
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

  Future<_ExplorePrograms> _loadPrograms() async {
    final service = ProgramService();
    final results = await Future.wait([
      service.fetchBannerPrograms(),
      service.fetchHotKeywordPrograms(includeEnded: false, size: 8),
      service.fetchHotPrograms(size: 8),
      service.fetchClosingSoon(size: 8),
    ]);
    return _ExplorePrograms(
      banners: results[0].content,
      all: results[1].content,
      hot: results[2].content,
      closingSoon: results[3].content,
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
            SizedBox(height: MediaQuery.paddingOf(context).top),
            PageHeader(
              title: Text(
                '탐색',
                style: AppTypography.title2.copyWith(color: AppColors.gray900),
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
                    colorFilter: const ColorFilter.mode(
                      AppColors.gray900,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<_ExplorePrograms>(
                future: _programsFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (_programsFuture != null) const ExploreTasteSection(),
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

  Widget _buildProgramSections(BuildContext context, _ExplorePrograms data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader1(
          text: '유형별 모아보기',
          buttonName: '전체보기',
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
        const SectionHeader1(text: '🔥인기 있는', buttonName: ''),
        SizedBox(height: 8.h),
        TwoRowHorizontalCardCarousel(
          programs: data.hot,
          entrySource: 'all_hot',
        ),
        if (data.banners.isNotEmpty) ...[
          const SectionHeader1(text: '✨새롭게 소개된', buttonName: ''),
          SizedBox(height: 8.h),
          VerticalCardCarousel(
            programs: data.banners,
            entrySource: 'explore_newly_introduced',
          ),
        ],
        SectionHeader1(
          text: '⏰ 이번달에 끝나는',
          buttonName: '전체보기',
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

class _ExplorePrograms {
  final List<ProgramModel> banners;
  final List<ProgramModel> all;
  final List<ProgramModel> hot;
  final List<ProgramModel> closingSoon;

  const _ExplorePrograms({
    required this.banners,
    required this.all,
    required this.hot,
    required this.closingSoon,
  });
}
