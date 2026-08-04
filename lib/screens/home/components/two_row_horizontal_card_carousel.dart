import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/cards/map_horizontal_card.dart';
import 'package:muntum/models/program_model.dart';

class TwoRowHorizontalCardCarousel extends StatelessWidget {
  final List<ProgramModel> programs;
  final String entrySource;

  const TwoRowHorizontalCardCarousel({
    super.key,
    required this.programs,
    required this.entrySource,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 56.h),
      child: SizedBox(
        height: 230.h,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 310.w,
            mainAxisSpacing: 24.w,
            crossAxisSpacing: 16.h,
          ),
          itemCount: programs.length,
          itemBuilder: (context, index) => MapHorizontalCard(
            program: programs[index],
            entrySource: entrySource,
          ),
        ),
      ),
    );
  }
}
