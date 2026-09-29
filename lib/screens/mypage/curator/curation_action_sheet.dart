import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

enum CurationAction { edit, delete }

Future<CurationAction?> showCurationActionSheet(BuildContext context) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return showCupertinoModalPopup<CurationAction>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext, CurationAction.edit),
            child: const Text(
              '수정하기',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(sheetContext, CurationAction.delete),
            child: const Text('삭제하기'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text(
            '취소',
            style: TextStyle(color: CupertinoColors.activeBlue),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<CurationAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.dimMedium,
    builder: (sheetContext) => Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 40.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionItem(
            text: '수정하기',
            onTap: () => Navigator.pop(sheetContext, CurationAction.edit),
          ),
          _ActionItem(
            text: '삭제하기',
            color: AppColors.error,
            onTap: () => Navigator.pop(sheetContext, CurationAction.delete),
          ),
          _ActionItem(text: '취소', onTap: () => Navigator.pop(sheetContext)),
        ],
      ),
    ),
  );
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.text, required this.onTap, this.color});

  final String text;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 52.h,
      child: Center(
        child: Text(
          text,
          style: AppTypography.button2.copyWith(
            color: color ?? AppColors.gray900,
          ),
        ),
      ),
    ),
  );
}
