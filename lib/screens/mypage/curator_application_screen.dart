import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';

class CuratorApplicationScreen extends StatelessWidget {
  const CuratorApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '큐레이터 지원/내역',
            onLeadingTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
