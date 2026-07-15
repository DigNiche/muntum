import 'dart:async';
import 'dart:io';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/report_place_search_screen.dart';
import 'package:muntum/services/keyword_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/utils/app_toast.dart';

class ProgramEditScreen extends StatefulWidget {
  const ProgramEditScreen({super.key, this.program, this.initialReport});

  final ProgramModel? program;
  final ReportModel? initialReport;

  @override
  State<ProgramEditScreen> createState() => _ProgramEditScreenState();
}

class _ProgramEditScreenState extends State<ProgramEditScreen> {
  static const _maxImages = 5;

  final _service = ProgramService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _taglineController;
  late final TextEditingController _curationController;
  late final TextEditingController _venueController;
  late final TextEditingController _addressController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _hoursController;
  late final TextEditingController _priceController;
  late final TextEditingController _contactController;
  late final TextEditingController _urlController;
  late final TextEditingController _keywordsController;

  late ProgramType _programType;
  late bool _isReservationNeeded;
  late final List<_ProgramImageItem> _images;
  bool _imagesChanged = false;
  bool _isSaving = false;

  bool get _isCreating => widget.program == null;

  @override
  void initState() {
    super.initState();
    final program = widget.program;
    final initialReport = widget.initialReport;
    _titleController = TextEditingController(
      text: program?.title ?? initialReport?.programName ?? '',
    );
    _taglineController = TextEditingController(
      text: program?.oneLineDescription ?? initialReport?.reason ?? '',
    );
    _curationController = TextEditingController(
      text: program?.detail ?? initialReport?.reason ?? '',
    );
    _venueController = TextEditingController(
      text: program?.locationName ?? initialReport?.place.name ?? '',
    );
    _addressController = TextEditingController(
      text: program?.location['address'] ?? initialReport?.place.address ?? '',
    );
    final storedStartDate = program?.startDate.trim().isNotEmpty == true
        ? program!.startDate
        : _dateOnlyMeta(program?.operatingPeriodMeta ?? '');
    _startDateController = TextEditingController(
      text: _displayDate(storedStartDate),
    );
    _endDateController = TextEditingController(
      text: _displayDate(program?.endDate ?? ''),
    );
    _hoursController = TextEditingController(
      text: program?.availableTime ?? '',
    );
    _priceController = TextEditingController(
      text: program == null
          ? ''
          : program.isFree
          ? '무료'
          : program.cost,
    );
    _contactController = TextEditingController(
      text: program?.phoneNumber ?? '',
    );
    _urlController = TextEditingController(
      text: program?.officialUrl ?? program?.link ?? '',
    );
    _keywordsController = TextEditingController(
      text: program?.keywords.take(3).join(', ') ?? '',
    );
    _programType = program?.programType ?? ProgramType.exhibition;
    _isReservationNeeded = program?.isReservationNeeded ?? false;
    _images = (program?.imageUrls.take(_maxImages) ?? const <String>[])
        .map(_ProgramImageItem.network)
        .toList();
    for (final controller in _formControllers) {
      controller.addListener(_onFormChanged);
    }
  }

  List<TextEditingController> get _formControllers => [
    _titleController,
    _taglineController,
    _curationController,
    _venueController,
    _addressController,
    _startDateController,
    _endDateController,
    _hoursController,
    _priceController,
    _contactController,
    _urlController,
    _keywordsController,
  ];

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    _curationController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _hoursController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    _urlController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  int get _imageCount => _images.length;

  Future<void> _pickImages() async {
    final remaining = _maxImages - _imageCount;
    if (remaining <= 0) {
      showAppToast(context, '사진은 최대 5장까지 업로드할 수 있어요.', isError: true);
      return;
    }
    final selected = await _imagePicker.pickMultiImage(imageQuality: 88);
    if (!mounted || selected.isEmpty) return;
    setState(() {
      _images.addAll(selected.take(remaining).map(_ProgramImageItem.local));
      _imagesChanged = true;
    });
  }

