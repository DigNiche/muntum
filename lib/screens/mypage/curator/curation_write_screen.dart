import 'dart:io';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/common/report_place_search_screen.dart';
import 'package:muntum/screens/mypage/curator/curation_submit_complete_screen.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/utils/app_toast.dart';
import 'package:muntum/utils/image_upload_format.dart';

class CurationWriteScreen extends StatefulWidget {
  const CurationWriteScreen({
    super.key,
    this.service,
    this.programService,
    this.initialCuration,
    this.resubmitAfterUpdate = false,
  });

  final CurationService? service;
  final ProgramService? programService;
  final CurationModel? initialCuration;
  final bool resubmitAfterUpdate;

  @override
  State<CurationWriteScreen> createState() => _CurationWriteScreenState();
}

class _CurationWriteScreenState extends State<CurationWriteScreen> {
  static const int _maxImages = 5;

  late final CurationService _service;
  late final ProgramService _programService;
  String _initialProgramTitle = '';
  final _programController = TextEditingController();
  final _taglineController = TextEditingController();
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<XFile> _images = [];
  final Set<String> _temporaryPaths = {};
  ReportPlace? _place;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialCuration != null;
  int get _imageCount => _images.isNotEmpty
      ? _images.length
      : widget.initialCuration?.images.length ?? 0;
  bool get _hasChanges {
    final initial = widget.initialCuration;
    if (initial == null) return true;
    return _programController.text.trim() != _initialProgramTitle ||
        _place?.name.trim() != initial.place ||
        _taglineController.text.trim() != initial.tagline ||
        _contentController.text.trim() != initial.content ||
        _images.isNotEmpty;
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _programController.text.trim().isNotEmpty &&
      _place != null &&
      _taglineController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      _imageCount > 0 &&
      (!_isEditing || _hasChanges);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CurationService();
    _programService = widget.programService ?? ProgramService();
    final initial = widget.initialCuration;
    if (initial != null) {
      _initialProgramTitle = initial.programTitle;
      _programController.text = _initialProgramTitle;
      _taglineController.text = initial.tagline;
      _contentController.text = initial.content;
      _place = ReportPlace(name: initial.place, address: initial.place);
    }
    for (final controller in [
      _programController,
      _taglineController,
      _contentController,
    ]) {
      controller.addListener(_onChanged);
    }
    if (initial?.programId?.isNotEmpty == true) {
      _loadLinkedProgramTitle(initial!.programId!);
    }
  }

