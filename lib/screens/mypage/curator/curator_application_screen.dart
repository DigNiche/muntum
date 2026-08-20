import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/curator/components/curation_writing_guide_bottom_sheet.dart';

class CuratorApplicationScreen extends StatelessWidget {
  const CuratorApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 48.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _IntroductionSection(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 56.h),
                              const _DescriptionSection(
                                title: '큐레이터 역할',
                                description:
                                    '문틈 큐레이터는 단순 정보 전달을 넘어, 실질적인 경험과 솔직한 추천을 전하는 콘텐츠 에디터입니다. 큐레이터님의 진솔한 관점이 담긴 글을 자유롭게 나누어 주세요.',
                              ),
                              SizedBox(height: 56.h),
                              const _DescriptionSection(
                                title: '활동방식',
                                description:
                                    '지금은 정해진 활동 규칙이 없어요. 관심 있는 프로그램이 생길 때마다 자유롭게 등록해주세요.',
                              ),
                              SizedBox(height: 56.h),
                              const _DescriptionSection(
                                title: '어떻게 지원하나요?',
                                description:
                                    '평소 관심 있던 프로그램 소개글을 예시로 가볍게 작성해 제출해 주세요. 승인 후 바로 큐레이팅 활동을 시작하실 수 있어요.',
                              ),
                              SizedBox(height: 12.h),
                              const _ApplicationGuideCard(),
                              SizedBox(height: 56.h),
                              Text(
                                '큐레이터만의 혜택',
                                style: AppTypography.title3.copyWith(
                                  color: AppColors.gray900,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              const _BenefitItem(
                                title: '나만의 큐레이션 포트폴리오',
                                description:
                                    "내가 애정하는 공간과 프로그램을 자신만의 시선으로 기록하고, 프로필에 차곡차곡 쌓아 나만의 '취향 포트폴리오'로 활용할 수 있어요.",
                              ),
                              SizedBox(height: 12.h),
                              const _BenefitItem(
                                title: '초기 멤버 전용 혜택 제공 예정',
                                description:
                                    '추후 우수 큐레이션 선정 및 리워드 제도가 도입될 경우, 초기부터 꾸준히 활동해 주신 1기 큐레이터분들에게 우선적으로 혜택을 드릴 예정입니다.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      SizedBox(height: 50.h),
                      AppBarWidget(
                        centerType: AppBarCenterType.none,
                        leadingIcon: 'arrow_left.svg',
                        onLeadingTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.white,
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
    );
  }
}

class _IntroductionSection extends StatelessWidget {
  const _IntroductionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary50, AppColors.white, AppColors.white],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 146.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                Text(
                  '누구나 쉽게,\n문틈 큐레이터 시작하기',
                  textAlign: TextAlign.center,
                  style: AppTypography.display.copyWith(color: AppColors.black),
                ),
                SizedBox(height: 20.h),
                Text(
                  '문화 생활을 사랑하는 마음만 있다면\n누구나 큐레이터가 될 수 있어요.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body1.copyWith(color: AppColors.gray900),
                ),
                SizedBox(height: 32.h),
                const _CuratorIntroductionLottie(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CuratorIntroductionLottie extends StatefulWidget {
  const _CuratorIntroductionLottie();

  @override
  State<_CuratorIntroductionLottie> createState() =>
      _CuratorIntroductionLottieState();
}

class _CuratorIntroductionLottieState extends State<_CuratorIntroductionLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/curator_apply_introduce.lottie',
      width: 240.r,
      height: 240.r,
      fit: BoxFit.contain,
      controller: _controller,
      repeat: false,
      onLoaded: (composition) {
        if (_hasStarted) return;
        _hasStarted = true;
        _controller.duration = Duration(
          microseconds: composition.duration.inMicroseconds ~/ 2,
        );
        _controller.forward(from: 0);
      },
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
          style: AppTypography.title3.copyWith(color: AppColors.black),
        ),
        SizedBox(height: 12.h),
        Text(
          description,
          style: AppTypography.body1.copyWith(color: AppColors.gray700),
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundNormal,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 지원 부담은 낮게, 참여는 자유롭게!',
            style: AppTypography.headline1.copyWith(color: AppColors.black),
          ),
          SizedBox(height: 10.h),
          Text(
            '작성 가이드는 준비되어 있어 누구나 쉽게 도전할 수 있습니다. 별도의 복잡한 자격 조건 없이, 나만의 솔직한 문장으로 문틈 큐레이터 신청해 보세요.',
            style: AppTypography.body3.copyWith(color: AppColors.gray800),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showCurationWritingGuideBottomSheet(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 11.h, 20.w, 10.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.gray200),
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
        Text(
          '✔️ $title',
          style: AppTypography.headline1.copyWith(color: AppColors.black),
        ),
        SizedBox(height: 8.h),
        Text(
          description,
          style: AppTypography.body1.copyWith(color: AppColors.gray800),
        ),
      ],
    );
  }
}
