import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/cards/vertical_card.dart';
import 'package:muntum/models/program_model.dart';

class VerticalCardCarousel extends StatefulWidget {
  final List<ProgramModel> programs;

  const VerticalCardCarousel({super.key, required this.programs});

  @override
  State<VerticalCardCarousel> createState() => _VerticalCardCarouselState();
}

class _VerticalCardCarouselState extends State<VerticalCardCarousel> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 343.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.programs.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 160.w,
            child: VerticalCard(program: widget.programs[index]),
          );
        },
      ),
    );
  }
}