  void _removeImage(int index) {
    if (!_isCreating && _imageCount <= 1) {
      showAppToast(context, '사진을 1장 이상 남겨주세요.');
      return;
    }
    setState(() {
      _images.removeAt(index);
      _imagesChanged = true;
    });
  }

  void _reorderImage(int oldIndex, int newIndex) {
    setState(() {
      final image = _images.removeAt(oldIndex);
      _images.insert(newIndex, image);
      _imagesChanged = true;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      showAppToast(context, validationMessage, isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final temporaryFiles = <File>[];
    try {
      final imagePaths = <String>[];
      if (_isCreating) {
        imagePaths.addAll(_images.map((image) => image.localFile!.path));
      } else if (_imagesChanged) {
        for (var index = 0; index < _images.length; index++) {
          final image = _images[index];
          if (image.localFile != null) {
            imagePaths.add(image.localFile!.path);
          } else {
            final file = await _downloadTemporaryImage(
              image.networkUrl!,
              index,
            );
            temporaryFiles.add(file);
            imagePaths.add(file.path);
          }
        }
      }

      if (_isCreating) {
        await _service.createProgram(
          program: _buildRequest(),
          imagePaths: imagePaths,
        );
      } else {
        await _service.updateProgram(
          id: widget.program!.id,
          program: _buildRequest(),
          imagePaths: imagePaths,
        );
      }
      if (!mounted) return;
      showAppToast(context, _isCreating ? '프로그램이 등록되었습니다.' : '저장되었습니다.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showAppToast(context, '$error');
    } finally {
      for (final file in temporaryFiles) {
        try {
          await file.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validationMessage() {
    if (_imageCount < 1) return '사진을 1장 이상 등록해주세요.';
    if (_titleController.text.trim().isEmpty) return '프로그램명을 입력해주세요.';
    if (_taglineController.text.trim().isEmpty) return '한줄소개를 입력해주세요.';
    if (_curationController.text.trim().isEmpty) return '소개글을 입력해주세요.';
    if (_venueController.text.trim().isEmpty) return '장소명을 입력해주세요.';
    if (_addressController.text.trim().isEmpty) return '주소를 입력해주세요.';
    final startDate = _apiDate(_startDateController.text);
    if (startDate == null) {
      return '시작일을 YYYY.MM.DD 형식으로 입력해주세요.';
    }
    final rawEndDate = _endDateController.text.trim();
    final endDate = rawEndDate.isEmpty ? null : _apiDate(rawEndDate);
    if (rawEndDate.isNotEmpty && endDate == null) {
      return '마감일을 YYYY.MM.DD 형식으로 입력해주세요.';
    }
    if (endDate != null && _isAfter(startDate, endDate)) {
      return '마감일은 시작일보다 빠를 수 없어요.';
    }
    if (_hoursController.text.trim().isEmpty) return '운영시간을 입력해주세요.';
    if (_priceController.text.trim().isEmpty) return '가격을 입력해주세요.';
    final keywords = _keywordNames;
    if (keywords.isEmpty) return '키워드를 선택해주세요.';
    if (keywords.length > 3) return '키워드는 최대 3개까지 입력해주세요.';
    return null;
  }

  bool get _canSubmit => !_isSaving;

  List<String> get _keywordNames => _keywordsController.text
      .split(',')
      .map((keyword) => keyword.trim())
      .where((keyword) => keyword.isNotEmpty)
      .toSet()
      .toList();

  Map<String, dynamic> _buildRequest() {
    final startDate = _apiDate(_startDateController.text)!;
    final endDate = _endDateController.text.trim().isEmpty
        ? null
        : _apiDate(_endDateController.text);
    final request = <String, dynamic>{
      'title': _titleController.text.trim(),
      'programType': _programType.apiValue,
      'tagline': _taglineController.text.trim(),
      'curation': _curationController.text.trim(),
      'reserved': _isReservationNeeded,
      'free': _priceController.text.trim() == '무료',
      'price': _priceController.text.trim() == '무료'
          ? ''
          : _priceController.text.trim(),
      'venueName': _venueController.text.trim(),
      'venueMeta': widget.program?.venueMeta ?? '',
      'address': _addressController.text.trim(),
      'officialUrl': _urlController.text.trim(),
      'operatingHours': _hoursController.text.trim(),
      'operatingPeriod': endDate == null ? null : '$startDate - $endDate',
      'operatingPeriodMeta': endDate == null ? startDate : '',
      'operatingHoursMeta': widget.program?.operatingHoursMeta ?? '',
      'inquiryContact': _contactController.text.trim(),
      'keywordNames': _keywordNames,
    };
    return request;
  }

  bool _isAfter(String start, String end) {
    final startDate = DateTime.parse(start.replaceAll('.', '-'));
    final endDate = DateTime.parse(end.replaceAll('.', '-'));
    return startDate.isAfter(endDate);
  }

  Future<File> _downloadTemporaryImage(String url, int index) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('기존 이미지를 불러오지 못했습니다.');
      }
      final extension = _imageExtension(url);
      final file = File(
        '${Directory.systemTemp.path}/muntum_program_${widget.program?.id ?? 'new'}_'
        '${DateTime.now().microsecondsSinceEpoch}_$index.$extension',
      );
      await response.pipe(file.openWrite());
      return file;
    } finally {
      client.close(force: true);
    }
  }

  String _imageExtension(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.heic')) return 'heic';
    return 'jpg';
  }

  String _displayDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  String _dateOnlyMeta(String value) {
    final trimmed = value.trim();
    return RegExp(r'^\d{4}\.\d{2}\.\d{2}$').hasMatch(trimmed) ? trimmed : '';
  }

  String? _apiDate(String value) {
    final match = RegExp(
      r'^(\d{4})\.(\d{2})\.(\d{2})$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final normalized =
        '$year-${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null ||
        parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      return null;
    }
    return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectPlace() async {
    final place = await Navigator.push<ReportPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportPlaceSearchScreen(allowDirectInput: false),
      ),
    );
    if (!mounted || place == null) return;
    setState(() {
      _venueController.text = place.name;
      _addressController.text = place.address;
    });
  }

  Future<void> _selectKeywords() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      barrierColor: AppColors.dimMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (_) => _KeywordPickerSheet(selected: _keywordNames),
    );
    if (!mounted || selected == null) return;
    setState(() => _keywordsController.text = selected.join(', '));
  }

  Future<void> _showOperatingHoursGuide() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      barrierColor: AppColors.dimMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      builder: (sheetContext) => const _OperatingHoursGuideSheet(),
    );
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
              center: _isCreating ? '새 프로그램 등록하기' : '수정',
              onLeadingTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 80.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('사진'),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 107.h,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ImageAddButton(
                            count: _imageCount,
                            maxCount: _maxImages,
                            onTap: _pickImages,
                          ),
                          if (_images.isNotEmpty) SizedBox(width: 8.w),
                          Expanded(
                            child: ReorderableListView.builder(
                              clipBehavior: Clip.none,
                              padding: EdgeInsets.only(top: 5.h),
                              scrollDirection: Axis.horizontal,
                              buildDefaultDragHandles: false,
                              itemCount: _images.length,
                              onReorderItem: _reorderImage,
                              proxyDecorator: (child, index, animation) =>
                                  Material(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 1,
                                        end: 1.06,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              itemBuilder: (context, index) {
                                final item = _images[index];
                                return Padding(
                                  key: ObjectKey(item),
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: _EditableImage(
                                      image: item.buildImage(),
                                      onRemove: () => _removeImage(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _ProgramTextField(
                      label: '프로그램명',
                      controller: _titleController,
                      hintText: "프로그램명을 입력해주세요.",
                    ),
                    _ProgramTextField(
                      label: '한줄소개',
                      controller: _taglineController,
                      maxLines: 4,
                      hintText: "임팩트 있는 한 줄로 소개해주세요.",
                    ),
                    _sectionLabel('프로그램 유형'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: ProgramType.values
                          .map(
                            (type) => _SelectionChip(
                              text: type.label,
                              selected: _programType == type,
                              onTap: () => setState(() => _programType = type),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 28.h),
                    _ProgramTextField(
                      label: '소개글',
                      controller: _curationController,
                      maxLines: 8,
                      hintText: "프로그램을 소개해주세요.",
                    ),
                    _ProgramTextField(
                      label: '장소',
                      hintText: '장소를 검색해주세요.',
                      controller: _venueController,
                      prefixIcon: SvgPicture.asset(
                        'assets/icons/search.svg',
                        color: AppColors.gray800,
                      ),
                      onPrefixIconTap: _selectPlace,
                    ),
                    _ProgramTextField(
                      label: '주소',
                      controller: _addressController,
                      hintText: '장소를 검색하면 주소가 입력돼요.',
                      readOnly: true,
                      canRequestFocus: false,
                      enableInteractiveSelection: false,
                    ),
                    _ProgramTextField(
                      label: '시작일',
                      hintText: '예: 2026.07.14',
                      controller: _startDateController,
                    ),
                    _ProgramTextField(
                      label: '마감일 (선택)',
                      hintText: '예: 2026.07.14 / 미입력 시 상시로 표시돼요.',
                      controller: _endDateController,
                    ),
                    _ProgramTextField(
                      label: '운영 시간',
                      controller: _hoursController,
                      hintText: "예: 월-금 10:00~17:00",
                      maxLines: 4,
                      labelTrailing: GestureDetector(
                        onTap: _showOperatingHoursGuide,
                        child: Text(
                          '작성방법',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.gray700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    _ProgramTextField(
                      label: '가격',
                      hintText: '예: 무료 / 15,000원 / 프로그램별 상이',
                      controller: _priceController,
                    ),
                    _sectionLabel('사전 예약'),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        _SelectionChip(
                          text: '필요',
                          selected: _isReservationNeeded,
                          onTap: () =>
                              setState(() => _isReservationNeeded = true),
                        ),
                        SizedBox(width: 8.w),
                        _SelectionChip(
                          text: '불필요',
                          selected: !_isReservationNeeded,
                          onTap: () =>
                              setState(() => _isReservationNeeded = false),
                        ),
                      ],
                    ),
                    SizedBox(height: 26.h),
                    _ProgramTextField(
                      label: '키워드',
                      hintText: '키워드를 선택해주세요.',
                      controller: _keywordsController,
                      readOnly: true,
                      onTap: _selectKeywords,
                      suffixIcon: SvgPicture.asset(
                        'assets/icons/arrow_down.svg',
                        color: AppColors.gray800,
                      ),
                    ),
                    _ProgramTextField(
                      label: '연락처 기재 (선택)',
                      hintText: "예: 02-123-4567",
                      controller: _contactController,
                    ),
                    _ProgramTextField(
                      label: '링크 (선택)',
                      hintText: "링크를 첨부해주세요.",
                      controller: _urlController,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          color: AppColors.white,
          padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 48.h),
          child: SizedBox(
            height: 48.h,
            child: ButtonSolid(
              text: _isSaving
                  ? (_isCreating ? '등록 중' : '저장 중')
                  : (_isCreating ? '등록하기' : '저장'),
              textColor: _canSubmit ? AppColors.white : AppColors.gray400,
              boxColor: _canSubmit ? AppColors.black : AppColors.gray100,
              padding: EdgeInsets.zero,
              onTap: _canSubmit ? _save : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.button3.copyWith(color: AppColors.gray700),
    );
  }
}

class _ProgramTextField extends StatelessWidget {
  const _ProgramTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.prefixIcon,
    this.onPrefixIconTap,
    this.labelTrailing,
    this.canRequestFocus = true,
    this.enableInteractiveSelection = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final VoidCallback? onPrefixIconTap;
  final Widget? labelTrailing;
  final bool canRequestFocus;
  final bool enableInteractiveSelection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.button3.copyWith(color: AppColors.gray700),
              ),
              labelTrailing ?? const SizedBox.shrink(),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: controller,
            readOnly: readOnly,
            canRequestFocus: canRequestFocus,
            enableInteractiveSelection: enableInteractiveSelection,
            onTap: onTap,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : maxLines,
            cursorColor: AppColors.gray900,
            style: AppTypography.body3.copyWith(color: AppColors.gray900),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.body3.copyWith(color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.white,
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onPrefixIconTap,
                        child: prefixIcon,
                      ),
                    )
                  : null,
              suffixIcon: suffixIcon == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: suffixIcon,
                    ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 13.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: AppColors.lineStrong, width: 1.w),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: AppColors.gray400, width: 1.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: selected ? AppColors.black : AppColors.lineStrong,
            width: selected ? 1.2.w : 1.w,
          ),
        ),
        child: Text(
          text,
          style: AppTypography.button3.copyWith(
            color: selected ? AppColors.black : AppColors.gray800,
          ),
        ),
      ),
    );
  }
}

class _KeywordPickerSheet extends StatefulWidget {
  const _KeywordPickerSheet({required this.selected});

  final List<String> selected;

  @override
  State<_KeywordPickerSheet> createState() => _KeywordPickerSheetState();
}

class _KeywordPickerSheetState extends State<_KeywordPickerSheet> {
  static const int _maxSelection = 3;

  late final Set<String> _selected = widget.selected
      .where((keyword) => keyword.trim().isNotEmpty)
      .take(_maxSelection)
      .toSet();
  late final Future<List<String>> _keywords = _loadKeywords();
  Timer? _limitToastTimer;
  bool _limitToastVisible = false;

  Future<List<String>> _loadKeywords() async {
    final keywords = await KeywordService().fetchTaggedKeywords();
    final names = keywords
        .where((keyword) => keyword.active && keyword.name.trim().isNotEmpty)
        .map((keyword) => keyword.name.trim())
        .toSet()
        .toList();
    for (final selected in _selected) {
      if (!names.contains(selected)) names.insert(0, selected);
    }
    return names;
  }

  void _toggle(String keyword) {
    if (_selected.contains(keyword)) {
      setState(() => _selected.remove(keyword));
      return;
    }
    if (_selected.length >= _maxSelection) {
      _showLimitToast();
      return;
    }
    setState(() => _selected.add(keyword));
  }

  void _showLimitToast() {
    _limitToastTimer?.cancel();
    setState(() => _limitToastVisible = true);
    _limitToastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _limitToastVisible = false);
    });
  }

