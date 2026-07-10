import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/mock_user_data.dart';
import 'package:muntum/models/user_keyword.dart';
import 'package:muntum/services/keyword_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/utils/app_toast.dart';

class KeywordChangeScreen extends StatefulWidget {
  const KeywordChangeScreen({super.key});

  @override
  State<KeywordChangeScreen> createState() => _KeywordChangeScreenState();
}

class _KeywordChangeScreenState extends State<KeywordChangeScreen> {
  bool isEdit = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Color trailingTextColor = AppColors.gray900;
  List<String> _allKeywords = List.of(entireKeywords);
  final Set<String> _selectedKeywords = {};

  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }

  Future<void> _loadKeywords() async {
    setState(() => _isLoading = true);
    try {
      if (ApiConfig.hasBaseUrl) {
        final allResult = await KeywordService().fetchTaggedKeywords();
        final selectedResult = await TasteService().fetchMyKeywords();
        final all = allResult.map((keyword) => keyword.name).toList();
        final selected = selectedResult.selectedKeywords
            .map((keyword) => keyword.name)
            .toList();
        if (!mounted) return;
        setState(() {
          _allKeywords = all.isEmpty ? List.of(entireKeywords) : all;
          _selectedKeywords
            ..clear()
            ..addAll(selected);
          MockUserSession.instance.updateKeywords(selected);
        });
      } else {
        setState(() {
          _allKeywords = List.of(entireKeywords);
          _selectedKeywords
            ..clear()
            ..addAll(MockUserSession.instance.selectedKeywords);
        });
      }
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error');
      setState(() {
        _allKeywords = List.of(entireKeywords);
        _selectedKeywords
          ..clear()
          ..addAll(MockUserSession.instance.selectedKeywords);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEditOrSave() async {
    if (!isEdit) {
      setState(() {
        isEdit = true;
        trailingTextColor = AppColors.gray500;
      });
      return;
    }

    if (_selectedKeywords.length < 3 || _isSaving) {
      showAppToast(context, '키워드를 3개 이상 선택해주세요.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (ApiConfig.hasBaseUrl) {
        await TasteService().saveMyKeywords(_selectedKeywords.toList());
      }
      MockUserSession.instance.updateKeywords(_selectedKeywords);
      if (!mounted) return;
      setState(() {
        isEdit = false;
        trailingTextColor = AppColors.gray900;
      });
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleKeyword(String keyword) {
    setState(() {
      trailingTextColor = AppColors.gray900;
      if (!_selectedKeywords.add(keyword)) {
        _selectedKeywords.remove(keyword);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: isEdit ? 'arrow_left.svg' : 'close.svg',
            center: isEdit ? '키워드 편집' : "키워드",
            onLeadingTap: () {
              if (isEdit) {
                isEdit = false;
                setState(() {});
              } else {
                Navigator.pop(context);
              }
            },
            trailing: GestureDetector(
              onTap: _toggleEditOrSave,
              child: Text(
                _isSaving
                    ? '저장 중...'
                    : isEdit
                    ? '저장'
                    : '편집',
                style: AppTypography.button2.copyWith(color: trailingTextColor),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "내 키워드(${_selectedKeywords.length})",
                    style: AppTypography.headline2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gray900,
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              spacing: 8.h,
                              children: isEdit
                                  ? _allKeywords.map((keyword) {
                                      final isSelected = _selectedKeywords
                                          .contains(keyword);
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0.h,
                                        ),
                                        child: Row(
                                          spacing: 12.w,
                                          children: [
                                            Container(
                                              width: 20.w,
                                              height: 20.h,
                                              padding: EdgeInsets.all(2.r),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                color: isSelected
                                                    ? AppColors.gray900
                                                    : AppColors.gray100,
                                              ),
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _toggleKeyword(keyword),
                                                child: SvgPicture.asset(
                                                  isSelected
                                                      ? 'assets/icons/check.svg'
                                                      : 'assets/icons/plus.svg',
                                                  width: 20.w,
                                                  color: isSelected
                                                      ? AppColors.white
                                                      : AppColors.gray600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              keyword,
                                              style: AppTypography.body1
                                                  .copyWith(
                                                    color: AppColors.gray900,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList()
                                  : _selectedKeywords
                                        .map(
                                          (keyword) => Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8.0.h,
                                            ),
                                            child: Row(
                                              spacing: 12.w,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(2.r),
                                                  width: 20.w,
                                                  height: 20.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    color: AppColors.gray100,
                                                  ),
                                                  child: SvgPicture.asset(
                                                    'assets/icons/minus.svg',
                                                    width: 20.w,
                                                    color: AppColors.gray600,
                                                  ),
                                                ),
                                                Text(
                                                  keyword,
                                                  style: AppTypography.body1
                                                      .copyWith(
                                                        color:
                                                            AppColors.gray900,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                            ),
                          ),
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
