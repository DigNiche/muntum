import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/components/appbar.dart';
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
  final popularKeywords = {
    '색다르게 즐기는',
    '사람들과 도란도란',
    '사진맛집',
    '내 손으로 만드는',
    '도파민 디톡스',
    '여러 작품을 한 번에',
    '힐링',
  };

  static const String _recentSearchesKey = 'recent_searches';

  final List<String> _defaultRecentSearches = [
    '큐비스트: 시각의 혁신가들',
    '우아한',
    '서울시립미술관',
    '국립현대미술관',
  ];

  List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();

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

  void _addRecentSearch(String text) {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return;
    }
    setState(() {
      _recentSearches.remove(trimmedText);
      _recentSearches.insert(0, trimmedText);

      if (_recentSearches.length > 10) {
        _recentSearches.removeRange(10, _recentSearches.length);
      }
    });
    _saveRecentSearches();
    _searchController.clear();
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
            onSearchSubmitted: _addRecentSearch,
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader2(text: '인기키워드', buttonName: '여러 키워드로 검색'),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: popularKeywords.take(6).map((keyword) {
                        return KeywordChip(
                          text: keyword,
                          textColor: AppColors.gray800,
                          outlineColor: AppColors.lineStrong,
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
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return RecentSearchWidget(
                        text: _recentSearches[index],
                        onDelete: () {
                          setState(() {
                            _recentSearches.removeAt(index);
                          });
                          _saveRecentSearches();
                        },
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemCount: _recentSearches.length,
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
