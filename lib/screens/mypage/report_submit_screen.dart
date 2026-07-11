import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/components/report_form_field.dart';
import 'package:muntum/screens/mypage/report_complete_screen.dart';
import 'package:muntum/screens/mypage/report_place_search_screen.dart';
import 'package:muntum/services/suggestion_service.dart';
import 'package:muntum/utils/app_toast.dart';

class ReportSubmitScreen extends StatefulWidget {
  const ReportSubmitScreen({super.key});

  @override
  State<ReportSubmitScreen> createState() => _ReportSubmitScreenState();
}

class _ReportSubmitScreenState extends State<ReportSubmitScreen> {
  final TextEditingController _programNameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  ReportPlace? _selectedPlace;
  bool _submitted = false;

  @override
  void dispose() {
    _programNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _hasProgramName => _programNameController.text.trim().isNotEmpty;
  bool get _hasReason => _reasonController.text.trim().isNotEmpty;
  bool get _hasPlace => _selectedPlace != null;
  bool get _canSubmit => _hasProgramName && _hasReason && _hasPlace;

  Future<void> _selectPlace() async {
    final place = await Navigator.push<ReportPlace>(
      context,
      MaterialPageRoute(builder: (context) => const ReportPlaceSearchScreen()),
    );
    if (place == null) return;
    setState(() {
      _selectedPlace = place;
    });
  }

  void _submit() {
    setState(() {
      _submitted = true;
    });
    if (!_canSubmit) return;

    _createSuggestion();
  }

  Future<void> _createSuggestion() async {
    try {
      final submittedReport = ReportModel(
        id: 'report_${DateTime.now().microsecondsSinceEpoch}',
        programName: _programNameController.text.trim(),
        reason: _reasonController.text.trim(),
        place: _selectedPlace!,
        createdAt: DateTime.now(),
      );

      await SuggestionService().createSuggestion(
        programName: submittedReport.programName,
        address: _selectedPlace!.address,
        reason: submittedReport.reason,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReportCompleteScreen(report: submittedReport),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '제보하기',
            leadingIcon: 'close.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportFormField(
                    label: '프로그램명',
                    hintText: '프로그램명 입력',
                    controller: _programNameController,
                    errorText: _submitted && !_hasProgramName
                        ? '프로그램명을 입력해주세요.'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 24.h),
                  ReportFormField(
                    label: '제보하는 이유',
                    hintText: '이 프로그램을 추천하는 이유를 알려주세요.',
                    controller: _reasonController,
                    maxLines: 5,
                    errorText: _submitted && !_hasReason ? '내용을 입력해주세요.' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 24.h),
                  ReportFormField(
                    label: '장소/위치',
                    hintText: '장소를 검색해주세요.',
                    value: _selectedPlace?.name,
                    readOnly: true,
                    onTap: _selectPlace,
                    showChevron: true,
                    errorText: _submitted && !_hasPlace ? '장소를 선택해주세요.' : null,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 34.h),
            child: Column(
              children: [
                Text(
                  '✨작은 발견이 누군가의 특별한 경험이 돼요',
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                SizedBox(height: 12.h),
                ButtonSolid(
                  text: '제보하기',
                  textColor: AppColors.white,
                  boxColor: AppColors.black,
                  onTap: _submit,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
