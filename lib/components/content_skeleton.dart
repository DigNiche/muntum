import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/constants/colors.dart';

/// A neutral placeholder that reserves space without continuous motion.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius,
  });

  final double? width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.gray200,
      borderRadius: BorderRadius.circular(radius ?? 6.r),
    ),
  );
}

/// Placeholder rows sized to match the app's horizontal program cards.
class ProgramListSkeleton extends StatelessWidget {
  const ProgramListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '프로그램 불러오는 중',
    child: Column(
      spacing: 20.h,
      children: List.generate(
        count,
        (_) => Row(
          spacing: 16.w,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 110.w, height: 147.h, radius: 8.r),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Column(
                  spacing: 8.h,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 145.w, height: 17.h),
                    SkeletonBlock(width: 94.w, height: 12.h),
                    SkeletonBlock(width: 116.w, height: 12.h),
                    SkeletonBlock(width: 78.w, height: 19.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A reusable loading layout for lists and detail screens.
class PageLoadingSkeleton extends StatelessWidget {
  const PageLoadingSkeleton.programs({super.key})
    : _layout = _LoadingLayout.programs;
  const PageLoadingSkeleton.rows({super.key}) : _layout = _LoadingLayout.rows;
  const PageLoadingSkeleton.detail({super.key})
    : _layout = _LoadingLayout.detail;

  final _LoadingLayout _layout;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '콘텐츠 불러오는 중',
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: switch (_layout) {
        _LoadingLayout.programs => const ProgramListSkeleton(),
        _LoadingLayout.rows => const TextListSkeleton(),
        _LoadingLayout.detail => Column(
          spacing: 16.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 145.w, height: 24.h),
            SkeletonBlock(width: 98.w, height: 14.h),
            SkeletonBlock(width: double.infinity, height: 96.h, radius: 12.r),
            SkeletonBlock(width: double.infinity, height: 14.h),
            SkeletonBlock(width: 230.w, height: 14.h),
            SkeletonBlock(width: double.infinity, height: 14.h),
            SkeletonBlock(width: 180.w, height: 14.h),
          ],
        ),
      },
    ),
  );
}

enum _LoadingLayout { programs, rows, detail }

/// Text-row placeholders for notices, keywords, and management lists.
class TextListSkeleton extends StatelessWidget {
  const TextListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '목록 불러오는 중',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20.h,
      children: [
        for (var index = 0; index < count; index++)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8.h,
            children: [
              SkeletonBlock(width: (index.isEven ? 190 : 155).w, height: 16.h),
              SkeletonBlock(width: 95.w, height: 12.h),
            ],
          ),
      ],
    ),
  );
}
