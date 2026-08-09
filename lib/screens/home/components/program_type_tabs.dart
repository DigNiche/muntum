import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/app_color_transition.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_filter.dart';
import 'package:muntum/models/program_type.dart';

class ProgramTypeTabs extends StatelessWidget {
  final Filter? selectedFilter;
  final ValueChanged<Filter?> onSelected;

  const ProgramTypeTabs({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (label: '전체', filter: null),
      ...ProgramType.values.map(
        (type) => (label: type.label, filter: type.filter),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedFilter == tab.filter;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(tab.filter),
              child: AppColorTransition(
                color: isSelected ? AppColors.gray900 : AppColors.gray500,
                builder: (context, textColor, _) {
                  return AppColorTransition(
                    color: isSelected
                        ? AppColors.gray900
                        : AppColors.lineNormal,
                    builder: (context, lineColor, _) {
                      return Container(
                        height: 43.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: lineColor,
                              width: isSelected ? 2.h : 1.h,
                            ),
                          ),
                        ),
                        child: Text(
                          tab.label,
                          style: AppTypography.button2.copyWith(
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ProgramDetailFilterChips extends StatelessWidget {
  const ProgramDetailFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  final Filter? selectedFilter;
  final ValueChanged<Filter?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8.w,
      children: [
        _DetailFilterChip(
          label: '무료',
          filter: Filter.free,
          selectedFilter: selectedFilter,
          onSelected: onSelected,
        ),
        _DetailFilterChip(
          label: '이번주',
          filter: Filter.thisWeek,
          selectedFilter: selectedFilter,
          onSelected: onSelected,
        ),
        _DetailFilterChip(
          label: '예약없이',
          filter: Filter.noReservation,
          selectedFilter: selectedFilter,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _DetailFilterChip extends StatelessWidget {
  const _DetailFilterChip({
    required this.label,
    required this.filter,
    required this.selectedFilter,
    required this.onSelected,
  });

  final String label;
  final Filter filter;
  final Filter? selectedFilter;
  final ValueChanged<Filter?> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedFilter == filter;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(isSelected ? null : filter),
      child: FilterChipWidget(
        text: label,
        textColor: isSelected ? AppColors.white : AppColors.gray800,
        backgroundColor: isSelected ? AppColors.gray900 : AppColors.white,
        outlineColor: isSelected ? AppColors.gray900 : AppColors.lineStrong,
      ),
    );
  }
}
