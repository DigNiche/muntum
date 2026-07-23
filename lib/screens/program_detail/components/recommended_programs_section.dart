import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/section_header.dart';

class RecommendedProgramsSection extends StatelessWidget {
  final Future<List<ProgramModel>> programsFuture;

  const RecommendedProgramsSection({super.key, required this.programsFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader1(
          text: '지금 주목받는',
          buttonName: '',
          onButtonTap: () {},
          horizontalPadding: 0,
        ),
        SizedBox(height: 8.h),
        FutureBuilder<List<ProgramModel>>(
          future: programsFuture,
          builder: (context, snapshot) {
            final programs = snapshot.data ?? const <ProgramModel>[];
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) => HorizontalCard(
                program: programs[index],
                entrySource: 'detail_recommendation',
              ),
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemCount: programs.length,
            );
          },
        ),
      ],
    );
  }
}
