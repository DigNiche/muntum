import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/cards/vertical_card.dart';
import 'package:muntum/models/program_model.dart';

class VerticalCardCarousel extends StatefulWidget {
  final List<ProgramModel> programs;
  final String entrySource;

  const VerticalCardCarousel({
    super.key,
    required this.programs,
    this.entrySource = 'all',
  });

  @override
  State<VerticalCardCarousel> createState() => _VerticalCardCarouselState();
}

class _VerticalCardCarouselState extends State<VerticalCardCarousel> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 48.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.w,
          children: widget.programs
              .map(
                (program) => VerticalCard(
                  program: program,
                  entrySource: widget.entrySource,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
