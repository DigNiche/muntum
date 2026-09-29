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
    return FutureBuilder<List<ProgramModel>>(
      future: programsFuture,
      builder: (context, snapshot) {
        final programs = snapshot.data ?? const <ProgramModel>[];
        if (programs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader1(
                verticalPadding: 0,
                text: '같은 키워드의 프로그램',
                buttonName: '',
                onButtonTap: () {},
                horizontalPadding: 0,
              ),
              SizedBox(height: 16.h),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) => HorizontalCard(
                  program: programs[index],
                  entrySource: 'detail_recommendation',
                ),
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemCount: programs.length,
              ),
            ],
          ),
        );
      },
    );
  }
}
