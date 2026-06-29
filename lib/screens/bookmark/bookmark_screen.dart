import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/cards/vertical_card.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/mock_program_data.dart';
import 'package:muntum/models/program_model.dart';

class BookmarkScreen extends StatefulWidget {
  final List<ProgramModel>? programs;

  const BookmarkScreen({super.key, this.programs});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  late List<ProgramModel> _bookmarkedPrograms;

  @override
  void initState() {
    super.initState();
    _setPrograms();
  }

  @override
  void didUpdateWidget(covariant BookmarkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programs != widget.programs) {
      _setPrograms();
    }
  }

  void _setPrograms() {
    _bookmarkedPrograms = List.of(widget.programs ?? mockPrograms.take(4));
    //_bookmarkedPrograms = [];
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
            child: _bookmarkedPrograms.isEmpty
                ? const _EmptyBookmarkView()
                : _BookmarkGrid(programs: _bookmarkedPrograms),
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
            Container(
              width: 140.w,
              height: 140.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: SvgPicture.asset(
                'assets/icons/scrap.svg',
                width: 40.w,
                height: 40.w,
                colorFilter: const ColorFilter.mode(
                  AppColors.gray400,
                  BlendMode.srcIn,
                ),
              ),
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
