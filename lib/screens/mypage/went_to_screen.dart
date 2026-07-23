import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class WentToScreen extends StatefulWidget {
  const WentToScreen({super.key});

  @override
  State<WentToScreen> createState() => _WentToScreenState();
}

class _WentToScreenState extends State<WentToScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.none,
            leadingIcon: "arrow_left.svg",
            onLeadingTap: () {
              Navigator.pop(context);
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 10.h),
            child: Row(
              children: [
                Text(
                  "다녀온\n프로그램 기록",
                  textAlign: TextAlign.left,
                  style: AppTypography.title3,
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
