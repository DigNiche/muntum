import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/curator/curation_action_sheet.dart';
import 'package:muntum/screens/mypage/curator/curation_write_screen.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/utils/app_toast.dart';

class CurationDetailScreen extends StatefulWidget {
  const CurationDetailScreen({
    super.key,
    required this.curation,
    this.service,
    this.programService,
  });

  final CurationModel curation;
  final CurationService? service;
  final ProgramService? programService;

  @override
  State<CurationDetailScreen> createState() => _CurationDetailScreenState();
}

class _CurationDetailScreenState extends State<CurationDetailScreen> {
  late final CurationService _service;
  late CurationModel _curation;
  ProgramModel? _linkedProgram;
  bool _linkedProgramLoadFailed = false;
  bool _isLoading = false;
  bool _isRefreshingDetail = false;
  String? _detailError;

  bool get _canDelete =>
      _curation.status == CurationStatus.pending ||
      _curation.status == CurationStatus.changesRequested;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CurationService();
    _curation = widget.curation;
    _loadLinkedProgram();
    // The list already contains details; avoid a second request during navigation.
    if (_curation.content.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshDetail();
      });
    }
  }

  Future<void> _loadLinkedProgram() async {
    final programId = _curation.programId;
    if (programId == null || programId.isEmpty) return;
    try {
      final program = await (widget.programService ?? ProgramService())
          .fetchProgram(programId);
      if (mounted) setState(() => _linkedProgram = program);
    } catch (_) {
      if (mounted) setState(() => _linkedProgramLoadFailed = true);
    }
  }

  Future<void> _refreshDetail() async {
    if (_curation.id.isEmpty) return;
    setState(() {
      _isRefreshingDetail = true;
      _detailError = null;
    });
    try {
      final detail = await _service
          .fetchMyDetail(_curation.id)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _curation = _curation.mergeDetails(detail));
    } on ApiException catch (error) {
      if (mounted) setState(() => _detailError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _detailError = '최신 내용을 불러오지 못했어요.');
      }
    } finally {
      if (mounted) setState(() => _isRefreshingDetail = false);
    }
  }

  Future<void> _showActions() async {
    final action = await showCurationActionSheet(context);
    if (!mounted || action == null) return;
    if (action == CurationAction.edit) {
      await _edit();
    } else {
      if (!_canDelete) {
        showAppToast(context, '승인된 글은 삭제할 수 없어요.', isError: true);
        return;
      }
      await _confirmDelete();
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CurationWriteScreen(
          service: _service,
          initialCuration: _curation,
          resubmitAfterUpdate:
              _curation.status == CurationStatus.changesRequested,
        ),
      ),
    );
    if (!mounted || updated != true) return;
    Navigator.pop(context, 'updated');
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showConfirmationPopupWidget(
      context: context,
      title: '작성한 글을 삭제할까요?',
      description: '삭제한 글은 복구할 수 없어요.',
      confirmText: '삭제',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await _service.delete(_curation.id);
      if (!mounted) return;
      Navigator.pop(context, 'deleted');
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, isError: true);
    } catch (_) {
      if (mounted) showAppToast(context, '글을 삭제하지 못했어요.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.text,
              center: '작성 내용 확인',
              leadingIcon: 'arrow_left.svg',
              onLeadingTap: () => Navigator.pop(context),
              trailing: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isLoading ? null : _showActions,
                child: SizedBox(
                  width: 28.r,
                  height: 28.r,
                  child: Icon(
                    Icons.more_vert,
                    size: 22.r,
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ),
            if (_curation.status != CurationStatus.approved)
              _ReviewBanner(curation: _curation),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 28.h),
                children: [
                  if (_isRefreshingDetail)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.primary500,
                      backgroundColor: AppColors.white,
                    ),
                  if (_detailError != null)
                    _DetailLoadError(
                      message: _detailError!,
                      onRetry: _refreshDetail,
                    ),
                  _InformationSection(
                    curation: _curation,
                    program: _linkedProgram,
                    programLoadFailed: _linkedProgramLoadFailed,
                  ),
                  Container(height: 8.h, color: AppColors.backgroundNormal),
                  _ContentSection(curation: _curation),
                  if (_curation.images.isNotEmpty)
                    _ImageSection(images: _curation.images),
                ],
              ),
            ),
            if (_curation.status == CurationStatus.changesRequested)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 32.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ButtonSolid(
                    text: '수정하기',
                    textColor: AppColors.white,
                    boxColor: AppColors.black,
                    padding: EdgeInsets.zero,
                    onTap: _isLoading ? null : _edit,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.curation});

  final CurationModel curation;

  @override
  Widget build(BuildContext context) {
    final isChanges = curation.status == CurationStatus.changesRequested;
    final message = isChanges
        ? curation.changeRequestReason ?? '수정이 필요한 내용을 확인해 주세요.'
        : '관리자가 작성 내용을 확인하고 있어요.';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      color: isChanges ? const Color(0xFFFFF8D8) : AppColors.primary100,
      child: Text(
        message,
        style: AppTypography.caption1.copyWith(
          color: isChanges ? AppColors.warning : AppColors.primary800,
        ),
      ),
    );
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.curation,
    required this.program,
    required this.programLoadFailed,
  });

  final CurationModel curation;
  final ProgramModel? program;
  final bool programLoadFailed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로그램 정보',
            style: AppTypography.headline1.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 24.h),
          const _SectionLabel('프로그램명'),
          SizedBox(height: 8.h),
          Text(
            curation.programId == null
                ? curation.programTitle
                : program?.title ??
                      (programLoadFailed
                          ? '프로그램 정보를 불러올 수 없어요.'
                          : '프로그램 정보를 불러오는 중'),
            style: AppTypography.body1.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 22.h),
          const _SectionLabel('장소'),
          SizedBox(height: 8.h),
          Text(
            program?.locationName ?? curation.place,
            style: AppTypography.body1.copyWith(color: AppColors.gray900),
          ),
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.curation});

  final CurationModel curation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '작성 내용',
            style: AppTypography.headline1.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 24.h),
          const _SectionLabel('한줄소개'),
          SizedBox(height: 8.h),
          Text(
            curation.tagline,
            style: AppTypography.body1.copyWith(color: AppColors.gray900),
          ),
          SizedBox(height: 22.h),
          const _SectionLabel('소개글'),
          SizedBox(height: 8.h),
          Text(
            curation.content,
            style: AppTypography.body1.copyWith(color: AppColors.gray900),
          ),
        ],
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.images});

  final List<CurationImageModel> images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: images
            .map(
              (image) => ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  image.imageUrl,
                  width: 96.r,
                  height: 96.r,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, _) {
                    assert(() {
                      final host = Uri.tryParse(image.imageUrl)?.host ?? '';
                      final status = error is NetworkImageLoadException
                          ? 'HTTP ${error.statusCode}'
                          : error.runtimeType.toString();
                      debugPrint('Curation image failed: host=$host, $status');
                      return true;
                    }());
                    return Container(
                      width: 96.r,
                      height: 96.r,
                      color: AppColors.gray100,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.gray400,
                      ),
                    );
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DetailLoadError extends StatelessWidget {
  const _DetailLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      color: AppColors.gray50,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption1.copyWith(color: AppColors.gray600),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption1.copyWith(color: AppColors.gray500),
    );
  }
}
