import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';

class ProgramHeader extends StatelessWidget {
  final ProgramModel program;

  const ProgramHeader({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6.w,
          runSpacing: 8.h,
          children: program.keywords
              .take(3)
              .map(
                (keyword) => Label(labelType: LabelType.keyword, text: keyword),
              )
              .toList(),
        ),
        SizedBox(height: 14.h),
        Text(program.title, style: AppTypography.title1),
      ],
    );
  }
}
