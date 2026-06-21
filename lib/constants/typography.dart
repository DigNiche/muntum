import 'package:flutter/material.dart';

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
  static final display = _style(
    fontSize: 28,
    lineHeight: 1.4,
    letterSpacingPercent: -2,
    fontWeight: FontWeight.w700,
  );

  // Title
  static final title1 = _style(
    fontSize: 24,
    lineHeight: 1.4,
    letterSpacingPercent: -1,
    fontWeight: FontWeight.w700,
  );

  static final title2 = _style(
    fontSize: 22,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w700,
  );

  static final title3 = _style(
    fontSize: 20,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w700,
  );

  static final title4 = _style(
    fontSize: 18,
    lineHeight: 1.4,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w700,
  );

  // Body
  static final body1 = _style(
    fontSize: 16,
    lineHeight: 1.6,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w400,
  );

  static final body2 = _style(
    fontSize: 15,
    lineHeight: 1.6,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w400,
  );

  static final body3 = _style(
    fontSize: 14,
    lineHeight: 1.6,
    letterSpacingPercent: -1.5,
    fontWeight: FontWeight.w400,
  );

  // Caption
  static final caption1 = _style(
    fontSize: 13,
    lineHeight: 1.4,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w400,
  );

  static final caption2 = _style(
    fontSize: 12,
    lineHeight: 1.4,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w400,
  );

  static final caption3 = _style(
    fontSize: 11,
    lineHeight: 1.4,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w400,
  );

  // Button
  static final button = _style(
    fontSize: 14,
    lineHeight: 1.4,
    letterSpacingPercent: -2.5,
    fontWeight: FontWeight.w600,
  );
}
