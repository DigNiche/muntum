import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

Future<void> showCurationWritingGuideBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.black.withValues(alpha: 0.3),
    builder: (context) => const _CurationWritingGuideBottomSheet(),
  );
}

class _CurationWritingGuideBottomSheet extends StatelessWidget {
  const _CurationWritingGuideBottomSheet();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 48.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Text(
                '💡 큐레이션글 작성 가이드',
                style: AppTypography.title3.copyWith(color: AppColors.gray900),
              ),
              SizedBox(height: 32.h),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: const Column(
                    children: [
                      _GuideSection(
                        number: 1,
                        title: '프로그램명',
                        description: '정식 명칭을 적어주세요.',
                        example: '예: 2026년 한국 근대 거장전 [유영국: 산은 내 안에 있다]',
                      ),
                      _GuideSection(
                        number: 2,
                        title: '한줄소개',
                        description:
                            '읽는 사람이 한눈에 파악할 수 있도록 이 프로그램의 핵심을 한 문장으로 요약해 주세요.',
                        example: '예: 산을 품은 화가, 유영국의 가장 큰 회고전',
                      ),
                      _GuideSection(
                        number: 3,
                        title: '소개글',
                        description:
                            '나만의 솔직한 시선과 경험을 담아 작성해 주세요.\n(떠오른 생각이나 관람 팁도 좋아요)',
                        example:
                            '예: 변하지 않는 자신만의 기준을 지킨다는 것. 그것이 얼마나 단단하고도 고독한 일인지, 이번 전시는 색과 선을 통해 조용히 보여준다. 잠시 걸음을 멈추고 한 화가가 평생 품어온 산을 들여다보는 시간, 한 번쯤 가져볼 만하다.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ButtonSolid(
                  text: '확인',
                  textColor: AppColors.white,
                  boxColor: AppColors.black,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.number,
    required this.title,
    required this.description,
    required this.example,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String description;
  final String example;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 12.h : 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22.r,
                height: 22.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gray900,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '$number',
                  style: AppTypography.button3.copyWith(color: AppColors.white),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: AppTypography.button2.copyWith(color: AppColors.black),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: AppTypography.body3.copyWith(color: AppColors.gray800),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.backgroundNormal,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              example,
              style: AppTypography.caption1.copyWith(color: AppColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}
