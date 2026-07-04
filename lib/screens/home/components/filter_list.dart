import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class FilterList extends StatelessWidget {
  final List<Widget> listOfChip;
  const FilterList({super.key, required this.listOfChip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(spacing: 10.w, children: listOfChip),
      ),
    );
  }
}
