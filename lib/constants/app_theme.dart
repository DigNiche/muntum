import 'package:flutter/material.dart';
import 'package:muntum/constants/colors.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary500).copyWith(
      primary: AppColors.primary500,
      onPrimary: AppColors.gray900,
      secondary: AppColors.gray900,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.gray900,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.white,
    canvasColor: AppColors.white,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.gray900,
      linearTrackColor: AppColors.gray200,
      circularTrackColor: AppColors.gray200,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.gray900,
      selectionColor: AppColors.primary500.withValues(alpha: 0.35),
      selectionHandleColor: AppColors.primary500,
    ),
  );
}
