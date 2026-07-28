import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';

class WentToScreen extends StatefulWidget {
  const WentToScreen({super.key});

  @override
  State<WentToScreen> createState() => _WentToScreenState();
}

class _WentToScreenState extends State<WentToScreen> {
  bool _isLikedSelected = true;

  static final _previewPrograms = List.generate(
    3,
    (index) => ProgramModel(
      id: 'went-to-preview-$index',
      title: '프로그램명',
      oneLineDescription: '',
      detail: '',
      images: const [],
      keywords: const [],
      startEndDates: 'YY.MM.DD–YY.MM.DD',
      locationName: '장소명',
      location: const {},
      availableTime: '',
      cost: '',
      isReservationNeeded: false,
      phoneNumber: '',
      link: '',
      filters: const [],
      isSpotlight: false,
      isOverThisMonth: false,
      isBookmark: false,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.none,
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 26.h),
            child: Text(
              '다녀온\n프로그램 기록',
              style: AppTypography.title3.copyWith(color: AppColors.gray900),
            ),
          ),
          _WentToTabs(
            isLikedSelected: _isLikedSelected,
            onLikedTap: () => setState(() => _isLikedSelected = true),
            onDislikedTap: () => setState(() => _isLikedSelected = false),
          ),
          if (_isLikedSelected)
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                itemCount: _previewPrograms.length,
                separatorBuilder: (_, _) => SizedBox(height: 16.h),
                itemBuilder: (context, index) => HorizontalCard(
                  program: _previewPrograms[index],
                  entrySource: 'went_to_preview',
                  onTap: () {},
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  '기록한 프로그램이 없어요.',
                  style: AppTypography.button2.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WentToTabs extends StatelessWidget {
  final bool isLikedSelected;
  final VoidCallback onLikedTap;
  final VoidCallback onDislikedTap;

  const _WentToTabs({
    required this.isLikedSelected,
    required this.onLikedTap,
    required this.onDislikedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lineNormal)),
      ),
      child: Row(
        children: [
          _WentToTab(
            text: '좋았어요',
            isSelected: isLikedSelected,
            onTap: onLikedTap,
          ),
          _WentToTab(
            text: '아쉬웠어요',
            isSelected: !isLikedSelected,
            onTap: onDislikedTap,
          ),
        ],
      ),
    );
  }
}

class _WentToTab extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _WentToTab({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom: BorderSide(color: AppColors.gray900, width: 2.h),
                  )
                : null,
          ),
          child: Text(
            text,
            style: AppTypography.button2.copyWith(
              color: isSelected ? AppColors.gray900 : AppColors.gray500,
            ),
          ),
        ),
      ),
    );
  }
}