  @override
  void dispose() {
    _limitToastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20.w,
              0.h,
              20.w,
              MediaQuery.paddingOf(context).bottom + 16.h,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 65.h,
                  child: Row(
                    children: [
                      SizedBox(width: 24.r),
                      Expanded(
                        child: Text(
                          '키워드 선택',
                          textAlign: TextAlign.center,
                          style: AppTypography.title4.copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: SvgPicture.asset(
                            'assets/icons/close.svg',
                            width: 21.r,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: _keywords,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gray900,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '키워드를 불러오지 못했어요.',
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        );
                      }
                      final keywords = snapshot.data ?? const [];
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: keywords.length,
                        separatorBuilder: (_, _) => SizedBox(height: 4.h),
                        itemBuilder: (context, index) {
                          final keyword = keywords[index];
                          final selected = _selected.contains(keyword);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggle(keyword),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20.r,
                                    height: 20.r,
                                    padding: EdgeInsets.all(2.r),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.gray900
                                          : AppColors.gray100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
                                      selected
                                          ? 'assets/icons/check.svg'
                                          : 'assets/icons/plus.svg',
                                      color: selected
                                          ? AppColors.white
                                          : AppColors.gray500,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      keyword,
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ButtonSolid(
                    text: '(${_selected.length}/$_maxSelection) 완료',
                    textColor: _selected.isEmpty
                        ? AppColors.gray500
                        : AppColors.white,
                    boxColor: _selected.isEmpty
                        ? AppColors.gray100
                        : AppColors.black,
                    padding: EdgeInsets.zero,
                    onTap: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            _selected.take(_maxSelection).toList(),
                          ),
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _limitToastVisible ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    20.w,
                    0,
                    20.w,
                    MediaQuery.paddingOf(context).bottom + 76.h,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dimStrong.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18.r,
                        height: 18.r,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.priority_high,
                          color: AppColors.white,
                          size: 13.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          '키워드는 최대 3개까지 선택할 수 있어요.',
                          style: AppTypography.button3.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatingHoursGuideSheet extends StatelessWidget {
  const _OperatingHoursGuideSheet();

  static const _guides = [
    '시간은 24시간제로 표기해주세요. (예. 13:00~18:00)',
    '연속된 요일은 “월–금”, 개별 요일은 “월, 금”으로 구분해주세요.',
    '여러 스케줄은 줄바꿈으로 구분해주세요.',
    '회차로 운영되는 경우 “운영시간 / 하루에 n회차 운영”으로 표기해주세요.',
    '주차 기반 운영은 자연어로 표기해주세요. (예. 매월 첫째 주 토요일)',
    '한 행사에서 여러 프로그램을 동시에 운영하는 경우, “프로그램별 상이”로 표기해주세요.',
    '휴무는 자유롭게 표기해주세요.',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          36.h,
          20.w,
          MediaQuery.paddingOf(context).bottom + 16.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '운영시간은 이렇게 작성해요',
              style: AppTypography.title3.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 20.h),
            ..._guides.map(
              (guide) => Padding(
                padding: EdgeInsets.only(bottom: 5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray700,
                        height: 1.6,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        guide,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.gray600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ButtonSolid(
                text: '확인',
                textColor: AppColors.white,
                boxColor: AppColors.black,
                padding: EdgeInsets.zero,
                onTap: () => Navigator.pop(context),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

class _ProgramImageItem {
  _ProgramImageItem.network(this.networkUrl) : localFile = null;

  _ProgramImageItem.local(this.localFile) : networkUrl = null;

  final String? networkUrl;
  final XFile? localFile;

  Widget buildImage() {
    final file = localFile;
    if (file != null) {
      return Image.file(File(file.path), fit: BoxFit.cover);
    }
    return Image.network(
      networkUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.gray100),
    );
  }
}

class _ImageAddButton extends StatelessWidget {
  const _ImageAddButton({
    required this.count,
    required this.maxCount,
    required this.onTap,
  });

  final int count;
  final int maxCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76.w,
        height: 100.h,
        decoration: DottedDecoration(
          shape: Shape.box,
          color: AppColors.gray300,
          strokeWidth: 1,
          dash: const [6, 4],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/plus.svg',
              width: 24.r,
              color: AppColors.gray800,
            ),
            SizedBox(height: 8.h),
            Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: count.toString(),
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  TextSpan(
                    text: '/$maxCount',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableImage extends StatelessWidget {
  const _EditableImage({required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76.w,
      height: 100.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: image,
            ),
          ),
          Positioned(
            top: -5.h,
            right: -5.w,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20.r,
                height: 20.r,
                decoration: const BoxDecoration(
                  color: AppColors.gray900,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: AppColors.white, size: 13.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
