import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/constants/typography.dart';

void main() {
  test(
    'typography follows the current screen size instead of the first one',
    () {
      ScreenUtilPlus.configure(
        data: const MediaQueryData(size: Size(800, 600)),
        designSize: const Size(390, 844),
      );
      final wideScreenFontSize = AppTypography.caption1.fontSize!;

      ScreenUtilPlus.configure(
        data: const MediaQueryData(size: Size(390, 844)),
        designSize: const Size(390, 844),
      );
      expect(AppTypography.caption1.fontSize, 13);
      expect(wideScreenFontSize, greaterThan(13));
    },
  );
}
