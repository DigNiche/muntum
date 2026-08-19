import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ProfileMenuItem extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final bool showDivider;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.onTap,
    required this.text,
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: showDivider
              ? BoxBorder.fromLTRB(
                  bottom: BorderSide(color: AppColors.lineNormal, width: 1.0.h),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTypography.button2.copyWith(color: AppColors.gray900),
            ),
            trailing ??
                SvgPicture.asset(
                  'assets/icons/arrow_right-small.svg',
                  width: 20.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray400,
                    BlendMode.srcIn,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
