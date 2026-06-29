import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

// HeaderItem
class HeaderTabItem extends StatelessWidget {
  final String text;
  final Color textColor;
  final VoidCallback? onTap;
  const HeaderTabItem({
    super.key,
    required this.text,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: AppTypography.title2.copyWith(color: textColor)),
    );
  }
}

// Header
class PageHeader extends StatelessWidget {
  final String firstText;
  final VoidCallback? onFirstTextTap;
  final Color firstTextColor;
  final VoidCallback? onSecondTextTap;
  final String? secondText;
  final Color? secondTextColor;
  final Widget icon;
  final bool showIndicator;
  const PageHeader({
    super.key,
    required this.firstText,
    this.onFirstTextTap,
    this.onSecondTextTap,
    this.secondText,
    required this.icon,
    required this.firstTextColor,
    this.secondTextColor,
    required this.showIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showIndicator)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    HeaderTabItem(
                      text: firstText,
                      textColor: AppColors.gray300,
                      onTap: onFirstTextTap,
                    ),
                    Positioned(
                      right: -5.w,
                      child: Container(
                        width: 4.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary400,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              if (!showIndicator)
                HeaderTabItem(
                  text: firstText,
                  textColor: firstTextColor,
                  onTap: onFirstTextTap,
                ),
              if (secondText != null) SizedBox(width: 20.w),
              if (secondText != null)
                HeaderTabItem(
                  text: secondText!,
                  textColor: secondTextColor!,
                  onTap: onSecondTextTap,
                ),
            ],
          ),
          icon,
        ],
      ),
    );
  }
}
