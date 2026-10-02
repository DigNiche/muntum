import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AppTypography {
  static const String _fontFamily = 'SUIT';

  static TextStyle _style({
    required double fontSize,
    required double lineHeight,
    required double letterSpacingPercent,
    required FontWeight fontWeight,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      height: lineHeight,
      letterSpacing: fontSize * letterSpacingPercent / 100,
      fontWeight: fontWeight,
    );
  }

  // Display
  static TextStyle get display => _style(
    fontSize: 28.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -2,
    fontWeight: FontWeight.w700,
  );

  // Title
  static TextStyle get title1 => _style(
    fontSize: 24.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get title2 => _style(
    fontSize: 22.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get title3 => _style(
    fontSize: 20.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get title4 => _style(
    fontSize: 18.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w700,
  );

  // Headline
  static TextStyle get headline1 => _style(
    fontSize: 16.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get headline2 => _style(
    fontSize: 15.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headline3 => _style(
    fontSize: 14.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w600,
  );

  // Body
  static TextStyle get body1 => _style(
    fontSize: 16.sp,
    lineHeight: 1.6,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get body2 => _style(
    fontSize: 15.sp,
    lineHeight: 1.6,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get body3 => _style(
    fontSize: 14.sp,
    lineHeight: 1.6,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w400,
  );

  // Caption
  static TextStyle get caption1 => _style(
    fontSize: 13.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get caption2 => _style(
    fontSize: 12.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get caption3 => _style(
    fontSize: 11.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w500,
  );

  // Button
  static TextStyle get button1 => _style(
    fontSize: 16.sp,
    lineHeight: 1.3,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get button2 => _style(
    fontSize: 15.sp,
    lineHeight: 1.3,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get button3 => _style(
    fontSize: 14.sp,
    lineHeight: 1.3,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get button4 => _style(
    fontSize: 13.sp,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get badge => _style(
    fontSize: 11.sp,
    lineHeight: 1.3,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w600,
  );
}
