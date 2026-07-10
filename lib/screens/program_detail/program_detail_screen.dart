import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/action_bottom_sheet.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/data/mock_user_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/screens/mypage/report_submit_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/utils/program_scrap.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgramDetailScreen extends StatefulWidget {
  final ProgramModel program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final PageController _posterController = PageController();
  late Future<ProgramModel> _programFuture;
  late Future<List<ProgramModel>> _recommendedFuture;
  int _currentPosterIndex = 0;

  @override
  void initState() {
    super.initState();
    _programFuture = _loadProgram();
    _recommendedFuture = _loadRecommendedPrograms();
  }

  Future<ProgramModel> _loadProgram() async {
    if (widget.program.id.isEmpty) {
      return widget.program;
    }
    try {
      final detail = await ProgramService().fetchProgram(widget.program.id);
      detail.isBookmark = MockBookmarkStore.instance.isBookmarked(
        widget.program,
      );
      return detail;
    } catch (_) {
      return widget.program;
    }
  }

  Future<List<ProgramModel>> _loadRecommendedPrograms() async {
    try {
      return (await ProgramService().fetchHotPrograms(
        size: 3,
      )).content.take(3).toList();
    } catch (_) {
      return const <ProgramModel>[];
    }
  }

  Future<bool> _isLoggedIn() async {
    if (!ApiConfig.hasBaseUrl) {
      return MockUserSession.instance.isLoggedIn;
    }
    final accessToken = TokenStore.instance.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      return true;
    }
    final refreshToken = await TokenStore.instance.readRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<void> _openReportBottomSheet() async {
    final isLoggedIn = await _isLoggedIn();
    if (!mounted) return;
    await showActionBottomSheet(
      context,
      type: isLoggedIn
          ? ActionBottomSheetType.reportSubmit
          : ActionBottomSheetType.reportLogin,
      onPrimaryTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportSubmitScreen()),
        );
      },
    );
  }

  @override
  void dispose() {
    _posterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FutureBuilder<ProgramModel>(
        future: _programFuture,
        initialData: widget.program,
        builder: (context, snapshot) {
          final program = snapshot.data ?? widget.program;
          return Column(
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
                      onTap: () => toggleProgramScrap(context, program),
                      child: ListenableBuilder(
                        listenable: MockBookmarkStore.instance,
                        builder: (context, _) {
                          final isBookmarked = MockBookmarkStore.instance
                              .isBookmarked(program);
                          return SvgPicture.asset(
                            isBookmarked
                                ? 'assets/icons/scrap-filled.svg'
                                : 'assets/icons/scrap.svg',
                            width: 24.w,
                            color: isBookmarked
                                ? AppColors.primary400
                                : const Color(0xff1c1b1f),
                          );
                        },
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
                              program.images.isEmpty
                                  ? 1
                                  : program.images.length,
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
                        MarkdownBody(
                          data: program.detail.isEmpty
                              ? '상세 정보가 준비 중입니다.'
                              : program.detail,
                          selectable: true,
                          onTapLink: (text, href, title) {
                            if (href == null || href.isEmpty) return;
                            _launchExternalUrl(href);
                          },
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: AppTypography.body1.copyWith(
                                  color: AppColors.gray900,
                                ),
                                strong: AppTypography.body1.copyWith(
                                  color: AppColors.gray900,
                                  fontWeight: FontWeight.w700,
                                ),
                                listBullet: AppTypography.body1.copyWith(
                                  color: AppColors.gray900,
                                ),
                                h1: AppTypography.title1.copyWith(
                                  color: AppColors.gray900,
                                ),
                                h2: AppTypography.title3.copyWith(
                                  color: AppColors.gray900,
                                ),
                                h3: AppTypography.title4.copyWith(
                                  color: AppColors.gray900,
                                ),
                                a: AppTypography.body1.copyWith(
                                  color: AppColors.primary600,
                                  decoration: TextDecoration.underline,
                                ),
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
                                  padding: EdgeInsets.only(
                                    top: 4.h,
                                    bottom: 4.h,
                                  ),
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
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      bottom: 4.h,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                program.location['address'] ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.body3
                                                    .copyWith(
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
                              onTap: program.phoneNumber.isEmpty
                                  ? null
                                  : () => _launchPhone(program.phoneNumber),
                            ),
                            ProgramDescription(
                              title: '링크',
                              body: program.link.isEmpty ? '' : '링크',
                              onTap: program.link.isEmpty
                                  ? null
                                  : () => _launchExternalUrl(program.link),
                            ),
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
                          child: GestureDetector(
                            onTap: _openReportBottomSheet,
                            behavior: HitTestBehavior.opaque,
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
                        ),
                        SizedBox(height: 40.h),
                        SectionHeader1(
                          text: '지금 주목받는',
                          buttonName: '',
                          onButtonTap: () {},
                        ),
                        SizedBox(height: 8.h),
                        FutureBuilder<List<ProgramModel>>(
                          future: _recommendedFuture,
                          builder: (context, snapshot) {
                            final recommendedPrograms =
                                snapshot.data ?? const <ProgramModel>[];
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) => HorizontalCard(
                                program: recommendedPrograms[index],
                              ),
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 12.h),
                              itemCount: recommendedPrograms.length,
                            );
                          },
                        ),
                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchExternalUrl(String rawUrl) async {
    final normalized =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
        ? rawUrl
        : 'https://$rawUrl';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final normalized = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: normalized));
  }
}

class ProgramDescription extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  const ProgramDescription({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayBody = body.trim().isEmpty ? '정보 없음' : body.trim();
    final bodyStyle = AppTypography.body1.copyWith(
      color: AppColors.gray900,
      decoration: onTap == null ? null : TextDecoration.underline,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Text(displayBody, style: bodyStyle, softWrap: true),
          ),
        ),
      ],
    );
  }
}
