import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/utils/app_toast.dart';

enum _ProgramMenuAction { edit, delete }

class ProgramManageScreen extends StatefulWidget {
  const ProgramManageScreen({super.key});

  @override
  State<ProgramManageScreen> createState() => _ProgramManageScreenState();
}

class _ProgramManageScreenState extends State<ProgramManageScreen> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _service = ProgramService();
  final List<ProgramModel> _programs = [];

  Timer? _searchDebounce;
  int _nextPage = 0;
  int _totalElements = 0;
  int _requestId = 0;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadPrograms(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadPrograms(reset: true);
    });
    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasNext || _isLoadingMore) return;
    if (_scrollController.position.extentAfter < 240.h) {
      _loadPrograms();
    }
  }

  Future<void> _loadPrograms({bool reset = false}) async {
    if (reset) {
      _requestId += 1;
      setState(() {
        _programs.clear();
        _isLoading = true;
        _errorMessage = null;
        _nextPage = 0;
        _hasNext = true;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasNext) return;
      setState(() => _isLoadingMore = true);
    }

    final requestId = _requestId;

    try {
      final response = await _service.fetchPrograms(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        page: reset ? 0 : _nextPage,
        size: _pageSize,
        authorized: true,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        if (reset) _programs.clear();
        _programs.addAll(response.content);
        _totalElements = response.totalElements;
        _nextPage = response.page + 1;
        _hasNext = response.hasNext || !response.last;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = '프로그램 목록을 불러오지 못했어요.');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _openProgram(ProgramModel program) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program)),
    );
  }

  Future<void> _openProgramCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProgramEditScreen()),
    );
    if (mounted && created == true) {
      await _loadPrograms(reset: true);
    }
  }

  Future<void> _showProgramActions(ProgramModel program) async {
    final action = await showModalBottomSheet<_ProgramMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.dimMedium,
      builder: (sheetContext) => _ProgramActionSheet(
        onEdit: () => Navigator.pop(sheetContext, _ProgramMenuAction.edit),
        onDelete: () => Navigator.pop(sheetContext, _ProgramMenuAction.delete),
      ),
    );
    if (!mounted || action == null) return;

    if (action == _ProgramMenuAction.edit) {
      ProgramModel detail;
      try {
        detail = await _service.fetchProgram(program.id, authorized: true);
      } catch (error) {
        if (mounted) showAppToast(context, '$error');
        return;
      }
      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => ProgramEditScreen(program: detail)),
      );
      if (mounted && saved == true) {
        await _loadPrograms(reset: true);
      }
      return;
    }

    await showPopupWidget(
      context: context,
      title: '프로그램을 삭제할까요?',
      description: '삭제된 데이터는 복구할 수 없어요.',
      text1: '취소',
      text2: '삭제',
      text2Color: AppColors.error,
      onText1Tap: () => Navigator.pop(context),
      onText2Tap: () {
        Navigator.pop(context);
        _deleteProgram(program);
      },
    );
  }

  Future<void> _deleteProgram(ProgramModel program) async {
    try {
      await _service.deleteProgram(program.id);
      if (!mounted) return;
      setState(() {
        _programs.removeWhere((item) => item.id == program.id);
        if (_totalElements > 0) _totalElements -= 1;
      });
      showAppToast(context, '프로그램이 삭제되었습니다.', showIcon: false);
    } catch (error) {
      if (mounted) showAppToast(context, '$error');
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
            leadingIcon: 'arrow_left.svg',
            center: '프로그램 관리',
            onLeadingTap: () => Navigator.pop(context),
            trailing: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openProgramCreate,
              child: SizedBox(
                width: 24.r,
                height: 24.r,
                child: SvgPicture.asset(
                  'assets/icons/plus.svg',
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray900,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
            child: _ProgramSearchField(
              controller: _searchController,
              onClear: () => _searchController.clear(),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _programs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }

    if (_errorMessage != null && _programs.isEmpty) {
      return _ProgramMessageState(
        message: _errorMessage!,
        buttonText: '다시 시도',
        onTap: () => _loadPrograms(reset: true),
      );
    }

    if (_programs.isEmpty) {
      return const _ProgramMessageState(message: '검색된 프로그램이 없어요.');
    }

    return RefreshIndicator(
      backgroundColor: AppColors.backgroundNormal,
      color: AppColors.gray900,
      onRefresh: () => _loadPrograms(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
        itemCount: _programs.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                '프로그램 $_totalElements개',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            );
          }
          if (index == _programs.length + 1) {
            return _isLoadingMore
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gray900,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          final program = _programs[index - 1];
          return _ProgramListItem(
            program: program,
            onTap: () => _openProgram(program),
            onMoreTap: () => _showProgramActions(program),
          );
        },
      ),
    );
  }
}

class _ProgramActionSheet extends StatelessWidget {
  const _ProgramActionSheet({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 48.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                '수정하기',
                style: AppTypography.body1.copyWith(color: AppColors.gray900),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                '삭제하기',
                style: AppTypography.body1.copyWith(color: AppColors.gray900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramSearchField extends StatelessWidget {
  const _ProgramSearchField({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.gray900,
        style: AppTypography.body1.copyWith(color: AppColors.gray900),
        decoration: InputDecoration(
          hintText: '프로그램 명, 키워드로 검색하기',
          hintStyle: AppTypography.body1.copyWith(color: AppColors.gray400),
          prefixIcon: Padding(
            padding: EdgeInsets.all(15.r),
            child: SvgPicture.asset(
              'assets/icons/search.svg',
              width: 22.r,
              height: 22.r,
              colorFilter: const ColorFilter.mode(
                AppColors.gray900,
                BlendMode.srcIn,
              ),
            ),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: SvgPicture.asset(
                      'assets/icons/circle_close.svg',
                      width: 20.r,
                      height: 20.r,
                    ),
                  ),
                ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.lineStrong, width: 1.w),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.gray400, width: 1.w),
          ),
        ),
      ),
    );
  }
}

class _ProgramListItem extends StatelessWidget {
  const _ProgramListItem({
    required this.program,
    required this.onTap,
    required this.onMoreTap,
  });

  final ProgramModel program;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  String get _location {
    if (program.locationName.trim().isNotEmpty) {
      return program.locationName.trim();
    }
    final address = program.location['address']?.trim() ?? '';
    return address.isEmpty ? '위치 정보 없음' : address;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.lineNormal, width: 1.h),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline1.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '(운영기간) ${program.detailDateText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/location-filled.svg',
                        width: 14.r,
                        height: 14.r,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gray400,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          _location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onMoreTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 0, 20.h),
                child: Icon(
                  Icons.more_vert,
                  size: 20.r,
                  color: AppColors.gray400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramMessageState extends StatelessWidget {
  const _ProgramMessageState({
    required this.message,
    this.buttonText,
    this.onTap,
  });

  final String message;
  final String? buttonText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
          if (buttonText != null && onTap != null) ...[
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onTap,
              child: Text(
                buttonText!,
                style: AppTypography.button2.copyWith(color: AppColors.gray900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
