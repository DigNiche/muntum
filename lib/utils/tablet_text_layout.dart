import 'dart:math' as math;
import 'package:flutter/material.dart';

class TabletTextLayout {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  static double lineHeight(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text.isEmpty ? '가' : text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  static double atLeast(BuildContext context, double original, double needed) =>
      isTablet(context)
      ? math.max(original, needed.ceilToDouble() + 1)
      : original;
}
