import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '다녀온 기록을 남길 수 있어요',
            style: AppTypography.headline3.copyWith(color: AppColors.gray600),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReactionButton(
                semanticsLabel: '좋았어요',
                text: '좋았어요!',
                iconPath: 'assets/icons/thumb_up_filled.svg',
                isSelected: _reaction == ProgramReaction.like,
                onTap: () => _selectReaction(ProgramReaction.like),
              ),
              SizedBox(width: 20.w),
              _ReactionButton(
                semanticsLabel: '아쉬웠어요',
                text: '아쉬웠어요',
                iconPath: 'assets/icons/thumb_down_filled.svg',
                isSelected: _reaction == ProgramReaction.dislike,
                onTap: () => _selectReaction(ProgramReaction.dislike),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectReaction(ProgramReaction selectedReaction) async {
    if (_isSaving || widget.programId.isEmpty) return;
    final previousReaction = _reaction;
    final nextReaction = previousReaction == selectedReaction
        ? null
        : selectedReaction;

    setState(() {
      _reaction = nextReaction;
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
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reaction = previousReaction;
        _isSaving = false;
      });
      showAppToast(context, '기록을 저장하지 못했어요. 다시 시도해주세요.', isError: true);
    }
  }
}

class _ReactionButton extends StatelessWidget {
  final String semanticsLabel;
  final String text;
  final String iconPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.semanticsLabel,
    required this.text,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.gray900 : AppColors.gray300,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                iconPath,
                width: 24.r,
                height: 24.r,
                colorFilter: const ColorFilter.mode(
                  AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            SizedBox(
              height: 20.h,
              child: isSelected
                  ? Text(
                      text,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray800,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
