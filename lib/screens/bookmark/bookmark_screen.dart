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

class BookmarkScreen extends StatefulWidget {
  final List<ProgramModel>? programs;
  final bool isActive;

  const BookmarkScreen({super.key, this.programs, this.isActive = true});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  late Future<List<ProgramModel>> _bookmarkedProgramsFuture;
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = _isLoggedIn();
    _bookmarkedProgramsFuture = _loadPrograms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BookmarkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programs != widget.programs ||
        (!oldWidget.isActive && widget.isActive)) {
      setState(() {
        _bookmarkedProgramsFuture = _loadPrograms();
      });
    }
  }

  Future<List<ProgramModel>> _loadPrograms() async {
    if (!await _isLoggedIn()) {
      return const <ProgramModel>[];
    }

    return (await ScrapService().fetchMyScraps(size: 100)).content;
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
                return FutureBuilder<List<ProgramModel>>(
                  future: _bookmarkedProgramsFuture,
                  builder: (context, snapshot) {
                    final programs = snapshot.data ?? const <ProgramModel>[];
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gray900,
                        ),
                      );
                    }
                    return programs.isEmpty
                        ? const _EmptyBookmarkView()
                        : _BookmarkGrid(programs: programs);
                  },
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

  const _BookmarkGrid({required this.programs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Text(
                '프로그램 ${programs.length}개',
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
                  titleMaxLines: 2,
                  width:
                      ((MediaQuery.of(context).size.width - 40.w - 14.w) / 2),
                );
              }).toList(),
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
