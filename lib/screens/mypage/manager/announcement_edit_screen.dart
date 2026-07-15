import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/announcement_model.dart';
import 'package:muntum/services/announcement_service.dart';
import 'package:muntum/utils/app_toast.dart';

class AnnouncementEditScreen extends StatefulWidget {
  const AnnouncementEditScreen({super.key, this.announcement});

  final AnnouncementModel? announcement;

  @override
  State<AnnouncementEditScreen> createState() => _AnnouncementEditScreenState();
}

class _AnnouncementEditScreenState extends State<AnnouncementEditScreen> {
  final _service = AnnouncementService();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSaving = false;

  bool get _isCreating => widget.announcement == null;
  bool get _canSubmit =>
      !_isSaving &&
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.announcement?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.announcement?.content ?? '',
    );
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onChanged);
    _contentController.removeListener(_onChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.length > 100) {
      showAppToast(context, '제목은 100자 이하로 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isCreating) {
        await _service.createAnnouncement(title: title, content: content);
      } else {
        await _service.updateAnnouncement(
          id: widget.announcement!.id,
          title: title,
          content: content,
        );
      }
      if (!mounted) return;
      showAppToast(context, _isCreating ? '공지사항이 등록되었습니다.' : '저장되었습니다.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showAppToast(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.text,
              leadingIcon: 'close.svg',
              center: _isCreating ? '공지사항 등록' : '수정',
              onLeadingTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 110.h),
                child: Column(
                  children: [
                    _AnnouncementField(
                      label: '제목',
                      hintText: '제목을 입력하세요.',
                      controller: _titleController,
                    ),
                    SizedBox(height: 28.h),
                    _AnnouncementField(
                      label: '상세 내용',
                      hintText: '내용을 입력하세요.',
                      controller: _contentController,
                      maxLines: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            color: AppColors.white,
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
            child: SizedBox(
              height: 48.h,
              child: ButtonSolid(
                text: _isSaving
                    ? (_isCreating ? '등록 중' : '저장 중')
                    : (_isCreating ? '등록하기' : '수정하기'),
                textColor: _canSubmit ? AppColors.white : AppColors.gray400,
                boxColor: _canSubmit ? AppColors.black : AppColors.gray100,
                padding: EdgeInsets.zero,
                onTap: _canSubmit ? _submit : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementField extends StatelessWidget {
  const _AnnouncementField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.button3.copyWith(color: AppColors.gray700),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines,
          cursorColor: AppColors.gray900,
          style: AppTypography.body1.copyWith(color: AppColors.gray900),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.body1.copyWith(color: AppColors.gray400),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            enabledBorder: _border(AppColors.lineStrong),
            focusedBorder: _border(AppColors.gray400),
          ),
        ),
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
