import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/services/program_reaction_service.dart';
import 'package:muntum/utils/app_toast.dart';

class ProgramAttendancePrompt extends StatefulWidget {
  final String programId;
  final ProgramReaction? initialReaction;

  const ProgramAttendancePrompt({
    super.key,
    required this.programId,
    required this.initialReaction,
  });

  @override
  State<ProgramAttendancePrompt> createState() =>
      _ProgramAttendancePromptState();
}

class _ProgramAttendancePromptState extends State<ProgramAttendancePrompt> {
  late ProgramReaction? _reaction;
  bool _isExpanded = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant ProgramAttendancePrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSaving) return;
    if (oldWidget.programId != widget.programId ||
        oldWidget.initialReaction != widget.initialReaction) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _reaction = widget.initialReaction;
    _isExpanded = _reaction == null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        padding: _reaction == null
            ? EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w)
            : EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
          color: AppColors.gray100,
        ),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpanded,
              child: _reaction == null
                  ? _buildQuestionHeader()
                  : _buildRecordedHeader(),
            ),
            if (_isExpanded) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _RatingButton(
                      text: '아쉬웠어요',
                      iconPath: 'assets/icons/thumb_down.svg',
                      selectedIconPath: 'assets/icons/thumb_down_filled.svg',
                      isSelected: _reaction == ProgramReaction.dislike,
                      onTap: () => _selectReaction(ProgramReaction.dislike),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _RatingButton(
                      text: '좋았어요',
                      iconPath: 'assets/icons/thumb_up.svg',
                      selectedIconPath: 'assets/icons/thumb_up_filled.svg',
                      isSelected: _reaction == ProgramReaction.like,
                      onTap: () => _selectReaction(ProgramReaction.like),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 프로그램 다녀오셨나요?',
              style: AppTypography.button2.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 4.h),
            Text(
              '평가하고 취향을 기록해보세요!',
              style: AppTypography.button3.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
        _buildArrow(),
      ],
    );
  }

  Widget _buildRecordedHeader() {
    final isLiked = _reaction == ProgramReaction.like;
    return Row(
      children: [
        SvgPicture.asset(
          isLiked ? 'assets/liked.svg' : 'assets/disliked.svg',
          width: 24.r,
          height: 24.r,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            isLiked ? '"좋았어요!"로 기록했어요' : '"아쉬웠어요"로 기록했어요',
            style: AppTypography.button2.copyWith(color: AppColors.gray900),
          ),
        ),
        _buildArrow(),
      ],
    );
  }

  Widget _buildArrow() {
    return SvgPicture.asset(
      _isExpanded ? 'assets/icons/arrow_up.svg' : 'assets/icons/arrow_down.svg',
      width: 24.r,
      height: 24.r,
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _selectReaction(ProgramReaction selectedReaction) async {
    if (_isSaving || widget.programId.isEmpty) return;
    final previousReaction = _reaction;
    final nextReaction = previousReaction == selectedReaction
        ? null
        : selectedReaction;

    setState(() {
      _reaction = nextReaction;
      _isExpanded = nextReaction == null;
      _isSaving = true;
    });

    try {
      final savedReaction = await ProgramReactionService().updateReaction(
        programId: widget.programId,
        reaction: nextReaction,
      );
      if (!mounted) return;
      setState(() {
        _reaction = savedReaction;
        _isExpanded = savedReaction == null;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reaction = previousReaction;
        _isExpanded = previousReaction == null;
        _isSaving = false;
      });
      showAppToast(context, '기록을 저장하지 못했어요. 다시 시도해주세요.', isError: true);
    }
  }
}

class _RatingButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final String selectedIconPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingButton({
    required this.text,
    required this.iconPath,
    required this.selectedIconPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? AppColors.white : AppColors.gray400;
    final textColor = isSelected ? AppColors.white : AppColors.gray800;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray900 : AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              isSelected ? selectedIconPath : iconPath,
              width: 18.r,
              height: 18.r,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            SizedBox(width: 6.w),
            Text(text, style: AppTypography.button3.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}
