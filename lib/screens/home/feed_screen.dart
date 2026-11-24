import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/search_screen.dart';
import 'package:muntum/services/analytics_service.dart';

/// Shows the feed layout while its editor content endpoints are unavailable.
class FeedScreen extends StatefulWidget {
  /// Creates the feed independently of the Explore data requests.
  const FeedScreen({super.key, required this.isActive});

  /// Whether the feed tab is selected.
  final bool isActive;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isActive) _logTabView();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _logTabView();
  }

  void _logTabView() {
    unawaited(AnalyticsService.instance.logHomeTabView('all'));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: AppColors.white,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top),
            PageHeader(
              title: Text(
                '피드',
                style: AppTypography.title2.copyWith(color: AppColors.gray900),
              ),
              icon: GestureDetector(
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                child: SvgPicture.asset(
                  'assets/icons/search.svg',
                  width: 24.w,
                  height: 24.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray900,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _EditorPickPlaceholder(),
                  SizedBox(height: 24.h),
                  Divider(
                    height: 8.h,
                    thickness: 8.h,
                    color: AppColors.lineNormal,
                  ),
                  const _EditorNotePlaceholder(),
                  const Divider(height: 1, color: AppColors.lineNormal),
                  const _EditorNotePlaceholder(),
                  const Divider(height: 1, color: AppColors.lineNormal),
                  const _EditorNotePlaceholder(hasImages: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorPickPlaceholder extends StatelessWidget {
  const _EditorPickPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cardWidth = math.min(330.w, 520.0);
    final cardHeight = cardWidth * 248 / 330;
    return SizedBox(
      height: cardHeight,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        children: [
          for (var index = 0; index < 2; index++) ...[
            SkeletonBlock(
              key: ValueKey('editor-pick-placeholder-$index'),
              width: cardWidth,
              height: cardHeight,
              radius: 10.r,
            ),
            SizedBox(width: 16.w),
          ],
          SizedBox(
            width: 160.w,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: const BoxDecoration(
                    color: AppColors.gray100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/curator_note_next_arrow.svg',
                    width: 16.r,
                    height: 16.r,
                    colorFilter: const ColorFilter.mode(
                      AppColors.gray700,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  '에디터픽 전체보기',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorNotePlaceholder extends StatelessWidget {
  const _EditorNotePlaceholder({this.hasImages = true});

  final bool hasImages;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        key: ValueKey(
          hasImages
              ? 'editor-note-placeholder'
              : 'editor-note-text-placeholder',
        ),
        padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 36.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 12.w,
              children: [
                SkeletonBlock(width: 40.r, height: 40.h, radius: 999),
                Column(
                  spacing: 6.h,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 48.w, height: 14.h),
                    SkeletonBlock(width: 82.w, height: 12.h),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              height: 36.h,
              child: Column(
                spacing: 6.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: double.infinity, height: 14.h),
                  SkeletonBlock(width: 160.w, height: 14.h),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 88.h,
              child: Column(
                spacing: 10.h,
                children: List.generate(
                  4,
                  (_) => SkeletonBlock(width: double.infinity, height: 12.h),
                ),
              ),
            ),
            if (hasImages) ...[
              SizedBox(height: 16.h),
              Row(
                spacing: 8.w,
                children: List.generate(
                  3,
                  (_) => SkeletonBlock(width: 80.w, height: 106.h, radius: 8.r),
                ),
              ),
            ],
            SizedBox(height: 12.h),
            SkeletonBlock(width: double.infinity, height: 68.h, radius: 10.r),
            SizedBox(height: 12.h),
            SkeletonBlock(width: 34.w, height: 16.h),
          ],
        ),
      ),
    );
  }
}