  Future<void> _loadLinkedProgramTitle(String programId) async {
    try {
      final program = await _programService.fetchProgram(programId);
      if (!mounted || program.title.trim().isEmpty) return;
      if (_programController.text.trim() != _initialProgramTitle) return;
      _initialProgramTitle = program.title.trim();
      _programController.text = _initialProgramTitle;
    } catch (_) {
      // Retain the submitted title if the linked program is unavailable.
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final path in _temporaryPaths) {
      File(path).delete().ignore();
    }
    _programController.dispose();
    _taglineController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectPlace() async {
    final place = await Navigator.push<ReportPlace>(
      context,
      MaterialPageRoute(builder: (_) => const ReportPlaceSearchScreen()),
    );
    if (mounted && place != null) setState(() => _place = place);
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;
    final picked = await _imagePicker.pickMultiImage(imageQuality: 88);
    if (!mounted || picked.isEmpty) return;

    final preparedImages = <XFile>[];
    var failed = 0;
    for (final image in picked.take(remaining)) {
      try {
        final prepared = await prepareImageForUpload(image.path);
        if (prepared.isTemporary) _temporaryPaths.add(prepared.path);
        preparedImages.add(XFile(prepared.path));
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() => _images.addAll(preparedImages));
    if (picked.length > remaining) {
      showAppToast(context, '사진은 최대 5장까지 등록할 수 있어요.', isError: true);
    } else if (failed > 0) {
      showAppToast(context, supportedUploadImageMessage, isError: true);
    }
  }

  void _removeImage(int index) {
    final removed = _images.removeAt(index);
    if (_temporaryPaths.remove(removed.path)) {
      File(removed.path).delete().ignore();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      final initial = widget.initialCuration;
      if (initial == null) {
        await _service.submit(
          programTitle: _programController.text.trim(),
          place: _place!.name,
          tagline: _taglineController.text.trim(),
          content: _contentController.text.trim(),
          imagePaths: _images.map((image) => image.path).toList(),
        );
      } else {
        await _service.update(
          id: initial.id,
          programTitle: _programController.text.trim(),
          place: _place!.name,
          tagline: _taglineController.text.trim(),
          content: _contentController.text.trim(),
          imagePaths: _images.map((image) => image.path).toList(),
        );
        if (widget.resubmitAfterUpdate) {
          await _service.resubmit(initial.id);
        }
      }
      if (!mounted) return;
      if (_isEditing) {
        Navigator.pop(context, true);
      } else {
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) => const CurationSubmitCompleteScreen(),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, isError: true);
    } catch (_) {
      if (mounted) showAppToast(context, '글을 등록하지 못했어요.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _attemptClose() async {
    if (!_hasChanges ||
        (!_isEditing &&
            _programController.text.isEmpty &&
            _taglineController.text.isEmpty &&
            _contentController.text.isEmpty &&
            _place == null &&
            _images.isEmpty)) {
      Navigator.pop(context);
      return;
    }
    final leave = await showConfirmationPopupWidget(
      context: context,
      title: '페이지를 나갈까요?',
      description: '작성 중인 내용이 저장되지 않습니다.',
      confirmText: '나가기',
    );
    if (mounted && leave) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _attemptClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(height: 50.h),
              AppBarWidget(
                centerType: AppBarCenterType.text,
                center: _isEditing ? '수정' : '새 글 작성',
                leadingIcon: 'close.svg',
                onLeadingTap: _attemptClose,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
                  children: [
                    _CurationField(
                      label: '프로그램명',
                      controller: _programController,
                      hint: '프로그램명을 입력해주세요.',
                      maxLength: 100,
                    ),
                    SizedBox(height: 24.h),
                    _PlaceField(place: _place, onTap: _selectPlace),
                    SizedBox(height: 24.h),
                    _CurationField(
                      label: '한줄소개',
                      controller: _taglineController,
                      hint: '임팩트 있는 한 줄로 소개해주세요.',
                      maxLength: 255,
                      maxLines: 4,
                      minHeight: 132,
                    ),
                    SizedBox(height: 24.h),
                    _CurationField(
                      label: '소개글',
                      controller: _contentController,
                      hint: '프로그램을 소개해주세요.',
                      maxLines: 7,
                      minHeight: 166,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      '사진',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 104.h,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _AddImageButton(
                            count: _imageCount,
                            onTap: _pickImages,
                          ),
                          if (_images.isEmpty && _isEditing)
                            for (final image
                                in widget.initialCuration!.images) ...[
                              SizedBox(width: 8.w),
                              _ExistingImage(imageUrl: image.imageUrl),
                            ],
                          for (
                            var index = 0;
                            index < _images.length;
                            index++
                          ) ...[
                            SizedBox(width: 8.w),
                            _SelectedImage(
                              image: _images[index],
                              isRepresentative: index == 0,
                              onRemove: () => _removeImage(index),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      height: 48.h,
                      child: ButtonSolid(
                        text: _isSubmitting
                            ? (_isEditing ? '수정 중' : '등록 중')
                            : (_isEditing ? '수정완료' : '작성완료'),
                        textColor: _canSubmit
                            ? AppColors.white
                            : AppColors.gray400,
                        boxColor: _canSubmit
                            ? AppColors.black
                            : AppColors.gray200,
                        padding: EdgeInsets.zero,
                        onTap: _canSubmit ? _submit : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurationField extends StatelessWidget {
  const _CurationField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.minHeight = 54,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption1.copyWith(color: AppColors.gray700),
        ),
        SizedBox(height: 10.h),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight.h),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            style: AppTypography.body2.copyWith(color: AppColors.gray900),
            cursorColor: AppColors.gray900,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: AppTypography.body2.copyWith(color: AppColors.gray400),
              contentPadding: EdgeInsets.all(16.r),
              enabledBorder: _fieldBorder(AppColors.lineStrong),
              focusedBorder: _fieldBorder(AppColors.gray400),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceField extends StatelessWidget {
  const _PlaceField({required this.place, required this.onTap});

  final ReportPlace? place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '장소',
          style: AppTypography.caption1.copyWith(color: AppColors.gray700),
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 54.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lineStrong),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    place?.name ?? '장소를 검색해주세요.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(
                      color: place == null
                          ? AppColors.gray400
                          : AppColors.gray900,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/arrow_right.svg',
                  width: 16.r,
                  height: 16.r,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray400,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76.w,
        decoration: DottedDecoration(
          color: AppColors.gray300,
          borderRadius: BorderRadius.circular(8.r),
          shape: Shape.box,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 24.r, color: AppColors.gray700),
            SizedBox(height: 7.h),
            Text(
              '$count/5',
              style: AppTypography.caption2.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImage extends StatelessWidget {
  const _SelectedImage({
    required this.image,
    required this.isRepresentative,
    required this.onRemove,
  });

  final XFile image;
  final bool isRepresentative;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.file(
            File(image.path),
            width: 76.w,
            height: 104.h,
            fit: BoxFit.cover,
          ),
        ),
        if (isRepresentative)
          Positioned(
            left: 8.w,
            bottom: 8.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.dimStrong,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Text(
                '대표',
                style: AppTypography.caption3.copyWith(color: AppColors.white),
              ),
            ),
          ),
        Positioned(
          right: -4.r,
          top: -4.r,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22.r,
              height: 22.r,
              decoration: const BoxDecoration(
                color: AppColors.gray900,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 14.r, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExistingImage extends StatelessWidget {
  const _ExistingImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.network(
        imageUrl,
        width: 76.w,
        height: 104.h,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 76.w,
          height: 104.h,
          color: AppColors.gray100,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(8.r),
  borderSide: BorderSide(color: color),
);
