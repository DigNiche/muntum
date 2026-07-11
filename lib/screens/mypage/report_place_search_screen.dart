import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/report_place_search_repository.dart';
import 'package:muntum/models/report_model.dart';

class ReportPlaceSearchScreen extends StatefulWidget {
  const ReportPlaceSearchScreen({super.key});

  @override
  State<ReportPlaceSearchScreen> createState() =>
      _ReportPlaceSearchScreenState();
}

class _ReportPlaceSearchScreenState extends State<ReportPlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _directController = TextEditingController();
  final ReportPlaceSearchRepository _repository =
      const NaverLocalPlaceSearchRepository();
  List<ReportPlace> _results = [];
  bool _isSearching = false;
  int _searchSerial = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _directController.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final keyword = value.trim();
    final currentSerial = ++_searchSerial;

    if (keyword.isEmpty) {
      setState(() {
        _isSearching = false;
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _repository.search(keyword);
    if (!mounted || currentSerial != _searchSerial) return;

    setState(() {
      _isSearching = false;
      _results = results;
    });
  }

  void _openDirectInputSheet() {
    _directController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canSubmit = _directController.text.trim().isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '장소를 직접 입력해주세요.',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _directController,
                    autofocus: true,
                    onChanged: (_) => setSheetState(() {}),
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.gray900,
                    ),
                    decoration: InputDecoration(
                      hintText: '문틈박물관',
                      hintStyle: AppTypography.caption1.copyWith(
                        color: AppColors.gray400,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 13.h,
                      ),
                      suffixIcon: canSubmit
                          ? GestureDetector(
                              onTap: () {
                                _directController.clear();
                                setSheetState(() {});
                              },
                              child: Icon(
                                Icons.cancel,
                                size: 18.r,
                                color: AppColors.gray400,
                              ),
                            )
                          : null,
                      enabledBorder: _inputBorder(
                        canSubmit ? AppColors.primary500 : AppColors.lineStrong,
                      ),
                      focusedBorder: _inputBorder(AppColors.primary500),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ButtonSolid(
                    text: '완료',
                    textColor: AppColors.white,
                    boxColor: canSubmit ? AppColors.black : AppColors.gray200,
                    onTap: canSubmit
                        ? () {
                            final name = _directController.text.trim();
                            Navigator.pop(context);
                            Navigator.pop(
                              context,
                              ReportPlace(name: name, address: '직접 입력한 장소'),
                            );
                          }
                        : null,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: BorderSide(color: color, width: 1.w),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKeyword = _searchController.text.trim().isNotEmpty;
    final hasNoResult = hasKeyword && !_isSearching && _results.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '장소 검색',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              autofocus: true,
              style: AppTypography.caption1.copyWith(color: AppColors.gray900),
              decoration: InputDecoration(
                hintText: '장소를 검색해보세요.',
                hintStyle: AppTypography.caption1.copyWith(
                  color: AppColors.gray400,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12.w, right: 8.w),
                  child: SvgPicture.asset(
                    'assets/icons/search.svg',
                    width: 16.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.gray700,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 36.w,
                  minHeight: 16.h,
                ),
                suffixIcon: hasKeyword
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _search('');
                        },
                        child: Icon(
                          Icons.cancel,
                          size: 18.r,
                          color: AppColors.gray400,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 11.h),
                enabledBorder: _inputBorder(AppColors.lineStrong),
                focusedBorder: _inputBorder(AppColors.lineStrong),
              ),
            ),
          ),
          Expanded(
            child: hasKeyword
                ? _SearchResultBody(
                    results: _results,
                    hasNoResult: hasNoResult,
                    isSearching: _isSearching,
                    onDirectInput: _openDirectInputSheet,
                  )
                : Center(
                    child: Text(
                      '장소명(건물명)으로 검색해보세요.',
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultBody extends StatelessWidget {
  final List<ReportPlace> results;
  final bool hasNoResult;
  final bool isSearching;
  final VoidCallback onDirectInput;

  const _SearchResultBody({
    required this.results,
    required this.hasNoResult,
    required this.isSearching,
    required this.onDirectInput,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gray900,
          ),
        ),
      );
    }

    if (hasNoResult) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '검색된 장소가 없어요.',
              style: AppTypography.caption2.copyWith(color: AppColors.gray400),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: onDirectInput,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: AppColors.lineStrong),
                ),
                child: Text(
                  '직접 입력하기',
                  style: AppTypography.button4.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      itemBuilder: (context, index) {
        final place = results[index];
        return GestureDetector(
          onTap: () => Navigator.pop(context, place),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  place.address,
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => SizedBox(height: 18.h),
      itemCount: results.length,
    );
  }
}
