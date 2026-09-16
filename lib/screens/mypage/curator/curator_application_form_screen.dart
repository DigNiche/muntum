import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/curator/components/curation_writing_guide_bottom_sheet.dart';
import 'package:muntum/screens/mypage/curator/curator_application_complete_screen.dart';

class CuratorApplicationFormScreen extends StatefulWidget {
  const CuratorApplicationFormScreen({super.key});

  @override
  State<CuratorApplicationFormScreen> createState() =>
      _CuratorApplicationFormScreenState();
}

class _CuratorApplicationFormScreenState
    extends State<CuratorApplicationFormScreen> {
  final _programNameController = TextEditingController();
  final _summaryController = TextEditingController();
  final _introductionController = TextEditingController();

  @override
  void dispose() {
    _programNameController.dispose();
    _summaryController.dispose();
    _introductionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '큐레이터 지원',
            leadingIcon: 'close.svg',
            onLeadingTap: () => Navigator.pop(context),
            trailing: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showCurationWritingGuideBottomSheet(context),
              child: Text(
                '💡가이드',
                style: AppTypography.button3.copyWith(color: AppColors.gray900),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ApplicationNotice(),
                  SizedBox(height: 32.h),
                  _ApplicationTextField(
                    label: '프로그램명',
                    hintText: '프로그램명을 입력해주세요.',
                    controller: _programNameController,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 40.h),
                  _ApplicationTextField(
                    label: '한줄소개',
                    hintText: '이 프로그램의 핵심을 한 문장으로 요약해 주세요.',
                    controller: _summaryController,
                    height: 136.h,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                  SizedBox(height: 40.h),
                  _ApplicationTextField(
                    label: '소개글',
                    hintText:
                        '이 프로그램에 마음이 간 이유, 추천 대상, 관람 팁 등을 작성자님의 솔직한 문장으로 자유롭게 적어주세요.',
                    controller: _introductionController,
                    height: 180.h,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                ],
              ),
            ),
          ),
          if (keyboardHeight == 0) const _ApplicationFooter(),
        ],
      ),
    );
  }
}

class _ApplicationNotice extends StatelessWidget {
  const _ApplicationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.backgroundNormal,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '큐레이터가 된다면 소개하고 싶은 프로그램 내용을 작성해주세요! 문틈팀의 확인 후 큐레이터 권한이 부여됩니다.',
            style: AppTypography.body3.copyWith(color: AppColors.gray800),
          ),
          SizedBox(height: 6.h),
          Tooltip(
            message: 'AI가 생성한 정형화된 글이나 단순 정보 복사글은\n큐레이터 승인이 어려울 수 있습니다.',
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 4),
            preferBelow: true,
            verticalOffset: 12.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.gray800,
              borderRadius: BorderRadius.circular(6.r),
            ),
            textStyle: AppTypography.caption1.copyWith(color: AppColors.white),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help, size: 16.r, color: AppColors.gray400),
                SizedBox(width: 4.w),
                Text(
                  '유의사항',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationTextField extends StatelessWidget {
  const _ApplicationTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.textInputAction,
    this.height,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final double? height;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      maxLines: maxLines,
      expands: height != null,
      textAlignVertical: TextAlignVertical.top,
      textInputAction: textInputAction,
      style: AppTypography.body1.copyWith(color: AppColors.gray900),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.body1.copyWith(color: AppColors.gray400),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        enabledBorder: _border(AppColors.lineStrong),
        focusedBorder: _border(AppColors.gray900),
        border: _border(AppColors.lineStrong),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.button3.copyWith(color: AppColors.gray700),
        ),
        SizedBox(height: 8.h),
        if (height == null) field else SizedBox(height: height, child: field),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color, width: 1.w),
    );
  }
}

class _ApplicationFooter extends StatelessWidget {
  const _ApplicationFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        20.w,
        10.h,
        20.w,
        MediaQuery.paddingOf(context).bottom + 16.h,
      ),
      child: Column(
        children: [
          Text(
            '제출 후 수정이 어려우니, 신중하게 제출해주세요.',
            style: AppTypography.caption1.copyWith(color: AppColors.gray800),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ButtonSolid(
              text: '작성 완료',
              textColor: AppColors.white,
              boxColor: AppColors.black,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CuratorApplicationCompleteScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
