/// THE ONE FILE TO EDIT TO RESTYLE THE APP.
/// Screens and shared widgets read only from [AppTokens] and the [ThemeData]
/// built here. Placeholder values below; replace with Allen's Canva design.
library;

import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  // Colors (hex from the design)
  static const background = Color(0xFF0A0A0C);
  static const surface = Color(0xFF16161B);
  static const surfaceAlt = Color(0xFF1F1F26);
  static const border = Color(0xFF2A2A33);
  static const primary = Color(0xFFE50914);
  static const onPrimary = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A94B8);
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF3DDC84);

  // Typography
  static const String? fontFamily = null; // e.g. 'Poppins' once added to pubspec
  static const fontTitle = 28.0;
  static const fontHeading = 20.0;
  static const fontBody = 16.0;
  static const fontSmall = 13.0;

  // Shape and spacing
  static const radius = 12.0;
  static const radiusSmall = 8.0;
  static const radiusPill = 999.0;
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 24.0;
  static const space6 = 32.0;

  /// Minimum tap target (accessibility).
  static const minTap = 48.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const t = AppTokens.textPrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppTokens.primary,
      onPrimary: AppTokens.onPrimary,
      surface: AppTokens.surface,
      onSurface: t,
      error: AppTokens.error,
    );

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          borderSide: BorderSide(color: c),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: AppTokens.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        foregroundColor: t,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            fontSize: AppTokens.fontTitle,
            fontWeight: FontWeight.w700,
            color: t),
        titleLarge: TextStyle(
            fontSize: AppTokens.fontHeading,
            fontWeight: FontWeight.w600,
            color: t),
        bodyLarge: TextStyle(fontSize: AppTokens.fontBody, color: t),
        bodyMedium:
            TextStyle(fontSize: AppTokens.fontBody, color: AppTokens.textSecondary),
        bodySmall:
            TextStyle(fontSize: AppTokens.fontSmall, color: AppTokens.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceAlt,
        hintStyle: const TextStyle(color: AppTokens.textSecondary),
        labelStyle: const TextStyle(color: AppTokens.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4, vertical: AppTokens.space3),
        border: border(AppTokens.border),
        enabledBorder: border(AppTokens.border),
        focusedBorder: border(AppTokens.primary),
        errorBorder: border(AppTokens.error),
        focusedErrorBorder: border(AppTokens.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: AppTokens.onPrimary,
          minimumSize: const Size.fromHeight(AppTokens.minTap),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall)),
          textStyle: const TextStyle(
              fontSize: AppTokens.fontBody, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppTokens.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppTokens.primary
                : AppTokens.textSecondary)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            color: s.contains(WidgetState.selected)
                ? AppTokens.primary
                : AppTokens.textSecondary)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.surfaceAlt,
        contentTextStyle: const TextStyle(color: t),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: AppTokens.border,
    );
  }
}
