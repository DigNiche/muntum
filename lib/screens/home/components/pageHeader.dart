import 'package:flutter/material.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

enum TabTextColor { black, gray300, white, gray500 }

class HeaderTabItem extends StatelessWidget {
  final String text;
  final TabTextColor textColor;
  final VoidCallback? onTap;
  const HeaderTabItem({
    super.key,
    required this.text,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (textColor) {
      case TabTextColor.black:
        color = AppColors.black;
        break;
      case TabTextColor.gray300:
        color = AppColors.gray300;
        break;
      case TabTextColor.white:
        color = AppColors.white;
        break;
      case TabTextColor.gray500:
        color = AppColors.gray500;
    }

    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: AppTypography.title2.copyWith(color: color)),
    );
  }
}
