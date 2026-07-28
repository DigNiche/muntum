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
        Text(program.title, style: AppTypography.title1),
        SizedBox(height: 20.h),
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
      ],
    );
  }
}
