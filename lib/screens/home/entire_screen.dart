import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/banner_carousel.dart';
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

  const EntireScreen({super.key, required this.isActive});

  @override
  State<EntireScreen> createState() => _EntireScreenState();
}

class _EntireScreenState extends State<EntireScreen> {
  static const double _collectionProgramsHeight = 370;

  late Future<_EntireScreenPrograms> _programsFuture;
  Filter? _selectedCollectionFilter;
  List<ProgramModel> _filteredCollectionPrograms = const [];
  bool _isLoadingCollection = false;
  int _collectionRequestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _logTabView();
    _programsFuture = _loadPrograms();
  }

  @override
  void didUpdateWidget(covariant EntireScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _logTabView();
  }

  void _logTabView() {
    unawaited(AnalyticsService.instance.logHomeTabView('all'));
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
        chip: filter,
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
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.gray900),
        ),
      );
    }

    final programs = _selectedCollectionFilter == null
        ? allPrograms
        : _filteredCollectionPrograms;
    return SizedBox(
      height: _collectionProgramsHeight.h,
      child: VerticalCardCarousel(
        programs: programs,
        entrySource: 'all_collection',
      ),
    );
  }

  Future<_EntireScreenPrograms> _loadPrograms() async {
    final service = ProgramService();
    final results = await Future.wait([
      service.fetchBannerPrograms(),
      service.fetchHotKeywordPrograms(size: 8),
      service.fetchHotPrograms(size: 8),
      service.fetchClosingSoon(size: 8),
    ]);
    return _EntireScreenPrograms(
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
            SizedBox(height: 50.h),
            PageHeader(
              title: Text(
                '전체',
                style: AppTypography.title2.copyWith(color: AppColors.black),
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
                      AppColors.gray600,
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
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gray900,
                      ),
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
                      Column(
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
                          SectionHeader1(
                            text: '🔥인기 있는',
                            buttonName: '',
                            onButtonTap: () {},
                          ),
                          SizedBox(height: 8.h),
                          TwoRowHorizontalCardCarousel(
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
