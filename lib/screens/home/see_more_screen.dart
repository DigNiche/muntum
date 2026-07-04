import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/data/mock_program_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/utils/program_query.dart';

enum SeeMoreType { allPrograms, endingThisMonth }

class SeeMoreScreen extends StatefulWidget {
  final SeeMoreType type;

  const SeeMoreScreen({super.key, required this.type});

  String get title => switch (type) {
    SeeMoreType.allPrograms => '모아보기',
    SeeMoreType.endingThisMonth => '이번달에 끝나는',
  };

  @override
  State<SeeMoreScreen> createState() => _SeeMoreScreenState();
}

class _SeeMoreScreenState extends State<SeeMoreScreen> {
  static const _filterOptions = [
    (filter: Filter.free, label: '무료'),
    (filter: Filter.thisWeek, label: '이번주'),
    (filter: Filter.noReservation, label: '예약없이'),
    (filter: Filter.exhibition, label: '전시'),
    (filter: Filter.show, label: '공연'),
    (filter: Filter.experience, label: '체험'),
    (filter: Filter.festival, label: '축제'),
  ];

  Filter? _selectedFilter;

  List<ProgramModel> get _sourcePrograms => switch (widget.type) {
    SeeMoreType.allPrograms => mockPrograms,
    SeeMoreType.endingThisMonth =>
      mockPrograms.where((program) => program.isOverThisMonth).toList(),
  };

  List<ProgramModel> get _visiblePrograms => queryPrograms(
    _sourcePrograms,
    filters: _selectedFilter == null ? const {} : {_selectedFilter!},
  );

  void _toggleFilter(Filter filter) {
    setState(() {
      _selectedFilter = _selectedFilter == filter ? null : filter;
    });
  }

  Widget _buildFilterChip(Filter filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _toggleFilter(filter),
      child: FilterChipWidget(
        text: label,
        textColor: isSelected ? AppColors.gray900 : AppColors.gray700,
        backgroundColor: AppColors.white,
        outlineColor: isSelected ? AppColors.gray900 : AppColors.lineStrong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programs = _visiblePrograms;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.text,
              leadingIcon: 'arrow_left.svg',
              onLeadingTap: () => Navigator.pop(context),
              center: widget.title,
            ),
            FilterList(
              listOfChip: _filterOptions
                  .map(
                    (option) => _buildFilterChip(option.filter, option.label),
                  )
                  .toList(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
              child: Text(
                '프로그램 ${programs.length}개',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
            Expanded(
              child: programs.isEmpty
                  ? Center(
                      child: Text(
                        '조건에 맞는 프로그램이 없어요.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                      itemCount: programs.length,
                      itemBuilder: (context, index) =>
                          HorizontalCard(program: programs[index]),
                      separatorBuilder: (_, _) => SizedBox(height: 16.h),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
