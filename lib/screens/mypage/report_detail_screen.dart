import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';
import 'package:muntum/services/suggestion_service.dart';
import 'package:muntum/utils/app_toast.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;
  final bool managerMode;
  final bool deletedMode;

  const ReportDetailScreen({
    super.key,
    required this.report,
    this.managerMode = false,
    this.deletedMode = false,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _service = SuggestionService();
  bool _isProcessing = false;

  ReportModel get report => widget.report;

  Future<void> _registerProgram() async {
    if (_isProcessing) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramEditScreen(initialReport: report),
      ),
    );
    if (!mounted || created != true) return;

    setState(() => _isProcessing = true);
    try {
      await _service.updateSuggestionStatus(id: report.id, status: 'APPROVED');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showAppToast(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (_isProcessing) return;
    await showPopupWidget(
      context: context,
      title: '제보를 삭제할까요?',
      description: '삭제해도 등록된 프로그램은 그대로 유지돼요.',
      text1: '취소',
      text2: '삭제',
      text2Color: AppColors.error,
      onText1Tap: () => Navigator.pop(context),
      onText2Tap: () {
        Navigator.pop(context);
        _deleteReport();
      },
    );
  }

  Future<void> _deleteReport() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _service.deleteSuggestion(report.id);
      if (!mounted) return;
      showAppToast(context, '제보가 삭제되었습니다.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showAppToast(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeName = report.place.name.trim();
    final placeAddress = report.place.address.trim();
    final displayPlaceName = placeName.isNotEmpty ? placeName : placeAddress;
    final displayAddress = placeAddress != displayPlaceName ? placeAddress : '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '제보 내용',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
            trailing: widget.managerMode && !widget.deletedMode
                ? GestureDetector(
                    onTap: _confirmDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        '삭제',
                        style: AppTypography.button3.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportDetailSection(
                    title: '프로그램 명',
                    body: report.programName,
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    '주소',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    displayPlaceName,
                    style: AppTypography.body3.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  if (displayAddress.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: SvgPicture.asset(
                            'assets/icons/location-filled.svg',
                            width: 16.w,
                            colorFilter: const ColorFilter.mode(
                              AppColors.gray400,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            displayAddress,
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 32.h),
                  _ReportDetailSection(title: '제보이유', body: report.reason),
                ],
              ),
            ),
          ),
          if (widget.managerMode && !widget.deletedMode)
            SafeArea(
              top: false,
              minimum: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
              child: ButtonSolid(
                text: report.status == 'APPROVED'
                    ? '이미 등록된 제보예요'
                    : _isProcessing
                    ? '처리 중...'
                    : '등록하기',
                boxColor: report.status == 'APPROVED'
                    ? AppColors.gray100
                    : AppColors.black,
                textColor: report.status == 'APPROVED'
                    ? AppColors.gray400
                    : AppColors.white,
                onTap: report.status == 'PENDING' && !_isProcessing
                    ? _registerProgram
                    : null,
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportDetailSection extends StatelessWidget {
  final String title;
  final String body;

  const _ReportDetailSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.caption2.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 14.h),
        Text(
          body,
          style: AppTypography.body3.copyWith(color: AppColors.gray900),
        ),
      ],
    );
  }
}
