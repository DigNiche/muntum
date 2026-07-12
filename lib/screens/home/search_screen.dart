import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/keyword_chip.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/recent_search_widget.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/services/keyword_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _guestRecentSearchesKey = 'recent_searches';
  static const String _userRecentSearchesKeyPrefix = 'recent_searches_user';
  List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  final List<String> _selectedKeywords = [];
  Future<List<ProgramModel>>? _searchResultFuture;
  late Future<List<String>> _popularKeywordsFuture;
  late Future<List<String>> _allKeywordsFuture;

  @override
  void initState() {
    super.initState();
    _popularKeywordsFuture = _loadPopularKeywords();
    _allKeywordsFuture = _loadAllKeywords();
    _loadRecentSearches();
  }

  Future<List<String>> _loadPopularKeywords() async {
    try {
      final keywords = await SearchService().fetchTopSearchKeywords();
      return keywords
          .map((keyword) => keyword.name)
          .where((name) => name.isNotEmpty)
          .take(6)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _loadAllKeywords() async {
    try {
      final keywords = await KeywordService().fetchTaggedKeywords();
      return keywords
          .map((keyword) => keyword.name)
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> _usesApiRecentSearches() async {
    if (TokenStore.instance.accessToken?.isNotEmpty == true) return true;
    final refreshToken = await TokenStore.instance.readRefreshToken();
    return refreshToken?.isNotEmpty == true;
  }

  Future<void> _loadRecentSearches() async {
    if (await _usesApiRecentSearches()) {
      try {
        final recent = await SearchService().fetchRecentSearches();
        final apiSearches = recent
            .map((search) => search.keyword)
            .where((keyword) => keyword.isNotEmpty)
            .toList();
        final localSearches = await _loadLocalRecentSearches(userScoped: true);
        final searches = apiSearches.isNotEmpty ? apiSearches : localSearches;
        if (!mounted) return;
        setState(() {
          _recentSearches = List<String>.from(searches);
        });
        if (apiSearches.isNotEmpty) {
          await _saveLocalRecentSearches(userScoped: true);
        }
        return;
      } catch (_) {
        final localSearches = await _loadLocalRecentSearches(userScoped: true);
        if (!mounted) return;
        setState(() {
          _recentSearches = List<String>.from(localSearches);
        });
        return;
      }
    }
    final savedSearches = await _loadLocalRecentSearches(userScoped: false);
    if (!mounted) return;
    setState(() {
      _recentSearches = List<String>.from(savedSearches);
    });
  }

  Future<String> _recentSearchesStorageKey({required bool userScoped}) async {
    if (!userScoped) return _guestRecentSearchesKey;
    final email = (await TokenStore.instance.readEmail())?.trim();
    if (email != null && email.isNotEmpty) {
      return '${_userRecentSearchesKeyPrefix}_$email';
    }
    final refreshToken = (await TokenStore.instance.readRefreshToken()) ?? '';
    return '${_userRecentSearchesKeyPrefix}_${refreshToken.hashCode}';
  }

  Future<List<String>> _loadLocalRecentSearches({
    required bool userScoped,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _recentSearchesStorageKey(userScoped: userScoped);
    return List<String>.from(prefs.getStringList(key) ?? const <String>[]);
  }

  Future<void> _saveLocalRecentSearches({required bool userScoped}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _recentSearchesStorageKey(userScoped: userScoped);
    await prefs.setStringList(key, List<String>.from(_recentSearches));
  }

  void _onSearchSubmitted(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return;
    }
    setState(() {
      searchText = trimmedText;
      _searchResultFuture = _loadSearchResults();
    });
    await _addRecentSearch(trimmedText);
  }

  void _onKeywordSelected(String keyword) {
    setState(() {
      if (!_selectedKeywords.contains(keyword)) {
        _selectedKeywords.add(keyword);
      }
      searchText = _selectedKeywords.join(', ');
      _searchController.clear();
      _searchResultFuture = _loadSearchResults();
    });
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
                              colorFilter: const ColorFilter.mode(
                                AppColors.gray900,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Expanded(
                        child: FutureBuilder<List<String>>(
                          future: _allKeywordsFuture,
                          builder: (context, snapshot) {
                            final keywords = snapshot.data ?? const <String>[];
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gray900,
                                ),
                              );
                            }
                            if (keywords.isEmpty) {
                              return Center(
                                child: Text(
                                  '불러올 키워드가 없어요.',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.gray500,
                                  ),
                                ),
                              );
                            }
                            return SingleChildScrollView(
                              child: Wrap(
                                spacing: 8.w,
                                runSpacing: 10.h,
                                alignment: WrapAlignment.start,
                                children: keywords.map((keyword) {
                                  final isSelected = modalSelectedKeywords
                                      .contains(keyword);
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
                            );
                          },
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
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.gray900,
                                    BlendMode.srcIn,
                                  ),
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
                                          _searchResultFuture =
                                              _loadSearchResults();
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

  Future<void> _addRecentSearch(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    if (await _usesApiRecentSearches()) {
      setState(() => _insertRecentSearch(trimmedText));
      await _saveLocalRecentSearches(userScoped: true);
      try {
        await SearchService().saveRecentSearch(trimmedText);
        await _loadRecentSearches();
      } catch (_) {}
      return;
    }
    setState(() => _insertRecentSearch(trimmedText));
    await _saveLocalRecentSearches(userScoped: false);
  }

  void _insertRecentSearch(String text) {
    final nextSearches = List<String>.from(_recentSearches);
    nextSearches.remove(text);
    nextSearches.insert(0, text);

    if (nextSearches.length > 10) {
      nextSearches.removeRange(10, nextSearches.length);
    }
    _recentSearches = nextSearches;
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
      backgroundColor: AppColors.white,
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
                _searchResultFuture = null;
              });
            },
            selectedKeywords: _selectedKeywords,
            onSearchTap: _selectedKeywords.isNotEmpty
                ? _showKeywordSelectionModal
                : null,
            onKeywordDeleted: (keyword) {
              setState(() {
                _selectedKeywords.remove(keyword);
                searchText = _selectedKeywords.join(', ');
                if (_selectedKeywords.isEmpty) {
                  searchText = '';
                  _searchResultFuture = null;
                } else {
                  _searchResultFuture = _loadSearchResults();
                }
              });
            },
            searchAutofocus: true,
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
              child: FutureBuilder<List<String>>(
                future: _popularKeywordsFuture,
                builder: (context, snapshot) {
                  final keywords = snapshot.data ?? const <String>[];
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 36,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gray900,
                        ),
                      ),
                    );
                  }
                  if (keywords.isEmpty) {
                    return Text(
                      '인기 키워드가 아직 없어요.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray500,
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: keywords.map((keyword) {
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
                  );
                },
              ),
            ),
            SizedBox(height: 32.h),
            if (_recentSearches.isNotEmpty) ...[
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
                    onText2Tap: () async {
                      Navigator.pop(context);
                      final usesApi = await _usesApiRecentSearches();
                      setState(() {
                        _recentSearches = [];
                      });
                      if (usesApi) {
                        try {
                          await SearchService().deleteAllRecentSearches();
                        } finally {
                          await _saveLocalRecentSearches(userScoped: true);
                        }
                      } else {
                        await _saveLocalRecentSearches(userScoped: false);
                      }
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
                      _searchResultFuture = _loadSearchResults();
                      setState(() {});
                    },
                    child: RecentSearchWidget(
                      text: _recentSearches[index],
                      onDelete: () async {
                        final keyword = _recentSearches[index];
                        setState(() {
                          final nextSearches = List<String>.from(
                            _recentSearches,
                          );
                          nextSearches.removeAt(index);
                          _recentSearches = nextSearches;
                        });
                        final usesApi = await _usesApiRecentSearches();
                        if (usesApi) {
                          try {
                            await SearchService().deleteRecentSearch(keyword);
                          } finally {
                            await _saveLocalRecentSearches(userScoped: true);
                            await _loadRecentSearches();
                          }
                        } else {
                          await _saveLocalRecentSearches(userScoped: false);
                        }
                      },
                    ),
                  );
                },
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
                itemCount: _recentSearches.length,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<ProgramModel>> _loadSearchResults() async {
    final service = ProgramService();
    final query = _selectedKeywords.isEmpty ? searchText : '';

    if (_selectedKeywords.isNotEmpty) {
      return (await service.fetchPrograms(
        keywordNames: _selectedKeywords,
        size: 100,
      )).content;
    }

    return (await service.fetchPrograms(
      search: query,
      size: 100,
      authorized: await _usesApiRecentSearches(),
    )).content;
  }

  Widget _searchSubmitScreen() {
    final future = _searchResultFuture ?? _loadSearchResults();
    _searchResultFuture = future;
    return Expanded(
      child: FutureBuilder<List<ProgramModel>>(
        future: future,
        builder: (context, snapshot) {
          final results = snapshot.data ?? const <ProgramModel>[];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gray900),
            );
          }
          if (results.isEmpty) {
            return Center(
              child: Text(
                "검색 결과가 없어요.",
                style: AppTypography.body2.copyWith(color: AppColors.gray500),
              ),
            );
          }
          return Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader3(text: '프로그램 ${results.length}개', buttonName: ''),
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final isLast = index == results.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 40.h : 0),
                        child: HorizontalCard(program: results[index]),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 12.h),
                    itemCount: results.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
