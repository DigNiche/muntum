import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/home/components/appbar.dart';

class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  bool isBookmark = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.none,
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () {
              Navigator.pop(context);
            },
            trailing: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/share.svg',
                  width: 24.w,
                  color: Color(0xff1c1b1f),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: () {
                    isBookmark = !isBookmark;
                    setState(() {});
                  },
                  child: SvgPicture.asset(
                    isBookmark
                        ? 'assets/icons/scrap-filled.svg'
                        : 'assets/icons/scrap.svg',
                    width: 24.w,
                    color: Color(0xff1c1b1f),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
