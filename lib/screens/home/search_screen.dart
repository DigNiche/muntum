import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/components/appbar.dart';
import 'package:muntum/screens/home/components/keyword_chip.dart';
import 'package:muntum/screens/home/components/section_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.backgroundNormal,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            onLeadingTap: () {
              Navigator.pop(context);
            },
            leadingIcon: "arrow_left.svg",
            centerType: AppBarCenterType.searchbar,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
            child: Column(
              children: [
                SectionHeader2(text: '인기키워드', buttonName: '여러 키워드로 검색'),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    KeywordChip(
                      text: '색다르게 즐기는',
                      textColor: AppColors.gray800,
                      outlineColor: AppColors.lineStrong,
                    ),
                    KeywordChip(
                      text: '색다르게 즐기는',
                      textColor: AppColors.gray800,
                      outlineColor: AppColors.lineStrong,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
