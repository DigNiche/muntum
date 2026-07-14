import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/action_bottom_sheet.dart';
import 'package:muntum/components/animated_scrap_icon.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/screens/mypage/report_submit_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
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
      final detail = await ProgramService().fetchProgram(
        widget.program.id,
        authorized: true,
      );
      detail.isBookmark = ProgramScrapStore.instance.isScrapped(detail);
      return detail;
    } catch (_) {
      return widget.program;
    }
  }

  Future<List<ProgramModel>> _loadRecommendedPrograms() async {
    try {
      final currentId = widget.program.id.trim();
      final currentTitle = widget.program.title.trim();
      final programs = (await ProgramService().fetchHotPrograms(size: 10))
          .content
          .where((program) {
            final sameId =
                currentId.isNotEmpty && program.id.trim() == currentId;
            final sameTitle =
                currentTitle.isNotEmpty && program.title.trim() == currentTitle;
            return !sameId && !sameTitle;
          })
          .toList();
      return programs.take(3).toList();
    } catch (_) {
      return const <ProgramModel>[];
    }
  }

  Future<bool> _isLoggedIn() async {
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
                trailing: GestureDetector(
                  onTap: () => toggleProgramScrap(context, program),
                  child: ListenableBuilder(
                    listenable: ProgramScrapStore.instance,
                    builder: (context, _) {
                      final isBookmarked = ProgramScrapStore.instance
                          .isScrapped(program);
                      return AnimatedScrapIcon(
                        isScrapped: isBookmarked,
                        size: 24,
                        activeColor: AppColors.primary400,
                        inactiveColor: const Color(0xff1c1b1f),
                      );
                    },
                  ),
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
                          program.detailDateText,
                          style: AppTypography.button2.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Wrap(
                          spacing: 6.w,
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
                            height: 467.h,
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
                        ProgramDetailMarkdownBody(
                          markdown: program.detail.isEmpty
                              ? '상세 정보가 준비 중입니다.'
                              : program.detail,
                          onTapLink: (href) {
                            if (href.isEmpty) return;
                            _launchExternalUrl(href);
                          },
                        ),
                        SizedBox(height: 40.h),
                        Column(
                          spacing: 6.h,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 1.0.h),
                                  child: Text(
                                    "위치",
                                    style: AppTypography.button2.copyWith(
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 60.w),
                                Expanded(
                                  child: Column(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(top: 2.h),
                                            child: SvgPicture.asset(
                                              'assets/icons/location-filled.svg',
                                              width: 16.w,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    AppColors.gray400,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 2.w),
                                          Expanded(
                                            child: Text(
                                              program.location['address'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.body3
                                                  .copyWith(
                                                    color: AppColors.gray600,
                                                  ),
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
                              body: program.detailDateText,
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
                            ProgramRelatedInfoDescription(
                              title: '관련정보',
                              body: program.phoneNumber,
                              onTapContact: _launchRelatedInfo,
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
                            color: AppColors.backgroundNormal,
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
    await launchUrl(
      Uri(scheme: 'tel', path: normalized),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _launchEmail(String email) async {
    final normalized = _extractEmail(email);
    if (normalized == null) return;

    final uri = Uri(scheme: 'mailto', path: normalized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchRelatedInfo(String value) async {
    if (_extractEmail(value) != null) {
      await _launchEmail(value);
      return;
    }
    await _launchPhone(value);
  }

  String? _extractEmail(String value) {
    final match = RegExp(
      r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).firstMatch(value.trim());
    return match?.group(0);
  }
}

class ProgramDetailMarkdownBody extends StatelessWidget {
  final String markdown;
  final ValueChanged<String> onTapLink;

  const ProgramDetailMarkdownBody({
    super.key,
    required this.markdown,
    required this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedMarkdown = markdown.replaceAll(
      RegExp(r'\n\s*---\s*\n'),
      '\n\n',
    );
    final fixedMarkdown = fixCjkEmphasis(normalizedMarkdown);
    final pointTitleMatch = RegExp(
      r'(^|\n).*프로그램 포인트.*',
      multiLine: true,
    ).firstMatch(fixedMarkdown);
    final styleSheet = _styleSheet(context);

    if (pointTitleMatch == null || pointTitleMatch.start <= 0) {
      return _buildMarkdown(fixedMarkdown, styleSheet);
    }

    final afterStart = fixedMarkdown.codeUnitAt(pointTitleMatch.start) == 10
        ? pointTitleMatch.start + 1
        : pointTitleMatch.start;
    final before = fixedMarkdown.substring(0, afterStart).trimRight();
    final after = fixedMarkdown.substring(afterStart).trimLeft();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (before.isNotEmpty) _buildMarkdown(before, styleSheet),
        SizedBox(height: 28.h),
        _buildMarkdown(after, styleSheet),
      ],
    );
  }

  MarkdownBody _buildMarkdown(String data, MarkdownStyleSheet styleSheet) {
    return MarkdownBody(
      data: data,
      selectable: true,
      onTapLink: (text, href, title) {
        onTapLink(href ?? '');
      },
      styleSheet: styleSheet,
    );
  }

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: AppTypography.body1.copyWith(color: AppColors.gray900),
      strong: AppTypography.body1.copyWith(
        color: AppColors.gray900,
        fontWeight: FontWeight.w700,
      ),
      listBullet: AppTypography.body1.copyWith(color: AppColors.gray900),
      h1: AppTypography.title1.copyWith(color: AppColors.gray900),
      h2: AppTypography.title3.copyWith(color: AppColors.gray900),
      h3: AppTypography.title4.copyWith(color: AppColors.gray900),
      a: AppTypography.body1.copyWith(decoration: TextDecoration.underline),
    );
  }
}

String fixCjkEmphasis(String md) {
  return md
      .replaceAllMapped(
        RegExp(r'([\p{P}\p{S}])\*\*(?=[가-힣])', unicode: true),
        (match) => '${match.group(1)}**\u200B',
      )
      .replaceAllMapped(
        RegExp(r'([가-힣])\*\*([\p{P}\p{S}])', unicode: true),
        (match) => '${match.group(1)}\u200B**${match.group(2)}',
      );
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

class ProgramRelatedInfoDescription extends StatelessWidget {
  final String title;
  final String body;
  final ValueChanged<String> onTapContact;

  const ProgramRelatedInfoDescription({
    super.key,
    required this.title,
    required this.body,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
    final contacts = _splitContacts(body);

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
          child: Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
            child: contacts.isEmpty
                ? Text(
                    '정보 없음',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.gray900,
                    ),
                  )
                : Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: [
                      for (var i = 0; i < contacts.length; i++) ...[
                        GestureDetector(
                          onTap: () => onTapContact(contacts[i]),
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            contacts[i],
                            style: AppTypography.body1.copyWith(
                              color: AppColors.gray900,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        if (i != contacts.length - 1)
                          Text(
                            '/',
                            style: AppTypography.body1.copyWith(
                              color: AppColors.gray900,
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  List<String> _splitContacts(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\s*(?:/|,|;|\n)\s*'))
        .map((contact) => contact.trim())
        .where((contact) => contact.isNotEmpty)
        .toList();
  }
}
