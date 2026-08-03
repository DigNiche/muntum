import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/program_type_tabs.dart';
import 'package:muntum/services/program_service.dart';

enum SeeMoreType { allPrograms, endingThisMonth }

class SeeMoreScreen extends StatefulWidget {
  final SeeMoreType type;

  const SeeMoreScreen({super.key, required this.type});

  String get title => switch (type) {
    SeeMoreType.allPrograms => '유형별 모아보기',
    SeeMoreType.endingThisMonth => '이번달에 끝나는',
  };

  @override
  State<SeeMoreScreen> createState() => _SeeMoreScreenState();
}

class _SeeMoreScreenState extends State<SeeMoreScreen> {
  static const int _pageSize = 20;

  Filter? _selectedFilter;
  final ScrollController _scrollController = ScrollController();
  List<ProgramModel> _programs = const [];
  int _nextPage = 0;
  int _totalElements = 0;
  bool _hasNextPage = true;
  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadPrograms(reset: true);
  }

  Future<void> _loadPrograms({required bool reset}) async {
    if (!reset && (_isLoading || !_hasNextPage)) return;
    final requestId = reset ? ++_requestId : _requestId;
    final requestedPage = reset ? 0 : _nextPage;
    setState(() {
      _isLoading = true;
      if (reset) {
        _programs = const [];
        _nextPage = 0;
        _totalElements = 0;
        _hasNextPage = true;
      }
    });
    final service = ProgramService();
    try {
      final page = widget.type == SeeMoreType.endingThisMonth
          ? await service.fetchClosingSoon(
              chip: _selectedFilter,
              page: requestedPage,
              size: _pageSize,
            )
          : await service.fetchHotKeywordPrograms(
              chip: _selectedFilter,
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
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 400.h) {
      _loadPrograms(reset: false);
    }
  }

  void _selectFilter(Filter? filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    _loadPrograms(reset: true);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
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
        body: Column(
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
                          14.h,
                          20.w,
                          programs.isEmpty ? 0 : 24.h,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Text(
                              '프로그램 ${_totalElements > 0 ? _totalElements : programs.length}개',
                              style: AppTypography.headline2.copyWith(
                                color: AppColors.gray900,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            for (
                              var index = 0;
                              index < programs.length;
                              index++
                            ) ...[
                              HorizontalCard(
                                program: programs[index],
                                entrySource:
                                    widget.type == SeeMoreType.allPrograms
                                    ? 'all_collection'
                                    : 'all_closing_soon',
                              ),
                              if (index != programs.length - 1)
                                SizedBox(height: 16.h),
                            ],
                            if (_isLoading && programs.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ),
                      if (programs.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.gray900,
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
      ),
    );
  }
}
