import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';
import 'package:muntum/services/admin_curation_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/utils/app_toast.dart';

class CurationReviewScreen extends StatefulWidget {
  const CurationReviewScreen({
    super.key,
    required this.summary,
    this.service,
    this.programService,
  });

  final AdminCurationModel summary;
  final AdminCurationService? service;
  final ProgramService? programService;

  @override
  State<CurationReviewScreen> createState() => _CurationReviewScreenState();
}

class _CurationReviewScreenState extends State<CurationReviewScreen> {
  late final AdminCurationService _service;
  late final ProgramService _programService;
  AdminCurationModel? _detail;
  ProgramModel? _program;
  bool _loading = true;
  bool _working = false;
  String? _error;

  bool get _pending => _detail?.curation.status == CurationStatus.pending;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminCurationService();
    _programService = widget.programService ?? ProgramService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.fetchDetail(widget.summary.curation.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '글을 불러오지 못했어요.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _searchProgram() async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (_) => _ProgramSearchSheet(
        initialQuery: _detail!.curation.programTitle,
        service: _programService,
      ),
    );
    if (!mounted || result == null) return;
    if (result is ProgramModel) {
      setState(() => _program = result);
    } else if (result == 'new') {
      final approved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ProgramEditScreen(
            approvalCuration: _detail,
            adminCurationService: _service,
          ),
        ),
      );
      if (mounted && approved == true) Navigator.pop(context, 'approved');
    }
  }

  Future<void> _approve() async {
    if (_working || _program == null) return;
    setState(() => _working = true);
    try {
      await _service.approveExisting(
        curationId: _detail!.curation.id,
        programId: _program!.id,
      );
      if (mounted) Navigator.pop(context, 'approved');
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, isError: true);
    } catch (_) {
      if (mounted) showAppToast(context, '등록하지 못했어요.', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _requestChanges() async {
    if (_working) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (_) => const _ChangeReasonSheet(),
    );
    if (!mounted || reason == null) return;
    setState(() => _working = true);
    try {
      await _service.requestChanges(
        curationId: _detail!.curation.id,
        reason: reason,
        publicationStatus: 'UNPUBLISHED',
      );
      if (mounted) Navigator.pop(context, 'changes');
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, isError: true);
    } catch (_) {
      if (mounted) showAppToast(context, '수정 요청을 보내지 못했어요.', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppBarWidget(
              centerType: AppBarCenterType.text,
              center: '큐레이터 글 확인',
              leadingIcon: 'arrow_left.svg',
              onLeadingTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: TextButton(
                        onPressed: _load,
                        child: Text('$_error\n다시 시도'),
                      ),
                    )
                  : ListView(
                      children: [
                        if (detail!.curation.status ==
                            CurationStatus.changesRequested)
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFFFF8D8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 14.h,
                            ),
                            child: Text(
                              '[수정 요청 건]\n${detail.curation.changeRequestReason ?? ''}',
                              style: AppTypography.caption2.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                          child: Row(
                            children: [
                              _ReviewCuratorAvatar(
                                imageUrl: detail.curator.profileImageUrl,
                              ),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.curator.nickname,
                                    style: AppTypography.headline3,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '작성일 ${detail.curation.formattedCreatedAt}',
                                    style: AppTypography.caption2.copyWith(
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 8.h,
                          color: AppColors.backgroundNormal,
                        ),
                        _Section(
                          children: [
                            Text('프로그램 정보', style: AppTypography.headline1),
                            SizedBox(height: 24.h),
                            _Field(
                              label: '프로그램명',
                              value: detail.curation.programTitle,
                            ),
                            _Field(label: '장소', value: detail.curation.place),
                            if (_program != null &&
                                (_program!.location['address'] ?? '')
                                    .trim()
                                    .isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14.r,
                                      color: AppColors.gray400,
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Text(
                                        _program!.location['address']!,
                                        style: AppTypography.caption2.copyWith(
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_program != null)
                              _SelectedProgram(
                                program: _program!,
                                onTap: _searchProgram,
                              )
                            else if (_pending)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 44.h,
                                  child: ButtonSolid(
                                    text: '프로그램 검색',
                                    textColor: AppColors.gray900,
                                    boxColor: AppColors.white,
                                    border: Border.all(
                                      color: AppColors.lineStrong,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onTap: _searchProgram,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Container(
                          height: 8.h,
                          color: AppColors.backgroundNormal,
                        ),
                        _Section(
                          children: [
                            Text('작성 내용', style: AppTypography.headline1),
                            SizedBox(height: 24.h),
                            _Field(
                              label: '한줄소개',
                              value: detail.curation.tagline,
                            ),
                            _Field(
                              label: '소개글',
                              value: detail.curation.content,
                            ),
                            if (detail.curation.images.isNotEmpty) ...[
                              Text(
                                '사진',
                                style: AppTypography.caption2.copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              SizedBox(
                                height: 64.r,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: detail.curation.images.length,
                                  separatorBuilder: (_, _) =>
                                      SizedBox(width: 6.w),
                                  itemBuilder: (_, index) => ClipRRect(
                                    borderRadius: BorderRadius.circular(6.r),
                                    child: Image.network(
                                      detail.curation.images[index].imageUrl,
                                      width: 64.r,
                                      height: 64.r,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 64.r,
                                        height: 64.r,
                                        color: AppColors.gray100,
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppColors.gray400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
            ),
            if (detail != null && _pending)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ButtonSolid(
                          text: '수정요청',
                          textColor: AppColors.gray900,
                          boxColor: AppColors.white,
                          border: Border.all(color: AppColors.lineStrong),
                          padding: EdgeInsets.zero,
                          onTap: _working ? null : _requestChanges,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ButtonSolid(
                          text: _working ? '처리 중' : '등록하기',
                          textColor: _working || _program == null
                              ? AppColors.gray400
                              : AppColors.white,
                          boxColor: _working || _program == null
                              ? AppColors.gray200
                              : AppColors.black,
                          padding: EdgeInsets.zero,
                          onTap: _working || _program == null ? null : _approve,
                        ),
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

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 22.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption2.copyWith(color: AppColors.gray500),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: AppTypography.body1.copyWith(color: AppColors.gray900),
        ),
      ],
    ),
  );
}

class _ReviewCuratorAvatar extends StatelessWidget {
  const _ReviewCuratorAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Image.asset(
      'assets/default_profile_img.jpg',
      width: 48.r,
      height: 48.r,
      fit: BoxFit.cover,
    );

    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: imageUrl?.isNotEmpty == true
                ? Image.network(
                    imageUrl!,
                    width: 48.r,
                    height: 48.r,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback(),
                  )
                : fallback(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SvgPicture.asset(
              'assets/icons/curator_badge.svg',
              width: 17.r,
              height: 17.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedProgram extends StatelessWidget {
  const _SelectedProgram({required this.program, required this.onTap});
  final ProgramModel program;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lineNormal),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5.r),
            child: program.imageUrls.isNotEmpty
                ? Image.network(
                    program.imageUrls.first,
                    width: 54.r,
                    height: 54.r,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _programImagePlaceholder(),
                  )
                : _programImagePlaceholder(),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headline3,
                ),
                SizedBox(height: 3.h),
                Text(
                  program.locationName,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  program.cardDateText.isEmpty ? '날짜 미정' : program.cardDateText,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray400),
        ],
      ),
    ),
  );
}

Widget _programImagePlaceholder() => Container(
  width: 54.r,
  height: 54.r,
  color: AppColors.gray100,
  child: const Icon(Icons.image_outlined, color: AppColors.gray400),
);

class _ProgramSearchSheet extends StatefulWidget {
  const _ProgramSearchSheet({
    required this.initialQuery,
    required this.service,
  });
  final String initialQuery;
  final ProgramService service;
  @override
  State<_ProgramSearchSheet> createState() => _ProgramSearchSheetState();
}

class _ProgramSearchSheetState extends State<_ProgramSearchSheet> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<ProgramModel> _programs = const [];
  bool _loading = false;
  String? _error;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final version = ++_version;
    final query = _controller.text.trim().isEmpty
        ? widget.initialQuery.trim()
        : _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _programs = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.service.fetchPrograms(
        search: query,
        size: 20,
        authorized: true,
      );
      if (mounted && version == _version) {
        setState(() => _programs = result.content);
      }
    } catch (_) {
      if (mounted && version == _version) {
        setState(() {
          _programs = const [];
          _error = '프로그램을 불러오지 못했어요.';
        });
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final contentHeight = math.min(
      screenHeight * 0.52,
      screenHeight - keyboardHeight - MediaQuery.paddingOf(context).top - 56.h,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, keyboardHeight + 20.h),
      child: SizedBox(
        height: math.max(200.h, contentHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: Text('프로그램 검색', style: AppTypography.headline1),
                ),
                SizedBox(
                  height: 32.h,
                  child: ButtonSolid(
                    text: '새로 등록',
                    textColor: AppColors.gray900,
                    boxColor: AppColors.white,
                    border: Border.all(color: AppColors.lineStrong),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    onTap: () => Navigator.pop(context, 'new'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.gray900),
                hintText: '프로그램명을 입력해 주세요.',
                hintStyle: AppTypography.body3.copyWith(
                  color: AppColors.gray400,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.lineStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.lineStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.gray900),
                ),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: AppColors.gray400,
                        ),
                        onPressed: () {
                          _controller.clear();
                          _search();
                        },
                      ),
              ),
              onChanged: (_) {
                setState(() {});
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), _search);
              },
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: TextButton(
                        onPressed: _search,
                        child: Text('$_error\n다시 시도'),
                      ),
                    )
                  : _controller.text.trim().isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_programs.isNotEmpty) ...[
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: '유사 프로그램 '),
                                TextSpan(
                                  text: '${_programs.length}',
                                  style: const TextStyle(
                                    color: AppColors.primary800,
                                  ),
                                ),
                              ],
                            ),
                            style: AppTypography.button3,
                          ),
                          SizedBox(height: 10.h),
                          SizedBox(
                            height: 84.r,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _programs.length,
                              separatorBuilder: (_, _) => SizedBox(width: 8.w),
                              itemBuilder: (context, index) => SizedBox(
                                width: MediaQuery.sizeOf(context).width - 56.w,
                                child: _SelectedProgram(
                                  program: _programs[index],
                                  onTap: () =>
                                      Navigator.pop(context, _programs[index]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : _programs.isEmpty
                  ? Center(
                      child: Text(
                        '검색 결과가 없어요.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _programs.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) => _SelectedProgram(
                        program: _programs[index],
                        onTap: () => Navigator.pop(context, _programs[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeReasonSheet extends StatefulWidget {
  const _ChangeReasonSheet();
  @override
  State<_ChangeReasonSheet> createState() => _ChangeReasonSheetState();
}

class _ChangeReasonSheetState extends State<_ChangeReasonSheet> {
  static const _reasons = [
    '글 내 오탈자 및 맞춤법, 띄어쓰기를 확인해주세요.',
    '프로그램 정보와 작성하신 내용이 일치하지 않습니다. 확인 후 수정해 주세요.',
    '비방, 욕설, 허위 등 부적절한 내용이 포함되어 있습니다. 확인 후 수정해 주세요.',
  ];
  int? _selected;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = _selected == 3
        ? _controller.text.trim()
        : _selected == null
        ? ''
        : _reasons[_selected!];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        24.h,
        20.w,
        MediaQuery.viewInsetsOf(context).bottom + 36.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('수정 요청 사유 선택', style: AppTypography.headline1),
            SizedBox(height: 18.h),
            for (var index = 0; index < _reasons.length; index++)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _ChangeReasonOption(
                  text: _reasons[index],
                  selected: _selected == index,
                  onTap: () => setState(() => _selected = index),
                ),
              ),
            _ChangeReasonOption(
              text: '직접 입력',
              selected: _selected == 3,
              onTap: () => setState(() => _selected = 3),
            ),
            if (_selected == 3) ...[
              SizedBox(height: 8.h),
              TextField(
                controller: _controller,
                maxLength: 500,
                maxLines: 4,
                style: AppTypography.body3.copyWith(color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: '수정 요청 사유를 입력해주세요.',
                  hintStyle: AppTypography.body3.copyWith(
                    color: AppColors.gray400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.lineStrong),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            SizedBox(height: 28.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ButtonSolid(
                      text: '취소',
                      textColor: AppColors.gray900,
                      boxColor: AppColors.white,
                      border: Border.all(color: AppColors.lineStrong),
                      padding: EdgeInsets.zero,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ButtonSolid(
                      text: '수정 요청',
                      textColor: reason.isEmpty
                          ? AppColors.gray400
                          : AppColors.white,
                      boxColor: reason.isEmpty
                          ? AppColors.gray100
                          : AppColors.black,
                      padding: EdgeInsets.zero,
                      onTap: reason.isEmpty
                          ? null
                          : () => Navigator.pop(context, reason),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeReasonOption extends StatelessWidget {
  const _ChangeReasonOption({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 46.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: selected ? AppColors.gray900 : AppColors.lineStrong,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.body3.copyWith(color: AppColors.gray900),
      ),
    ),
  );
}
