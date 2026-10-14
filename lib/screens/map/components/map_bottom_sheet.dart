import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/cards/map_horizontal_card.dart';
import 'package:muntum/models/program_model.dart';

class MapProgramBottomPanel extends StatelessWidget {
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;
  final double minChildSize;
  final double maxChildSize;
  final List<double> snapSizes;
  final List<ProgramModel> programs;
  final ValueChanged<ProgramModel>? onProgramTap;

  const MapProgramBottomPanel({
    super.key,
    required this.scrollController,
    required this.sheetController,
    required this.minChildSize,
    required this.maxChildSize,
    this.snapSizes = const [],
    required this.programs,
    this.onProgramTap,
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
            color: const Color(0xFF10110F).withValues(alpha: 0.08),
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
            onTap: () {
              if (!sheetController.isAttached) return;
              final sizes = _snapSizes;
              _animateTo(
                sheetController.size <= minChildSize + 0.01
                    ? sizes[1]
                    : minChildSize,
              );
            },
            onVerticalDragUpdate: (details) {
              if (!sheetController.isAttached) {
                return;
              }
              final nextSize =
                  sheetController.size -
                  sheetController.pixelsToSize(details.primaryDelta!);
              sheetController.jumpTo(
                nextSize.clamp(minChildSize, maxChildSize),
              );
            },
            onVerticalDragEnd: (details) {
              if (!sheetController.isAttached) {
                return;
              }
              final sizes = _snapSizes;
              final current = sheetController.size;
              final velocity = details.primaryVelocity ?? 0;
              final targets = velocity > 300
                  ? sizes.where((size) => size < current - 0.001).toList()
                  : velocity < -300
                  ? sizes.where((size) => size > current + 0.001).toList()
                  : sizes;
              _animateTo(
                (targets.isEmpty ? sizes : targets).reduce(
                  (a, b) => (a - current).abs() <= (b - current).abs() ? a : b,
                ),
              );
            },
            child: SizedBox(
              height: 32.h,
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
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    0,
                    20.w,
                    programs.isEmpty ? 0 : 20.h,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        '프로그램 ${programs.length}개',
                        style: AppTypography.headline2.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      for (var index = 0; index < programs.length; index++) ...[
                        MapHorizontalCard(
                          program: programs[index],
                          entrySource: 'map',
                          onTap: onProgramTap == null
                              ? null
                              : () => onProgramTap!(programs[index]),
                        ),
                        if (index != programs.length - 1)
                          SizedBox(height: 16.h),
                      ],
                    ]),
                  ),
                ),
                if (programs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        "근처에 프로그램이 없어요.\n지도를 움직여 다른 지역을 탐색해보세요.",
                        style: AppTypography.body2.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> get _snapSizes =>
      ({minChildSize, ...snapSizes, maxChildSize}.toList()..sort());

  void _animateTo(double size) {
    sheetController.animateTo(
      size,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}
