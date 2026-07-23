import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/action_bottom_sheet.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/pre_update.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/report_submit_screen.dart';
import 'package:muntum/screens/program_detail/components/program_attendance_prompt.dart';
import 'package:muntum/screens/program_detail/components/program_detail_app_bar.dart';
import 'package:muntum/screens/program_detail/components/program_detail_markdown_body.dart';
import 'package:muntum/screens/program_detail/components/program_header.dart';
import 'package:muntum/screens/program_detail/components/program_information_section.dart';
import 'package:muntum/screens/program_detail/components/program_poster_carousel.dart';
import 'package:muntum/screens/program_detail/components/recommended_programs_section.dart';
import 'package:muntum/screens/program_detail/components/report_container.dart';
import 'package:muntum/services/analytics_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgramDetailScreen extends StatefulWidget {
  final ProgramModel program;
  final String entrySource;

  const ProgramDetailScreen({
    super.key,
    required this.program,
    this.entrySource = 'unknown',
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  late Future<ProgramModel> _programFuture;
  late Future<List<ProgramModel>> _recommendedFuture;

  @override
  void initState() {
    super.initState();
    unawaited(
      AnalyticsService.instance.logProgramDetailView(
        program: widget.program,
        entrySource: widget.entrySource,
      ),
    );
    unawaited(
      AnalyticsService.instance.logScreenView(
        screenName: 'program_detail',
        screenClass: 'ProgramDetailScreen',
      ),
    );
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
              ProgramDetailAppBar(
                program: program,
                entrySource: widget.entrySource,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.h),
                        ProgramHeader(program: program),
                        SizedBox(height: 16.h),
                        Center(
                          child: ProgramPosterCarousel(images: program.images),
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
                            _launchExternalUrl(
                              program,
                              href,
                              linkType: 'markdown_link',
                            );
                          },
                        ),
                        SizedBox(height: 40.h),
                        ProgramInformationSection(
                          program: program,
                          onTapContact: (value) =>
                              _launchRelatedInfo(program, value),
                          onTapWebsite: program.link.isEmpty
                              ? null
                              : () => _launchExternalUrl(
                                  program,
                                  program.link,
                                  linkType: 'website',
                                ),
                        ),
                        SizedBox(height: 40.h),
                        // TODO: 방문 기록 기능이 준비되면 노출한다.
                        if (isReadyForPublish)
                          Padding(
                            padding: EdgeInsets.only(bottom: 40.h),
                            child: const ProgramAttendancePrompt(),
                          ),
                        RecommendedProgramsSection(
                          programsFuture: _recommendedFuture,
                        ),
                        SizedBox(height: 40.h),
                        ReportContainer(
                          openReportBottomSheet: _openReportBottomSheet,
                        ),
                        SizedBox(height: 134.h),
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

  Future<void> _launchExternalUrl(
    ProgramModel program,
    String rawUrl, {
    required String linkType,
  }) async {
    final normalized =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
        ? rawUrl
        : 'https://$rawUrl';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    await AnalyticsService.instance.logExternalLinkClick(
      program: program,
      entrySource: widget.entrySource,
      linkType: linkType,
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(ProgramModel program, String phoneNumber) async {
    final normalized = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.isEmpty) return;
    await AnalyticsService.instance.logExternalLinkClick(
      program: program,
      entrySource: widget.entrySource,
      linkType: 'phone',
    );
    await launchUrl(
      Uri(scheme: 'tel', path: normalized),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _launchEmail(ProgramModel program, String email) async {
    final normalized = _extractEmail(email);
    if (normalized == null) return;

    await AnalyticsService.instance.logExternalLinkClick(
      program: program,
      entrySource: widget.entrySource,
      linkType: 'email',
    );
    final uri = Uri(scheme: 'mailto', path: normalized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchRelatedInfo(ProgramModel program, String value) async {
    if (_extractEmail(value) != null) {
      await _launchEmail(program, value);
      return;
    }
    await _launchPhone(program, value);
  }

  String? _extractEmail(String value) {
    final match = RegExp(
      r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).firstMatch(value.trim());
    return match?.group(0);
  }
}
