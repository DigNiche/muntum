import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/utils/app_toast.dart';

enum _ProgramMenuAction { edit, delete }

enum _PeriodFilter { all, ongoing, upcoming, ended }

enum _OriginFilter { all, general, curation }

enum _ManageSort { latest, endingSoon, popular }

class ProgramManageScreen extends StatefulWidget {
  const ProgramManageScreen({super.key, this.service});

  final ProgramService? service;

  @override
  State<ProgramManageScreen> createState() => _ProgramManageScreenState();
}

class _ProgramManageScreenState extends State<ProgramManageScreen> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  late final ProgramService _service;
  final List<ProgramModel> _programs = [];

  Timer? _searchDebounce;
  int _nextPage = 0;
  int _totalElements = 0;
  int _requestId = 0;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _searchMode = false;
  _PeriodFilter _periodFilter = _PeriodFilter.all;
  _OriginFilter _originFilter = _OriginFilter.all;
  _ManageSort _sort = _ManageSort.latest;

  List<ProgramModel> get _visiblePrograms => _programs.where((program) {
    final current = DateTime.now();
    final now = DateTime(current.year, current.month, current.day);
    final start = DateTime.tryParse(program.startDate);
    final end = DateTime.tryParse(program.endDate);
    final matchesPeriod = switch (_periodFilter) {
      _PeriodFilter.all => true,
      _PeriodFilter.ongoing =>
        !program.ended &&
            (start == null || !start.isAfter(now)) &&
            (end == null || !end.isBefore(now)),
      _PeriodFilter.upcoming => start != null && start.isAfter(now),
      _PeriodFilter.ended =>
        program.ended || (end != null && end.isBefore(now)),
    };
    final matchesOrigin = switch (_originFilter) {
      _OriginFilter.all => true,
      _OriginFilter.general => !program.hasCurator,
      _OriginFilter.curation => program.hasCurator,
    };
    return matchesPeriod && matchesOrigin;
  }).toList();

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ProgramService();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _reloadPrograms();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _reloadPrograms();
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
        sort: switch (_sort) {
          _ManageSort.latest => ProgramSort.latest,
          _ManageSort.endingSoon => ProgramSort.endDate,
          _ManageSort.popular => ProgramSort.view,
        },
        order: _sort == _ManageSort.endingSoon ? SortOrder.asc : SortOrder.desc,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        if (reset) _programs.clear();
        _programs.addAll(response.content);
        _totalElements = response.totalElements;
        _nextPage = response.page + 1;
        _hasNext = response.hasMore;
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

  Future<void> _reloadPrograms() async {
    await _loadPrograms(reset: true);
    if (mounted) await _loadRemainingPagesForLocalFilters();
  }

  void _openProgram(ProgramModel program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(
          program: program,
          entrySource: 'admin_program_management',
        ),
      ),
    );
  }

  Future<void> _openProgramCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProgramEditScreen()),
    );
    if (mounted && created == true) {
      await _reloadPrograms();
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
        await _reloadPrograms();
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

  Future<int?> _showFilterSheet({
    required String title,
    required List<String> labels,
    required int selected,
  }) => showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.dimMedium,
    builder: (sheetContext) => Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headline1),
          SizedBox(height: 18.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 8.h,
            children: [
              for (var i = 0; i < labels.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(sheetContext, i),
                  child: FilterChipWidget(
                    text: labels[i],
                    textColor: AppColors.gray900,
                    backgroundColor: AppColors.white,
                    outlineColor: selected == i
                        ? AppColors.gray900
                        : AppColors.lineStrong,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 9.h,
                    ),
                    textStyle: AppTypography.button4,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _selectPeriod() async {
    final selected = await _showFilterSheet(
      title: '운영기간',
      labels: const ['전체', '진행중', '진행예정', '종료'],
      selected: _periodFilter.index,
    );
    if (mounted && selected != null) {
      setState(() => _periodFilter = _PeriodFilter.values[selected]);
      await _loadRemainingPagesForLocalFilters();
    }
  }

  Future<void> _selectOrigin() async {
    final selected = await _showFilterSheet(
      title: '프로그램 유형',
      labels: const ['일반·큐레이션', '일반', '큐레이션'],
      selected: _originFilter.index,
    );
    if (mounted && selected != null) {
      setState(() => _originFilter = _OriginFilter.values[selected]);
      await _loadRemainingPagesForLocalFilters();
    }
  }

  Future<void> _loadRemainingPagesForLocalFilters() async {
    if (_periodFilter == _PeriodFilter.all &&
        _originFilter == _OriginFilter.all) {
      return;
    }
    final requestId = _requestId;
    while (mounted &&
        requestId == _requestId &&
        _hasNext &&
        _errorMessage == null) {
      if (_isLoading || _isLoadingMore) return;
      final nextPage = _nextPage;
      await _loadPrograms();
      if (_nextPage == nextPage) return;
    }
  }

  Future<void> _selectSort() async {
    final selected = await _showFilterSheet(
      title: '정렬',
      labels: const ['최신순', '종료 임박순'],
      selected: _sort.index,
    );
    if (!mounted || selected == null) return;
    setState(() => _sort = _ManageSort.values[selected]);
    await _reloadPrograms();
  }

  void _openSearch() {
    setState(() => _searchMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() => _searchMode = false);
    _reloadPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: _searchMode
          ? null
          : FloatingActionButton(
              key: const Key('program-manage-create'),
              onPressed: _openProgramCreate,
              backgroundColor: AppColors.gray900,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: AppColors.white),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_searchMode)
              AppBarWidget(
                centerType: AppBarCenterType.text,
                leadingIcon: 'arrow_left.svg',
                center: '프로그램 관리',
                onLeadingTap: () => Navigator.pop(context),
                trailing: GestureDetector(
                  key: const Key('program-manage-search'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _openSearch,
                  child: SizedBox(
                    width: 24.r,
                    height: 24.r,
                    child: SvgPicture.asset(
                      'assets/icons/search.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.gray900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            if (_searchMode)
              ColoredBox(
                color: AppColors.white,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 20.w, 12.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _closeSearch,
                        icon: const Icon(Icons.arrow_back_ios_new),
                      ),
                      Expanded(
                        child: _ProgramSearchField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onClear: () => _searchController.clear(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_searchMode)
              ColoredBox(
                color: AppColors.white,
                child: FilterList(
                  verticalPadding: 8,
                  listOfChip: [
                    _FilterButton(
                      label: ['전체', '진행중', '진행예정', '종료'][_periodFilter.index],
                      onTap: _selectPeriod,
                    ),
                    _FilterButton(
                      label: ['일반·큐레이션', '일반', '큐레이션'][_originFilter.index],
                      onTap: _selectOrigin,
                    ),
                    _FilterButton(
                      label: ['최신순', '종료 임박순'][_sort.index],
                      onTap: _selectSort,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ColoredBox(
                color: _searchMode
                    ? AppColors.white
                    : AppColors.backgroundNormal,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_searchMode && _searchController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final visiblePrograms = _visiblePrograms;
    if (_isLoading && _programs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }

    if (_errorMessage != null && _programs.isEmpty) {
      return _ProgramMessageState(
        message: _errorMessage!,
        buttonText: '다시 시도',
        onTap: _reloadPrograms,
      );
    }

    if (visiblePrograms.isEmpty) {
      return const _ProgramMessageState(message: '검색된 프로그램이 없어요.');
    }

    return RefreshIndicator(
      backgroundColor: AppColors.backgroundNormal,
      color: AppColors.gray900,
      onRefresh: _reloadPrograms,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 40.h),
        itemCount: visiblePrograms.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            if (_searchMode) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                '${_periodFilter == _PeriodFilter.all && _originFilter == _OriginFilter.all ? _totalElements : visiblePrograms.length}개',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            );
          }
          if (index == visiblePrograms.length + 1) {
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
          final program = visiblePrograms[index - 1];
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
  const _ProgramSearchField({
    required this.controller,
    required this.onClear,
    required this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onClear;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.gray900,
        style: AppTypography.body1.copyWith(color: AppColors.gray900),
        decoration: InputDecoration(
          hintText: '프로그램 검색',
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: FilterChipWidget(
      text: label,
      textColor: AppColors.gray900,
      backgroundColor: AppColors.white,
      outlineColor: AppColors.lineStrong,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
      textStyle: AppTypography.button4,
      trailing: Icon(
        Icons.keyboard_arrow_down,
        size: 15.r,
        color: AppColors.gray500,
      ),
    ),
  );
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
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(9.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 76.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: program.imageUrls.isEmpty
                            ? _imagePlaceholder()
                            : Image.network(
                                program.imageUrls.first,
                                width: 60.r,
                                height: 76.r,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _imagePlaceholder(),
                              ),
                      ),
                      if (program.hasCurator)
                        Positioned(
                          left: 3.w,
                          bottom: 3.h,
                          child: SvgPicture.asset(
                            'assets/icons/curator_badge.svg',
                            width: 18.r,
                            height: 18.r,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline1,
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          _location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          program.cardDateText.isEmpty
                              ? '날짜 미정'
                              : program.cardDateText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onMoreTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
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
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 60.r,
    height: 76.r,
    color: AppColors.gray100,
    child: const Icon(Icons.image_outlined, color: AppColors.gray400),
  );
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
