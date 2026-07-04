import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/data/mock_program_data.dart';
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

enum ScreenTypes { myNiche, entire }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScreenTypes screenType = ScreenTypes.myNiche;

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
                    setState(() {
                      screenType = ScreenTypes.myNiche;
                    });
                  },
                  secondText: '전체',
                  secondTextColor: isMyNiche
                      ? AppColors.gray600
                      : AppColors.black,
                  onSecondTextTap: () {
                    setState(() {
                      screenType = ScreenTypes.entire;
                    });
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
  final ScrollController _scrollController = ScrollController();
  String? selectedFilter;
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 200.h;
    if (shouldShow != _showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = shouldShow;
      });
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

  void _onFilterTap(String filter) {
    setState(() {
      selectedFilter = (selectedFilter == filter ? null : filter);
      _showScrollToTopButton = false;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
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
    final hasSelectedFilter = selectedFilter != null;
    final selectedFilterValue = switch (selectedFilter) {
      '무료' => Filter.free,
      '이번주' => Filter.thisWeek,
      '예약없이' => Filter.noReservation,
      '전시' => Filter.exhibition,
      '공연' => Filter.show,
      '체험' => Filter.experience,
      '축제' => Filter.festival,
      _ => null,
    };
    final programs = selectedFilterValue == null
        ? mockPrograms
        : mockPrograms
              .where((program) => program.filters.contains(selectedFilterValue))
              .toList();

    return Column(
      children: [
        FilterList(
          listOfChip: [
            _buildFilterChip('무료'),
            _buildFilterChip('이번주'),
            _buildFilterChip('예약없이'),
            _buildFilterChip('전시'),
            _buildFilterChip('공연'),
            _buildFilterChip('체험'),
            _buildFilterChip('축제'),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: hasSelectedFilter && programs.isEmpty
                    ? Center(
                        child: Text(
                          '조건에 맞는 프로그램이 없어요.',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: programs.length,
                        itemBuilder: (context, index) =>
                            CurationCard(program: programs[index]),
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
                      width: 48.w,
                      height: 48.h,
                      child: SvgPicture.asset(
                        'assets/icons/arrow_up_2.svg',
                        width: 24.w,
                        height: 24.w,
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
  }
}

class EntirePage extends StatelessWidget {
  const EntirePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        BannerCarousel(programs: mockPrograms.take(3).toList()),
        SizedBox(height: 48.h),
        SectionHeader1(
          text: '모아보기',
          buttonName: '전체보기',
          onButtonTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const SeeMoreScreen(type: SeeMoreType.allPrograms),
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
        VerticalCardCarousel(programs: mockPrograms.take(8).toList()),
        SectionHeader1(text: '지금 주목받는', buttonName: '', onButtonTap: () {}),
        SizedBox(height: 8.h),
        VerticalCardCarousel(
          programs: mockPrograms
              .where((program) => program.isSpotlight)
              .take(8)
              .toList(),
        ),
        SectionHeader1(
          text: '이번달에 끝나는',
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
          programs: mockPrograms
              .where((program) => program.isOverThisMonth)
              .take(8)
              .toList(),
        ),
      ],
    );
  }
}
