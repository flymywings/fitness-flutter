/// THE ONE FILE TO EDIT TO RESTYLE THE APP.
/// Screens and shared widgets read only from [AppTokens] and the [ThemeData]
/// built here, following the PACE foundations and mobile screens.
library;

import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  // Colors (hex from the design)
  static const background = Colors.black;
  static const chrome = Color(0xFF0B0B0D);
  static const surface = Color(0xFF18181B);
  static const surfaceAlt = Color(0xFF1B1B1E);
  static const border = Color(0xFF303036);
  static const controlBorder = Color(0xFF55555C);
  static const primary = Color(0xFFE32636);
  static const primaryPressed = Color(0xFFB91C2C);
  static const onPrimary = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const error = Color(0xFFFF8A8A);
  static const success = Color(0xFF22C55E);

  // Typography
  static const fontFamily = 'Inter';
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
  static const minTap = 44.0;
  static const actionHeight = 56.0;
  static const desktopBreakpoint = 1024.0;

  static bool desktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const t = AppTokens.textPrimary;
    final scheme =
        ColorScheme.fromSeed(
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
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: BorderSide(color: c),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTokens.fontFamily,
      applyElevationOverlayColor: false,
      scaffoldBackgroundColor: AppTokens.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        foregroundColor: t,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: AppTokens.fontTitle,
          height: 32 / 28,
          fontWeight: FontWeight.w700,
          color: t,
        ),
        titleLarge: TextStyle(
          fontSize: AppTokens.fontHeading,
          height: 24 / 20,
          fontWeight: FontWeight.w600,
          color: t,
        ),
        bodyLarge: TextStyle(
          fontSize: AppTokens.fontBody,
          height: 1.5,
          color: t,
        ),
        bodyMedium: TextStyle(
          fontSize: AppTokens.fontBody,
          height: 1.5,
          color: AppTokens.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: AppTokens.fontSmall,
          height: 16 / 13,
          color: AppTokens.textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceAlt,
        hintStyle: const TextStyle(color: AppTokens.textSecondary),
        labelStyle: const TextStyle(color: AppTokens.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space4,
        ),
        border: border(AppTokens.controlBorder),
        enabledBorder: border(AppTokens.controlBorder),
        focusedBorder: border(t),
        errorBorder: border(AppTokens.error),
        focusedErrorBorder: border(AppTokens.error),
        errorStyle: const TextStyle(color: AppTokens.error),
        helperStyle: const TextStyle(color: AppTokens.textSecondary),
        helperMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: AppTokens.primary,
              foregroundColor: AppTokens.onPrimary,
              minimumSize: const Size(0, AppTokens.actionHeight),
              disabledBackgroundColor: AppTokens.surface,
              disabledForegroundColor: AppTokens.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
              textStyle: const TextStyle(
                fontFamily: AppTokens.fontFamily,
                fontSize: AppTokens.fontBody,
                fontWeight: FontWeight.w600,
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppTokens.surface;
                }
                if (states.contains(WidgetState.pressed)) {
                  return AppTokens.primaryPressed;
                }
                return AppTokens.primary;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t,
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, AppTokens.minTap),
          side: const BorderSide(color: AppTokens.controlBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, AppTokens.minTap)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppTokens.controlBorder),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? t : AppTokens.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppTokens.background : t,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t,
          minimumSize: const Size(0, AppTokens.minTap),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.chrome,
        height: 72,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? AppTokens.controlBorder
              : Colors.transparent,
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppTokens.error
                : AppTokens.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            color: s.contains(WidgetState.selected)
                ? t
                : AppTokens.textSecondary,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
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
