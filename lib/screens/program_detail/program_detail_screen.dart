import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/screens/home/components/section_header.dart';

class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  bool isBookmark = false;
  final PageController _posterController = PageController();
  int _currentPosterIndex = 0;
  final List<Color> postColors = [
    Colors.amber,
    Colors.black,
    Colors.yellow,
    Colors.red,
  ];

  @override
  void dispose() {
    _posterController.dispose();
    super.dispose();
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
            centerType: AppBarCenterType.none,
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () {
              Navigator.pop(context);
            },
            trailing: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/share.svg',
                  width: 24.w,
                  color: Color(0xff1c1b1f),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: () {
                    isBookmark = !isBookmark;
                    setState(() {});
                  },
                  child: SvgPicture.asset(
                    isBookmark
                        ? 'assets/icons/scrap-filled.svg'
                        : 'assets/icons/scrap.svg',
                    width: 24.w,
                    color: isBookmark
                        ? AppColors.primary400
                        : Color(0xff1c1b1f),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Text(
                      "겹쳐 보는 순간 A Layered Moment",
                      style: AppTypography.title1,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      '문화역서울 278',
                      style: AppTypography.button2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    Text(
                      "2026.06.01 - 2026.12.12",
                      style: AppTypography.button2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Row(
                      spacing: 10.w,
                      children: [
                        Label(labelType: LabelType.keyword, text: '힐링되는'),
                        Label(labelType: LabelType.keyword, text: '이색적인'),
                        Label(labelType: LabelType.keyword, text: '데이트코스'),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.radius_10,
                      ),
                      child: SizedBox(
                        width: 350.w,
                        height: 350.h,
                        child: PageView.builder(
                          controller: _posterController,
                          itemCount: postColors.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPosterIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return ColoredBox(color: postColors[index]);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(postColors.length, (index) {
                          final isSelected = _currentPosterIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            margin: EdgeInsets.symmetric(horizontal: 3.w),
                            width: 7.w,
                            height: 7.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.gray300,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Text(
                      "같은 출발선에서 시작해 각자의 길을 걸어온 세 작가, 다시 한 공간에서 겹쳐지다",
                      style: AppTypography.title4.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      "전시 포스터를 처음 봤을 때는 살짝 당황했다. 글자가 죄다 겹쳐져 있어 제목조차 한눈에 읽히지 않았기 때문이다. 그런데 전시 제목이 **<겹쳐지는 순간들>**이라는 걸 알고 나니 이해가 되었다. 읽기 힘들도록 의도된 디자인이었던 것이다. 그 순간부터 이 전시가 묘하게 궁금해지기 시작했다.\n전시 소개글을 따라가 보니, 참여한 세 작가는 같은 학교 동창이라고 한다. 한때는 같은 시간표 아래 같은 시간을 보냈지만, 졸업 이후에는 각자의 공간과 속도로 작업을 이어왔다는 것. 이 대목에서 자연스럽게 떠오르는 얼굴들이 있었다. 같은 동네에서 나고 자랐지만 지금은 완전히 다른 삶을 살고 있는 어릴 적 친구들, 같은 과 강의실에 앉아 있었지만 서로 다른 길을 걷고 있는 대학 동기들. 한때 겹쳐졌던 시간이, 각자의 궤적으로 흩어지는 일은 누구에게나 일어나는 일이니까.\n그렇게 흩어졌던 세 사람이, 각자의 세계를 단단히 구축한 채로 다시 한 자리에 모였다. 같은 출발점에서 시작해 어떤 다른 길을 걸어왔을지, 그리고 그 길들이 지금 이 공간에서 어떻게 다시 마주치는지를 상상하며 작품을 둘러보는 것도 이 전시를 즐기는 한 가지 방법이 될 것 같다.\n조각, 사진, 설치미술, 영상이라는 서로 다른 네 가지 매체의 작품을 한 공간에서 동시에 만날 수 있다는 점도 이 전시의 매력이다. 다양한 매체로 표현된 작품들을 따라가다 보면, 서로 다른 시간을 살아온 이들의 흔적이 한 장면 안에서 은근하게 포개지는 순간을 발견하게 될지도 모른다.",
                      style: AppTypography.body1.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Column(
                      spacing: 10.h,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 70.w,
                              height: 50.h,
                              padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                              child: Text(
                                "위치",
                                style: AppTypography.button2.copyWith(
                                  color: AppColors.gray900,
                                ),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            SizedBox(
                              width: 260.w,
                              height: 50.h,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 2.0.h,
                                children: [
                                  Text(
                                    "온양민속박물관",
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                  Row(
                                    spacing: 2.0.w,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/location-filled.svg',
                                        width: 16.w,
                                        color: AppColors.gray400,
                                      ),
                                      Text(
                                        "충남 아산시 충무로 123 온양민속박물관",
                                        style: AppTypography.body3.copyWith(
                                          color: AppColors.gray400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ProgramDescription(
                          title: '기간',
                          body: '2026.02.12 - 2026.12.12',
                        ),
                        ProgramDescription(
                          title: '시간',
                          body: '월-금 11:00~20:00',
                        ),
                        ProgramDescription(title: '가격', body: '10,000원'),
                        ProgramDescription(title: '사전예약', body: '필요'),
                        ProgramDescription(title: '관련정보', body: '02-1234-1234'),
                        ProgramDescription(title: '링크', body: '바로가기'),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.radius_8,
                        ),
                        color: AppColors.backgroundNormal,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "👀아무도 모르는 나만의 장소가 있다면?",
                            style: AppTypography.button3.copyWith(
                              color: AppColors.gray700,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "제보하기",
                                style: AppTypography.button3.copyWith(
                                  color: AppColors.gray900,
                                ),
                              ),
                              SvgPicture.asset(
                                'assets/icons/arrow_outward.svg',
                                width: 20.w,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),
                    SectionHeader1(text: '지금 주목 받는', buttonName: ''),
                    SizedBox(height: 8.h),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) =>
                          HorizontalCard(programName: 'programName'),
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12.h),
                      itemCount: 5,
                    ),
                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgramDescription extends StatelessWidget {
  final String title;
  final String body;
  const ProgramDescription({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70.w,
          padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
          child: Text(
            title,
            style: AppTypography.button2.copyWith(color: AppColors.gray900),
          ),
        ),
        SizedBox(width: 20.w),
        SizedBox(
          width: 260.w,
          child: Text(
            body,
            style: AppTypography.body1.copyWith(color: AppColors.gray900),
          ),
        ),
      ],
    );
  }
}
