import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/appbar.dart';
import 'package:muntum/screens/home/components/cards/horizontal.dart';
import 'package:muntum/screens/home/components/keyword_chip.dart';
import 'package:muntum/screens/home/components/popup_widget.dart';
import 'package:muntum/screens/home/components/recent_search_widget.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<String> popularKeywords = [
    '가만히 못 있는 편',
    '식탁보상 생활하는',
    '감성 낭만 충전',
    '갓생살기',
    '그 순간에 몰입',
    '내 손으로 만드는',
    '눈을 사로잡는',
    '느긋하게 힐링하는',
    '도파민 디톡스',
    '미식 탐험가',
    '복작복작 핫플',
    '사람들과 도란도란',
    '사진맛집',
    '새로운 것 배우기',
    '색다르게 즐기는',
    '생생한 감각',
    '쉽게 해석되지 않는',
    '압도감을 느끼는',
    '야외에서 즐기는',
    '여러 작품을 한 번에',
    '여운이 남는',
    '음악에 집중하는',
    '전통문화 역사 덕후',
    '조용하고 차분한',
    '직접 참여하는',
    '깊은 대화 나누는',
    '명상과 가까운',
    '퇴근하고 슬쩍',
    '짧게 즐기는',
    '이번달 끝나는',
  ];

  static const String _recentSearchesKey = 'recent_searches';
  final List<String> _defaultRecentSearches = [
    '큐비스트: 시각의 혁신가들',
    '우아한',
    '서울시립미술관',
    '국립현대미술관',
  ];
  List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  final List<String> _selectedKeywords = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSearches = prefs.getStringList(_recentSearchesKey);

    setState(() {
      _recentSearches =
          savedSearches ?? List<String>.from(_defaultRecentSearches);
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  void _onSearchSubmitted(String text) {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return;
    }
    _addRecentSearch(trimmedText);
    setState(() {
      searchText = trimmedText;
    });
  }

  void _onKeywordSelected(String keyword) {
    setState(() {
      if (!_selectedKeywords.contains(keyword)) {
        _selectedKeywords.add(keyword);
      }
      searchText = _selectedKeywords.join(', ');
      _searchController.clear();
    });

    _addRecentSearch(keyword);
  }

  void _showKeywordSelectionModal() {
    final List<String> modalSelectedKeywords = List<String>.from(
      _selectedKeywords,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedCount = modalSelectedKeywords.length;
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.86,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              '키워드 선택',
                              textAlign: TextAlign.center,
                              style: AppTypography.title4.copyWith(
                                color: AppColors.gray900,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: SvgPicture.asset(
                              'assets/icons/close.svg',
                              width: 24.sp,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 10.h,
                            alignment: WrapAlignment.start,
                            children: popularKeywords.map((keyword) {
                              final isSelected = modalSelectedKeywords.contains(
                                keyword,
                              );
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      modalSelectedKeywords.remove(keyword);
                                    } else {
                                      modalSelectedKeywords.add(keyword);
                                    }
                                  });
                                },
                                child: KeywordChip(
                                  text: keyword,
                                  textColor: AppColors.black,
                                  outlineColor: isSelected
                                      ? AppColors.black
                                      : AppColors.lineStrong,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                modalSelectedKeywords.clear();
                              });
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/redo.svg',
                                  width: 18.sp,
                                  color: AppColors.gray900,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '선택 초기화',
                                  style: AppTypography.button1.copyWith(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: SizedBox(
                              height: 52.h,
                              child: GestureDetector(
                                onTap: selectedCount == 0
                                    ? null
                                    : () {
                                        final joinedKeywords =
                                            modalSelectedKeywords.join(', ');
                                        setState(() {
                                          _selectedKeywords
                                            ..clear()
                                            ..addAll(modalSelectedKeywords);
                                          searchText = joinedKeywords;
                                          _searchController.clear();
                                        });
                                        Navigator.pop(context);
                                      },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.radius_8,
                                    ),
                                    color: selectedCount == 0
                                        ? AppColors.gray200
                                        : AppColors.black,
                                  ),
                                  child: Center(
                                    child: Text(
                                      selectedCount == 0
                                          ? '검색하기'
                                          : '$selectedCount 검색하기',
                                      style: AppTypography.button1.copyWith(
                                        color: selectedCount == 0
                                            ? AppColors.gray400
                                            : AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addRecentSearch(String text) {
    final trimmedText = text.trim();

    setState(() {
      _recentSearches.remove(trimmedText);
      _recentSearches.insert(0, trimmedText);

      if (_recentSearches.length > 10) {
        _recentSearches.removeRange(10, _recentSearches.length);
      }
    });
    _saveRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.backgroundNormal,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            onLeadingTap: () {
              Navigator.pop(context);
            },
            leadingIcon: "arrow_left.svg",
            centerType: AppBarCenterType.searchbar,
            searchController: _searchController,
            onSearchSubmitted: _onSearchSubmitted,
            onClear: () {
              setState(() {
                searchText = '';
                _selectedKeywords.clear();
              });
            },
            selectedKeywords: _selectedKeywords,
            onKeywordDeleted: (keyword) {
              setState(() {
                _selectedKeywords.remove(keyword);
                searchText = _selectedKeywords.join(', ');
                if (_selectedKeywords.isEmpty) {
                  searchText = '';
                }
              });
            },
          ),
          searchText.isEmpty
              ? _defaultSearchScreen(context)
              : _searchSubmitScreen(),
        ],
      ),
    );
  }

  Widget _defaultSearchScreen(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            SectionHeader2(
              text: '인기키워드',
              buttonName: '여러 키워드로 검색',
              onButtonTap: _showKeywordSelectionModal,
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: popularKeywords.take(6).map((keyword) {
                  return GestureDetector(
                    onTap: () {
                      _onKeywordSelected(keyword);
                    },
                    child: KeywordChip(
                      text: keyword,
                      textColor: AppColors.gray800,
                      outlineColor: AppColors.lineStrong,
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 32.h),
            SectionHeader2(
              text: '최근 검색어',
              buttonName: '전체 삭제',
              onButtonTap: () {
                showPopupWidget(
                  context: context,
                  title: '최근 검색어를 모두 삭제할까요?',
                  description: '검색 내역이 전부 삭제됩니다.',
                  text1: '취소',
                  text2: '삭제하기',
                  onText1Tap: () {
                    Navigator.pop(context);
                  },
                  onText2Tap: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                    _saveRecentSearches();
                    Navigator.pop(context);
                  },
                );
              },
            ),
            SizedBox(height: 12.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = _recentSearches[index];
                    searchText = _recentSearches[index];
                    setState(() {});
                  },
                  child: RecentSearchWidget(
                    text: _recentSearches[index],
                    onDelete: () {
                      setState(() {
                        _recentSearches.removeAt(index);
                      });
                      _saveRecentSearches();
                    },
                  ),
                );
              },
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemCount: _recentSearches.length,
            ),
          ],
        ),
      ),
    );
  }

  final List<String> searchResult = [
    '프로그램1',
    '프로그램2',
    '프로그램3',
    '프로그램4',
    '프로그램5',
    '프로그램6',
    '프로그램7',
    '프로그램8',
  ];

  Widget _searchSubmitScreen() {
    return searchResult.isEmpty
        ? Expanded(
            child: Center(
              child: Text(
                "검색 결과가 없어요.",
                style: AppTypography.body2.copyWith(color: AppColors.gray500),
              ),
            ),
          )
        : Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader3(
                    text: '프로그램 ${searchResult.length}개',
                    buttonName: '',
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) =>
                          HorizontalCard(programName: searchResult[index]),
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemCount: searchResult.length,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
