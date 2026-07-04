import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/data/mock_program_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/section_header.dart';

class ProgramDetailScreen extends StatefulWidget {
  final ProgramModel program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  bool isBookmark = false;
  final PageController _posterController = PageController();
  int _currentPosterIndex = 0;
  @override
  void dispose() {
    _posterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final recommendedPrograms = mockPrograms
        .where((program) => program.isSpotlight)
        .take(8)
        .toList();

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
                    Text(program.title, style: AppTypography.title1),
                    SizedBox(height: 10.h),
                    Text(
                      program.locationName,
                      style: AppTypography.button2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    Text(
                      program.startEndDates,
                      style: AppTypography.button2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: program.keywords
                          .take(3)
                          .map(
                            (keyword) => Label(
                              labelType: LabelType.keyword,
                              text: keyword,
                            ),
                          )
                          .toList(),
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
                          itemCount: program.images.isEmpty
                              ? 1
                              : program.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPosterIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return program.images.isEmpty
                                ? const ColoredBox(color: Color(0xff9DB6BE))
                                : program.images[index];
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          program.images.isEmpty ? 1 : program.images.length,
                          (index) {
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
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Text(
                      program.oneLineDescription,
                      style: AppTypography.title4.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      program.detail,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Column(
                      spacing: 10.h,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70.w,
                              padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                              child: Text(
                                "위치",
                                style: AppTypography.button2.copyWith(
                                  color: AppColors.gray900,
                                ),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      program.locationName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/location-filled.svg',
                                          width: 16.w,
                                          color: AppColors.gray400,
                                        ),
                                        SizedBox(width: 2.w),
                                        Expanded(
                                          child: Text(
                                            program.location['address'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.body3.copyWith(
                                              color: AppColors.gray400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        ProgramDescription(
                          title: '기간',
                          body: program.startEndDates,
                        ),
                        ProgramDescription(
                          title: '시간',
                          body: program.availableTime,
                        ),
                        ProgramDescription(title: '가격', body: program.cost),
                        ProgramDescription(
                          title: '사전예약',
                          body: program.isReservationNeeded ? '필요' : '불필요',
                        ),
                        ProgramDescription(
                          title: '관련정보',
                          body: program.phoneNumber,
                        ),
                        ProgramDescription(title: '링크', body: program.link),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.radius_8,
                        ),
                        color: AppColors.white,
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
                    SectionHeader1(
                      text: '지금 주목받는',
                      buttonName: '',
                      onButtonTap: () {},
                    ),
                    SizedBox(height: 8.h),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) =>
                          HorizontalCard(program: recommendedPrograms[index]),
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12.h),
                      itemCount: recommendedPrograms.length,
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
