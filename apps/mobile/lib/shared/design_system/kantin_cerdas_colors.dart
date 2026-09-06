import 'package:flutter/material.dart';

abstract final class KantinCerdasColors {
  // Brand
  static const brandOrange = Color(0xFFE85D2A);
  static const actionOrange = Color(0xFFC74418);
  static const darkTerracotta = Color(0xFF9B341B);
  static const goldAccent = Color(0xFFF4B740);

  // Light
  static const lightBackground = Color(0xFFFAFAF8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceWarm = Color(0xFFF7F3F0);
  static const lightOutline = Color(0xFFDDD6D1);
  static const lightTextPrimary = Color(0xFF251B17);
  static const lightTextSecondary = Color(0xFF6D5A50);
  static const lightDisabled = Color(0xFFA99A92);

  // Dark
  static const darkBackground = Color(0xFF15110F);
  static const darkSurface = Color(0xFF211B18);
  static const darkSurfaceWarm = Color(0xFF2B2420);
  static const darkOutline = Color(0xFF756860);
  static const darkTextPrimary = Color(0xFFF8F1ED);
  static const darkTextSecondary = Color(0xFFD4C4BC);
  static const darkDisabled = Color(0xFF8E817A);

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: actionOrange,
    onPrimary: lightSurface,
    primaryContainer: Color(0xFFFBE9E2),
    onPrimaryContainer: Color(0xFF3B1205),
    secondary: goldAccent,
    onSecondary: lightTextPrimary,
    secondaryContainer: Color(0xFFFBE9E2),
    onSecondaryContainer: darkTerracotta,
    tertiary: darkTerracotta,
    onTertiary: lightSurface,
    tertiaryContainer: lightSurfaceWarm,
    onTertiaryContainer: darkTerracotta,
    surface: lightSurface,
    onSurface: lightTextPrimary,
    onSurfaceVariant: lightTextSecondary,
    surfaceDim: lightSurfaceWarm,
    surfaceBright: lightSurface,
    surfaceContainerLowest: lightSurface,
    surfaceContainerLow: lightBackground,
    surfaceContainer: lightSurfaceWarm,
    surfaceContainerHigh: lightSurfaceWarm,
    surfaceContainerHighest: lightSurfaceWarm,
    error: Color(0xFFB3261E),
    onError: lightSurface,
    errorContainer: Color(0xFFFCE8E6),
    onErrorContainer: Color(0xFFB3261E),
    outline: lightOutline,
    outlineVariant: lightOutline,
    inverseSurface: darkSurface,
    onInverseSurface: darkTextPrimary,
    inversePrimary: Color(0xFFFF9A73),
    surfaceTint: Colors.transparent,
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF9A73),
    onPrimary: Color(0xFF541D0B),
    primaryContainer: Color(0xFF71301A),
    onPrimaryContainer: Color(0xFFFFEDE5),
    secondary: Color(0xFFF4C867),
    onSecondary: Color(0xFF3A2A00),
    secondaryContainer: Color(0xFF71301A),
    onSecondaryContainer: Color(0xFFFFEDE5),
    tertiary: Color(0xFFFF9A73),
    onTertiary: Color(0xFF541D0B),
    tertiaryContainer: darkSurfaceWarm,
    onTertiaryContainer: darkTextPrimary,
    surface: darkSurface,
    onSurface: darkTextPrimary,
    onSurfaceVariant: darkTextSecondary,
    surfaceDim: darkBackground,
    surfaceBright: darkSurfaceWarm,
    surfaceContainerLowest: darkBackground,
    surfaceContainerLow: darkSurface,
    surfaceContainer: darkSurface,
    surfaceContainerHigh: darkSurfaceWarm,
    surfaceContainerHighest: darkSurfaceWarm,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF690005),
    onErrorContainer: Color(0xFFFFB4AB),
    outline: darkOutline,
    outlineVariant: darkOutline,
    inverseSurface: lightSurface,
    onInverseSurface: lightTextPrimary,
    inversePrimary: actionOrange,
    surfaceTint: Colors.transparent,
  );
}
