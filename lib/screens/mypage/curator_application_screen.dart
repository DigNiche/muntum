import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class CuratorApplicationScreen extends StatelessWidget {
  const CuratorApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNormal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary50,
              AppColors.backgroundNormal,
              AppColors.backgroundNormal,
            ],
            stops: [0, 0.32, 1],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.none,
              leadingIcon: 'arrow_left.svg',
              onLeadingTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  32.h,
                  20.w,
                  MediaQuery.paddingOf(context).bottom + 24.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '누구나 쉽게,\n문틈 큐레이터 시작하기',
                            textAlign: TextAlign.center,
                            style: AppTypography.display.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            '문화 생활을 사랑하는 마음만 있다면\n누구나 큐레이터가 될 수 있어요.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.gray900,
                            ),
                          ),
                          SizedBox(height: 32.h),
                          SvgPicture.asset(
                            'assets/curator_apply.svg',
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 48.h),
                    const _DescriptionSection(
                      title: '큐레이터 역할',
                      description:
                          '문틈 큐레이터는 단순 정보 전달을 넘어, 실질적인 경험과 솔직한 추천을 전하는 콘텐츠 에디터입니다. 큐레이터님의 진솔한 관점이 담긴 글을 자유롭게 나누어 주세요.',
                    ),
                    SizedBox(height: 40.h),
                    const _DescriptionSection(
                      title: '활동방식',
                      description:
                          '지금은 정해진 활동 규칙이 없어요. 관심 있는 프로그램이 생길 때마다 자유롭게 등록해주세요.',
                    ),
                    SizedBox(height: 40.h),
                    const _DescriptionSection(
                      title: '어떻게 지원하나요?',
                      description:
                          '평소 관심 있던 프로그램 소개글을 예시로 가볍게 작성해 제출해 주세요. 승인 후 바로 큐레이팅 활동을 시작하실 수 있어요.',
                    ),
                    SizedBox(height: 16.h),
                    const _ApplicationGuideCard(),
                    SizedBox(height: 48.h),
                    Text(
                      '큐레이터만의 혜택',
                      style: AppTypography.headline1.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    const _BenefitItem(
                      title: '나만의 큐레이션 포트폴리오',
                      description:
                          "내가 애정하는 공간과 프로그램을 자신만의 시선으로 기록하고, 프로필에 차곡차곡 쌓아 나만의 '취향 포트폴리오'로 활용할 수 있어요.",
                    ),
                    SizedBox(height: 28.h),
                    const _BenefitItem(
                      title: '초기 멤버 전용 혜택 제공 예정',
                      description:
                          '추후 우수 큐레이션 선정 및 리워드 제도가 도입될 경우, 초기부터 꾸준히 활동해 주신 1기 큐레이터분들에게 우선적으로 혜택을 드릴 예정입니다.',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.backgroundNormal,
              padding: EdgeInsets.fromLTRB(
                20.w,
                12.h,
                20.w,
                MediaQuery.paddingOf(context).bottom + 16.h,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ButtonSolid(
                  text: '큐레이터 지원하기',
                  textColor: AppColors.white,
                  boxColor: AppColors.black,
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headline1.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 12.h),
        Text(
          description,
          style: AppTypography.body3.copyWith(color: AppColors.gray700),
        ),
      ],
    );
  }
}

class _ApplicationGuideCard extends StatelessWidget {
  const _ApplicationGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18.r,
                height: 18.r,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '지원 부담은 낮게, 참여는 자유롭게!',
                  style: AppTypography.headline2.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '작성 가이드는 준비되어 있어 누구나 쉽게 도전할 수 있습니다. 별도의 복잡한 자격 조건 없이, 나만의 솔직한 문장으로 문틈 큐레이터 신청해 보세요.',
            style: AppTypography.caption1.copyWith(color: AppColors.gray700),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.lineStrong),
              ),
              child: Text(
                '작성가이드 보기',
                style: AppTypography.button3.copyWith(color: AppColors.gray900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✓',
              style: AppTypography.headline1.copyWith(color: AppColors.gray900),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                title,
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          description,
          style: AppTypography.body3.copyWith(color: AppColors.gray700),
        ),
      ],
    );
  }
}
