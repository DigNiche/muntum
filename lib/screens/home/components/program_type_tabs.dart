import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/app_color_transition.dart';
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
