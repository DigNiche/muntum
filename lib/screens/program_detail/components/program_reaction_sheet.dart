import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/services/program_reaction_service.dart';
import 'package:muntum/utils/app_toast.dart';

Future<ProgramReactionRecord?> showProgramReactionSheet({
  required BuildContext context,
  required String programId,
  required ProgramReaction? initialReaction,
  ProgramReaction? suggestedReaction,
  String? initialComment,
  ProgramReactionService? service,
}) {
  return showModalBottomSheet<ProgramReactionRecord>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
    ),
    builder: (context) => _ProgramReactionSheet(
      programId: programId,
      initialReaction: initialReaction,
      suggestedReaction: suggestedReaction,
      initialComment: initialComment,
      service: service ?? ProgramReactionService(),
    ),
  );
}

class _ProgramReactionSheet extends StatefulWidget {
  const _ProgramReactionSheet({
    required this.programId,
    required this.initialReaction,
    required this.suggestedReaction,
    required this.initialComment,
    required this.service,
  });

  final String programId;
  final ProgramReaction? initialReaction;
  final ProgramReaction? suggestedReaction;
  final String? initialComment;
  final ProgramReactionService service;

  @override
  State<_ProgramReactionSheet> createState() => _ProgramReactionSheetState();
}

class _ProgramReactionSheetState extends State<_ProgramReactionSheet> {
  late final TextEditingController _commentController;
  late ProgramReaction? _selectedReaction;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.initialComment ?? '',
    );
    _selectedReaction = widget.suggestedReaction ?? widget.initialReaction;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool delete = false}) async {
    if (_isSaving || (!delete && _selectedReaction == null)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final result = await widget.service.updateReaction(
        programId: widget.programId,
        reaction: delete ? null : _selectedReaction,
        comment: delete ? null : _commentController.text,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAppToast(context, '기록을 저장하지 못했어요. 다시 시도해주세요.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '기록 남기기',
                    style: AppTypography.headline1.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('delete-visit-record'),
                    onPressed: widget.initialReaction == null || _isSaving
                        ? null
                        : () => _submit(delete: true),
                    child: Text(
                      '기록 삭제',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetReactionButton(
                    reaction: ProgramReaction.like,
                    selected: _selectedReaction == ProgramReaction.like,
                    onTap: () => setState(
                      () => _selectedReaction = ProgramReaction.like,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  _SheetReactionButton(
                    reaction: ProgramReaction.dislike,
                    selected: _selectedReaction == ProgramReaction.dislike,
                    onTap: () => setState(
                      () => _selectedReaction = ProgramReaction.dislike,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              TextField(
                key: const ValueKey('visit-comment-input'),
                controller: _commentController,
                autofocus: true,
                cursorColor: AppColors.gray900,
                maxLength: 500,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '어떤 점이 가장 기억에 남았나요?',
                  hintStyle: AppTypography.body2.copyWith(
                    color: AppColors.gray400,
                  ),
                  counterText: '',
                  contentPadding: EdgeInsets.all(14.r),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.lineStrong),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.lineStrong),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.gray400),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ButtonSolid(
                        key: const ValueKey('cancel-visit-record'),
                        text: '취소',
                        textColor: AppColors.gray900,
                        boxColor: AppColors.white,
                        border: Border.all(color: AppColors.lineStrong),
                        padding: EdgeInsets.zero,
                        onTap: _isSaving ? null : () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ButtonSolid(
                        key: const ValueKey('save-visit-record'),
                        text: '저장하기',
                        textColor: _isSaving || _selectedReaction == null
                            ? AppColors.gray400
                            : AppColors.white,
                        boxColor: _isSaving || _selectedReaction == null
                            ? AppColors.gray200
                            : AppColors.black,
                        padding: EdgeInsets.zero,
                        onTap: _isSaving || _selectedReaction == null
                            ? null
                            : _submit,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetReactionButton extends StatelessWidget {
  const _SheetReactionButton({
    required this.reaction,
    required this.selected,
    required this.onTap,
  });

  final ProgramReaction reaction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final liked = reaction == ProgramReaction.like;
    final label = liked ? '좋았어요!' : '아쉬웠어요';
    return GestureDetector(
      key: ValueKey(liked ? 'sheet-like' : 'sheet-dislike'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64.w,
        child: Column(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.gray900 : AppColors.gray300,
              ),
              child: SvgPicture.asset(
                liked
                    ? 'assets/icons/thumb_up_filled.svg'
                    : 'assets/icons/thumb_down_filled.svg',
                width: 23.r,
                height: 23.r,
                colorFilter: const ColorFilter.mode(
                  AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            if (selected)
              Text(
                label,
                style: AppTypography.caption2.copyWith(
                  color: AppColors.gray900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
