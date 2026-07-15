import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/cards/vertical_card.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/services/scrap_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';

class BookmarkScreen extends StatefulWidget {
  final List<ProgramModel>? programs;
  final bool isActive;

  const BookmarkScreen({super.key, this.programs, this.isActive = true});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  late Future<bool> _isLoggedInFuture;
  final ScrollController _scrollController = ScrollController();
  final List<ProgramModel> _programs = [];
  int _nextPage = 0;
  int _totalElements = 0;
  bool _hasNextPage = true;
  bool _isLoading = false;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = _isLoggedIn();
    _scrollController.addListener(_onScroll);
    ProgramScrapStore.instance.addListener(_syncProgramsFromScrapStore);
    _loadPrograms(reset: true);
  }

  @override
  void dispose() {
    ProgramScrapStore.instance.removeListener(_syncProgramsFromScrapStore);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncProgramsFromScrapStore() {
    if (!mounted || !_loadedOnce) return;

    final storedPrograms = ProgramScrapStore.instance.scrappedPrograms;
    final storedIds = storedPrograms.map((program) => program.id).toSet();
    final currentIds = _programs.map((program) => program.id).toSet();
    final removedCount = currentIds.difference(storedIds).length;
    final addedPrograms = storedPrograms
        .where((program) => !currentIds.contains(program.id))
        .toList();

    if (removedCount == 0 && addedPrograms.isEmpty) return;

    setState(() {
      _programs.removeWhere((program) => !storedIds.contains(program.id));
      _programs.insertAll(0, addedPrograms);
      _totalElements += addedPrograms.length - removedCount;
      if (_totalElements < 0) _totalElements = 0;
    });
  }

  @override
  void didUpdateWidget(covariant BookmarkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programs != widget.programs ||
        (!oldWidget.isActive && widget.isActive)) {
      _loadPrograms(reset: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      _loadPrograms();
    }
  }

  Future<void> _loadPrograms({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasNextPage)) return;
    if (!await _isLoggedIn()) {
      if (mounted) setState(() => _loadedOnce = true);
      return;
    }
    if (reset) {
      _nextPage = 0;
      _hasNextPage = true;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await ScrapService().fetchMyScraps(
        page: _nextPage,
        size: 20,
        syncStore: false,
      );
      final merged = reset
          ? <ProgramModel>[]
          : List<ProgramModel>.from(_programs);
      final ids = merged.map((program) => program.id).toSet();
      for (final program in response.content) {
        if (ids.add(program.id)) merged.add(program);
      }
      ProgramScrapStore.instance.replaceScrappedPrograms(merged, notify: false);
      if (!mounted) return;
      setState(() {
        _programs
          ..clear()
          ..addAll(merged);
        _totalElements = response.totalElements;
        _hasNextPage = response.hasMore;
        _nextPage = response.page + 1;
        _loadedOnce = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _isLoggedIn() async {
    final accessToken = TokenStore.instance.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) return true;
    final refreshToken = await TokenStore.instance.readRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          const PageHeader(
            firstText: '스크랩',
            icon: SizedBox.shrink(),
            firstTextColor: AppColors.black,
            showIndicator: false,
          ),
          Expanded(
            child: FutureBuilder<bool>(
              future: _isLoggedInFuture,
              builder: (context, loginSnapshot) {
                final isLoggedIn = loginSnapshot.data ?? false;
                if (loginSnapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gray900),
                  );
                }
                if (!isLoggedIn) {
                  return const _GuestBookmarkView();
                }
                if (!_loadedOnce && _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gray900),
                  );
                }
                return _programs.isEmpty
                    ? const _EmptyBookmarkView()
                    : _BookmarkGrid(
                        programs: _programs,
                        totalElements: _totalElements,
                        controller: _scrollController,
                        isLoading: _isLoading,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkGrid extends StatelessWidget {
  final List<ProgramModel> programs;
  final int totalElements;
  final ScrollController controller;
  final bool isLoading;

  const _BookmarkGrid({
    required this.programs,
    required this.totalElements,
    required this.controller,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      child: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Text(
                '프로그램 $totalElements개',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            Wrap(
              spacing: 12.w,
              runSpacing: 32.h,
              children: programs.map((program) {
                return VerticalCard(
                  program: program,
                  entrySource: 'scrap',
                  titleMaxLines: 2,
                  width:
                      ((MediaQuery.of(context).size.width - 40.w - 14.w) / 2),
                );
              }).toList(),
            ),
            if (isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.gray900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookmarkView extends StatelessWidget {
  const _EmptyBookmarkView();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 190.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/bottom_sheet/scrap.svg',
              width: 140.w,
              height: 140.w,
            ),
            SizedBox(height: 20.h),
            Text(
              '스크랩한 프로그램이 없어요.',
              style: AppTypography.title4.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 8.h),
            Text(
              '마음에 드는 프로그램을 발견하고,\n스크랩해보세요!',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBookmarkView extends StatelessWidget {
  const _GuestBookmarkView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/bottom_sheet/login_light.svg',
              width: 140.w,
              height: 140.w,
            ),
            SizedBox(height: 32.h),
            Text(
              '로그인 후 이용할 수 있어요.',
              textAlign: TextAlign.center,
              style: AppTypography.title4.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 8.h),
            Text(
              '로그인하고 마음에 드는 프로그램을\n스크랩해보세요.',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: 36.h),
            IntrinsicWidth(
              child: ButtonSolid(
                padding: EdgeInsets.fromLTRB(20.w, 11.h, 20.w, 10.h),
                text: '로그인하기',
                textColor: AppColors.white,
                boxColor: AppColors.black,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(showBackButton: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
