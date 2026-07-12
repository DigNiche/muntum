import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/services/keyword_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/user_preference_store.dart';
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
  List<String> _allKeywords = const [];
  final Set<String> _savedKeywords = {};
  final Set<String> _selectedKeywords = {};

  bool get _hasChanges => !_isSameKeywords(_savedKeywords, _selectedKeywords);
  bool get _canSave =>
      isEdit && _hasChanges && _selectedKeywords.length >= 3 && !_isSaving;

  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }

  Future<void> _loadKeywords() async {
    setState(() => _isLoading = true);
    try {
      final allResult = await KeywordService().fetchTaggedKeywords();
      final selectedResult = await TasteService().fetchMyKeywords();
      final all = allResult.map((keyword) => keyword.name).toList();
      final selected = selectedResult.selectedKeywords
          .map((keyword) => keyword.name)
          .toList();
      UserPreferenceStore.instance.updateKeywords(selected);
      if (!mounted) return;
      setState(() {
        _allKeywords = all;
        _savedKeywords
          ..clear()
          ..addAll(selected);
        _selectedKeywords
          ..clear()
          ..addAll(selected);
      });
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error');
      setState(() {
        _allKeywords = const [];
        _selectedKeywords
          ..clear()
          ..addAll(UserPreferenceStore.instance.selectedKeywords);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEditOrSave() async {
    if (!isEdit) {
      setState(() {
        isEdit = true;
      });
      return;
    }

    if (_isSaving) return;
    if (!_hasChanges) return;
    if (_selectedKeywords.length < 3) {
      showAppToast(context, '키워드를 3개 이상 선택해주세요.');
      return;
    }

    await _saveAndExitEdit();
  }

  Future<void> _saveAndExitEdit() async {
    setState(() => _isSaving = true);
    try {
      await TasteService().saveMyKeywords(_selectedKeywords.toList());
      UserPreferenceStore.instance.updateKeywords(_selectedKeywords);
      if (!mounted) return;
      setState(() {
        _savedKeywords
          ..clear()
          ..addAll(_selectedKeywords);
        isEdit = false;
      });
      showAppToast(context, '저장되었습니다');
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleKeyword(String keyword) {
    setState(() {
      if (!_selectedKeywords.add(keyword)) {
        _selectedKeywords.remove(keyword);
      }
    });
  }

  Future<void> _handleLeadingTap() async {
    if (!isEdit) {
      Navigator.pop(context);
      return;
    }

    if (!_hasChanges) {
      setState(() => isEdit = false);
      return;
    }

    await showPopupWidget(
      context: context,
      title: '변경사항을 저장할까요?',
      description: '저장하지 않으면 변경사항이 반영되지 않아요',
      text1: '나가기',
      text2: '저장하기',
      onText1Tap: () {
        Navigator.pop(context);
        setState(() {
          _selectedKeywords
            ..clear()
            ..addAll(_savedKeywords);
          isEdit = false;
        });
      },
      onText2Tap: () async {
        if (_selectedKeywords.length < 3) {
          Navigator.pop(context);
          showAppToast(context, '키워드를 3개 이상 선택해주세요.');
          return;
        }
        Navigator.pop(context);
        await _saveAndExitEdit();
      },
    );
  }

  Future<void> _confirmDeleteKeyword(String keyword) async {
    await showPopupWidget(
      context: context,
      title: "'$keyword'\n키워드를 삭제할까요?",
      description: '',
      text1: '취소',
      text2: '삭제하기',
      text2Color: AppColors.error,
      onText1Tap: () => Navigator.pop(context),
      onText2Tap: () async {
        Navigator.pop(context);
        if (_selectedKeywords.length <= 3) {
          showAppToast(context, '키워드를 3개 이상 선택해주세요.');
          return;
        }
        await _deleteKeyword(keyword);
      },
    );
  }

  Future<void> _deleteKeyword(String keyword) async {
    final previousSelected = Set<String>.from(_selectedKeywords);
    setState(() {
      _selectedKeywords.remove(keyword);
      _savedKeywords.remove(keyword);
      _isSaving = true;
    });

    try {
      await TasteService().saveMyKeywords(_selectedKeywords.toList());
      UserPreferenceStore.instance.updateKeywords(_selectedKeywords);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _selectedKeywords
          ..clear()
          ..addAll(previousSelected);
        _savedKeywords
          ..clear()
          ..addAll(previousSelected);
      });
      showAppToast(context, '$error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isSameKeywords(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.every(b.contains);
  }

  Color get _trailingTextColor {
    if (!isEdit) return AppColors.gray900;
    return _canSave ? AppColors.gray900 : AppColors.gray500;
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
            onLeadingTap: _handleLeadingTap,
            trailing: GestureDetector(
              onTap: _toggleEditOrSave,
              child: Text(
                _isSaving
                    ? '저장 중...'
                    : isEdit
                    ? '저장'
                    : '편집',
                style: AppTypography.button2.copyWith(
                  color: _trailingTextColor,
                ),
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
                                            GestureDetector(
                                              onTap: () =>
                                                  _toggleKeyword(keyword),
                                              child: Container(
                                                width: 20.w,
                                                height: 20.h,
                                                padding: EdgeInsets.all(2.r),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  color: isSelected
                                                      ? AppColors.gray900
                                                      : AppColors.gray100,
                                                ),
                                                child: SvgPicture.asset(
                                                  isSelected
                                                      ? 'assets/icons/check.svg'
                                                      : 'assets/icons/plus.svg',
                                                  width: 20.w,
                                                  colorFilter: ColorFilter.mode(
                                                    isSelected
                                                        ? AppColors.white
                                                        : AppColors.gray600,
                                                    BlendMode.srcIn,
                                                  ),
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
                                                GestureDetector(
                                                  onTap: () =>
                                                      _confirmDeleteKeyword(
                                                        keyword,
                                                      ),
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      2.r,
                                                    ),
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
                                                      colorFilter:
                                                          const ColorFilter.mode(
                                                            AppColors.gray600,
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
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
                  SizedBox(height: 25.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
