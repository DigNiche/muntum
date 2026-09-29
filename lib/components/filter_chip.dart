import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/app_color_transition.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/typography.dart';

class FilterChipWidget extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final Color? outlineColor;
  final bool? hasShadow;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Widget? trailing;
  const FilterChipWidget({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    this.outlineColor,
    this.hasShadow,
    this.padding,
    this.textStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShowShadow = hasShadow == true;
    return AppColorTransition(
      color: backgroundColor,
      builder: (context, animatedBackgroundColor, _) {
        return AppColorTransition(
          color: textColor,
          builder: (context, animatedTextColor, _) {
            return AppColorTransition(
              color: outlineColor ?? backgroundColor,
              builder: (context, animatedOutlineColor, _) {
                return Container(
                  padding:
                      padding ??
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: animatedBackgroundColor,
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.radius_8,
                    ),
                    border: outlineColor == null
                        ? null
                        : Border.all(color: animatedOutlineColor, width: 1.sp),
                    boxShadow: shouldShowShadow
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF10110F,
                              ).withValues(alpha: 0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: (textStyle ?? AppTypography.button3).copyWith(
                          color: animatedTextColor,
                        ),
                      ),
                      if (trailing != null) ...[
                        SizedBox(width: 4.w),
                        trailing!,
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
