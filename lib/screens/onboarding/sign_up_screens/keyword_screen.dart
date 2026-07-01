import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/keyword_chip.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/loading_screen.dart';

class KeywordScreen extends StatefulWidget {
  const KeywordScreen({super.key});

  @override
  State<KeywordScreen> createState() => _KeywordScreenState();
}

class _KeywordScreenState extends State<KeywordScreen> {
  static const int _minimumSelectionCount = 3;
  static const int _maximumSelectionCount = 30;

  static const List<String> _keywords = [
    '가만히 못 있는 편',
    '사색하고 생각하는',
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

  final Set<String> _selectedKeywords = {};

  bool get _canContinue => _selectedKeywords.length >= _minimumSelectionCount;

  double get _progressRatio =>
      (_selectedKeywords.length / _maximumSelectionCount).clamp(0.0, 1.0);

  void _toggleKeyword(String keyword) {
    setState(() {
      if (!_selectedKeywords.add(keyword)) {
        _selectedKeywords.remove(keyword);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.none,
              leadingIcon: 'arrow_left.svg',
              leadingColor: AppColors.gray200,
              onLeadingTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 32.h),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '어떤 문화를 즐기시나요?',
                      style: AppTypography.display.copyWith(
                        color: AppColors.gray200,
                      ),
                    ),
                    SizedBox(height: 13.h),
                    Text(
                      '3개 이상의 취향 키워드를 선택해 주세요.\n'
                      '많이 선택할 수록 다양한 추천을 받을 수 있어요.',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.gray200,
                      ),
                    ),
                    SizedBox(height: 13.h),
                    Row(
                      spacing: 14.w,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              height: 2.h,
                              color: AppColors.gray700,
                              alignment: Alignment.centerLeft,
                              child: AnimatedFractionallySizedBox(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                widthFactor: _progressRatio,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 2.h,
                                  color: AppColors.primary600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text:
                                '${_selectedKeywords.length}', // Default base text
                            style: AppTypography.caption2.copyWith(
                              color: _selectedKeywords.isNotEmpty
                                  ? AppColors.primary600
                                  : AppColors.gray500,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '/$_maximumSelectionCount',
                                style: AppTypography.caption2.copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8.w,
                            runSpacing: 10.h,
                            children: _keywords.map((keyword) {
                              final isSelected = _selectedKeywords.contains(
                                keyword,
                              );
                              return GestureDetector(
                                onTap: () => _toggleKeyword(keyword),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.transparent
                                        : AppColors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary400
                                          : Colors.transparent,
                                      width: 1.w,
                                    ),
                                  ),
                                  child: KeywordChip(
                                    text: keyword,
                                    textColor: isSelected
                                        ? AppColors.primary400
                                        : AppColors.gray400,
                                    outlineColor: Colors.transparent,
                                    boxColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 8.h,
                                    ),
                                    textStyle: AppTypography.caption2,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 48.h),
              child: ButtonSolid(
                text: '다음으로',
                textColor: _canContinue ? AppColors.gray900 : AppColors.gray600,
                boxColor: _canContinue
                    ? AppColors.primary400
                    : AppColors.gray800,
                onTap: () {
                  if (_canContinue) {
                    pushToScreen(context, LoadingScreen());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
