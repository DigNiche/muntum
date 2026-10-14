import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_model.dart';

/// Preserve the phone layout exactly; on tablets, .sp can grow faster than .h.
/// Measure the same text widths/styles rather than shrinking typography.
class ProgramCardLayout {
  static bool _isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  static double _textHeight(
    BuildContext context,
    String text,
    TextStyle style,
    double width, {
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(maxWidth: math.max(1, width));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  static double collectionHeight(
    BuildContext context,
    List<ProgramModel> programs,
  ) {
    final original = 370.h;
    if (!_isTablet(context)) return original;
    var height = original;
    for (final program in programs) {
      final textWidth = 160.w - 8.w;
      final content =
          213.h +
          12.h +
          _textHeight(
            context,
            program.title,
            AppTypography.headline1,
            textWidth,
            maxLines: 2,
          ) +
          4.h +
          _textHeight(
            context,
            program.locationName,
            AppTypography.caption1,
            textWidth,
            maxLines: 1,
          ) +
          2.h +
          _textHeight(
            context,
            program.cardDateText,
            AppTypography.caption1,
            textWidth,
            maxLines: 1,
          );
      // The vertical carousel includes 48.h bottom spacing.
      height = math.max(height, (content + 48.h).ceilToDouble() + 1);
    }
    return height;
  }

  static double twoRowHeight(
    BuildContext context,
    List<ProgramModel> programs,
  ) {
    final original = 230.h;
    if (!_isTablet(context)) return original;
    var rowHeight = 107.h;
    // MapHorizontalCard: image + outer gap + bookmark gap + bookmark width.
    final textWidth = 310.w - 80.w - 16.w - 16.w - 24.r;
    for (final program in programs) {
      final content =
          16.h +
          _textHeight(
            context,
            program.title,
            AppTypography.headline1,
            textWidth,
            maxLines: 2,
          ) +
          4.h +
          _textHeight(
            context,
            program.locationName,
            AppTypography.caption1,
            textWidth,
          ) +
          2.h +
          _textHeight(
            context,
            program.cardDateText,
            AppTypography.caption1,
            textWidth,
          );
      rowHeight = math.max(rowHeight, content.ceilToDouble() + 1);
    }
    return math.max(original, rowHeight * 2 + 16.h);
  }
}
