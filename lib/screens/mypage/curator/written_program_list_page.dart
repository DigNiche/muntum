import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/app_color_transition.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';

class WrittenProgramList extends StatefulWidget {
  const WrittenProgramList({super.key});

  @override
  State<WrittenProgramList> createState() => _WrittenProgramListState();
}

class _WrittenProgramListState extends State<WrittenProgramList> {
  static const _programs = [
    _WrittenProgram(id: 1, status: _WrittenProgramStatus.scheduled),
    _WrittenProgram(id: 2, status: _WrittenProgramStatus.ongoing),
    _WrittenProgram(id: 3, status: _WrittenProgramStatus.ongoing),
    _WrittenProgram(id: 4, status: _WrittenProgramStatus.ended),
    _WrittenProgram(id: 5, status: _WrittenProgramStatus.ended),
  ];

  _WrittenProgramStatus? _selectedStatus;

  List<_WrittenProgram> get _visiblePrograms => _selectedStatus == null
      ? _programs
      : _programs
            .where((program) => program.status == _selectedStatus)
            .toList();

  void _openProgramWriter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramEditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            center: '프로그램 작성내역',
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () => Navigator.pop(context),
            trailing: GestureDetector(
              key: const ValueKey('written-program-add'),
              behavior: HitTestBehavior.opaque,
              onTap: _openProgramWriter,
              child: SizedBox(
                width: 24.w,
                height: 24.h,
                child: SvgPicture.asset(
                  'assets/icons/plus.svg',
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray900,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: const _ProgramSummary(),
          ),
          _ProgramStatusTabs(
            selectedStatus: _selectedStatus,
            onSelected: (status) => setState(() => _selectedStatus = status),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _ProgramList(
                key: ValueKey(_selectedStatus),
                programs: _visiblePrograms,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramSummary extends StatelessWidget {
  const _ProgramSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96.h,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _SummaryItem(value: '5', label: '등록 프로그램'),
          ),
          _SummaryDivider(),
          Expanded(
            child: _SummaryItem(value: '36', label: '유저 스크랩'),
          ),
          _SummaryDivider(),
          Expanded(
            child: _SummaryItem(value: '17', label: '받은 ‘좋았어요’'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTypography.title2.copyWith(color: AppColors.gray900),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTypography.caption1.copyWith(color: AppColors.gray600),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1.w, height: 48.h, color: AppColors.lineStrong);
  }
}

class _ProgramStatusTabs extends StatelessWidget {
  const _ProgramStatusTabs({
    required this.selectedStatus,
    required this.onSelected,
  });

  final _WrittenProgramStatus? selectedStatus;
  final ValueChanged<_WrittenProgramStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lineNormal)),
      ),
      child: Row(
        children: [
          _ProgramStatusTab(
            label: '전체',
            isSelected: selectedStatus == null,
            onTap: () => onSelected(null),
          ),
          _ProgramStatusTab(
            label: '진행예정',
            isSelected: selectedStatus == _WrittenProgramStatus.scheduled,
            onTap: () => onSelected(_WrittenProgramStatus.scheduled),
          ),
          _ProgramStatusTab(
            label: '진행중',
            isSelected: selectedStatus == _WrittenProgramStatus.ongoing,
            onTap: () => onSelected(_WrittenProgramStatus.ongoing),
          ),
          _ProgramStatusTab(
            label: '종료',
            isSelected: selectedStatus == _WrittenProgramStatus.ended,
            onTap: () => onSelected(_WrittenProgramStatus.ended),
          ),
        ],
      ),
    );
  }
}

class _ProgramStatusTab extends StatelessWidget {
  const _ProgramStatusTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        key: ValueKey('written-program-tab-$label'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AppColorTransition(
          color: isSelected ? AppColors.gray900 : AppColors.gray500,
          builder: (context, textColor, _) {
            return AppColorTransition(
              color: isSelected ? AppColors.gray900 : AppColors.lineNormal,
              builder: (context, lineColor, _) {
                return Container(
                  height: 48.h,
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
                    label,
                    style: AppTypography.button2.copyWith(color: textColor),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProgramList extends StatelessWidget {
  const _ProgramList({super.key, required this.programs});

  final List<_WrittenProgram> programs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
      itemCount: programs.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, thickness: 1, color: AppColors.lineNormal),
      itemBuilder: (context, index) => _ProgramListItem(
        key: ValueKey('written-program-${programs[index].id}'),
      ),
    );
  }
}

class _ProgramListItem extends StatelessWidget {
  const _ProgramListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프로그램 명',
                  style: AppTypography.headline1.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '(운영기간) YYYY.MM.DD - YYYY.MM.DD',
                  style: AppTypography.body3.copyWith(color: AppColors.gray600),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/location.svg',
                      width: 16.r,
                      height: 16.r,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gray400,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '위치 정보',
                      style: AppTypography.body3.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(Icons.more_vert, size: 20.r, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}

enum _WrittenProgramStatus { scheduled, ongoing, ended }

class _WrittenProgram {
  const _WrittenProgram({required this.id, required this.status});

  final int id;
  final _WrittenProgramStatus status;
}
