import 'package:flutter/material.dart';

/// 亮色主题色
class AppLightColors {
  static const Color primary = Color(0xFFC3473A); // 网易云红
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color divider = Color(0xFFE0E0E0);
}

/// 暗色主题色
class AppColors {
  static const Color primary = Color(0xFFC3473A); // 网易云红
  static const Color background = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF9A9A9A);
  static const Color divider = Color(0xFF333333);
}

ThemeData buildLightTheme() {
  const base = ColorScheme.light(
    primary: AppLightColors.primary,
    secondary: AppLightColors.primary,
    surface: AppLightColors.card,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppLightColors.background,
    colorScheme: base.copyWith(
      surface: AppLightColors.background,
      onSurface: AppLightColors.textPrimary,
    ),
    cardColor: AppLightColors.card,
    dividerColor: AppLightColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppLightColors.background,
      elevation: 0,
      foregroundColor: AppLightColors.textPrimary,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: AppLightColors.textPrimary),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppLightColors.textPrimary),
      bodyMedium: TextStyle(color: AppLightColors.textPrimary),
      bodySmall: TextStyle(color: AppLightColors.textSecondary),
      titleMedium: TextStyle(
        color: AppLightColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppLightColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppLightColors.primary,
      inactiveTrackColor: AppLightColors.divider,
      thumbColor: AppLightColors.primary,
      trackHeight: 2.5,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppLightColors.primary,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppLightColors.card,
      contentTextStyle: TextStyle(color: AppLightColors.textPrimary),
    ),
  );
}

ThemeData buildDarkTheme() {
  const base = ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.primary,
    surface: AppColors.card,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.copyWith(
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
    ),
    cardColor: AppColors.card,
    dividerColor: AppColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.divider,
      thumbColor: AppColors.primary,
      trackHeight: 2.5,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
