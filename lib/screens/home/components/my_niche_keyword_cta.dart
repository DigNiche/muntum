import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class MyNicheKeywordCta extends StatelessWidget {
  final VoidCallback onTap;

  const MyNicheKeywordCta({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 64.h, bottom: 80.h),
      child: Column(
        children: [
          Text(
            '키워드를 추가하면\n더 많은 큐레이션을 받을 수 있어요!',
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
          SizedBox(height: 24.h),
          IntrinsicWidth(
            child: ButtonSolid(
              text: '키워드 추가하기',
              textColor: AppColors.gray900,
              boxColor: AppColors.primary400,
              padding: EdgeInsets.fromLTRB(20.w, 11.h, 20.w, 10.h),
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}
