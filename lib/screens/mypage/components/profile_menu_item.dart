import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ProfileMenuItem extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  const ProfileMenuItem({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: BoxBorder.fromLTRB(
            bottom: BorderSide(color: AppColors.lineNormal, width: 1.0.h),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTypography.button2.copyWith(color: AppColors.gray900),
            ),
            SvgPicture.asset(
              'assets/icons/arrow_right-small.svg',
              width: 24.w,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
