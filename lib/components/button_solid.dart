import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/typography.dart';

class ButtonSolid extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color boxColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final Widget? leading;
  const ButtonSolid({
    super.key,
    required this.text,
    required this.textColor,
    required this.boxColor,
    this.onTap,
    this.padding,
    this.border,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? EdgeInsets.fromLTRB(26.w, 14.h, 26.w, 13.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.radius_8),
          color: boxColor,
          border: border,
        ),
        child: leading == null
            ? Center(child: _buildText())
            : Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Center(child: _buildText()),
                  Positioned(left: 0, child: leading!),
                ],
              ),
      ),
    );
  }

  Widget _buildText() {
    return Text(
      text,
      style: AppTypography.button1.copyWith(color: textColor),
      maxLines: 1,
    );
  }
}
