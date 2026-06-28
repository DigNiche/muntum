import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/cards/horizontal.dart';

class MapProgramBottomPanel extends StatelessWidget {
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;
  final double minChildSize;
  final double maxChildSize;
  final List<String> programList;

  const MapProgramBottomPanel({
    required this.scrollController,
    required this.sheetController,
    required this.minChildSize,
    required this.maxChildSize,
    required this.programList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.radius_10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10110F).withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              if (!sheetController.isAttached) {
                return;
              }
              final screenHeight = MediaQuery.sizeOf(context).height;
              final nextSize =
                  sheetController.size - details.primaryDelta! / screenHeight;
              sheetController.jumpTo(
                nextSize.clamp(minChildSize, maxChildSize),
              );
            },
            onVerticalDragEnd: (_) {
              if (!sheetController.isAttached) {
                return;
              }
              final targetSize =
                  sheetController.size < (minChildSize + maxChildSize) / 2
                  ? minChildSize
                  : maxChildSize;
              sheetController.animateTo(
                targetSize,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            },
            child: SizedBox(
              height: 32.h,
              width: double.infinity,
              child: Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.gray400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              '프로그램 ${programList.length}개',
              style: AppTypography.headline2.copyWith(color: AppColors.gray900),
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: programList.isEmpty
                ? Center(
                    child: Text(
                      textAlign: TextAlign.center,
                      "근처에 프로그램이 없어요.\n지도를 움직여 다른 지역을 탐색해보세요.",
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    itemBuilder: (context, index) {
                      return HorizontalCard(programName: programList[index]);
                    },
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 12.h),
                    itemCount: programList.length,
                  ),
          ),
        ],
      ),
    );
  }
}
