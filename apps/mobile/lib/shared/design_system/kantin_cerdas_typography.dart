import 'package:flutter/material.dart';

abstract final class KantinCerdasTypography {
  static const fontFamily = 'PlusJakartaSans';

  static TextTheme applyTo(TextTheme base) {
    final textTheme = base.apply(fontFamily: fontFamily);

    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
      ),

      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
      ),

      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w700,
      ),

      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      ),

      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),

      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),

      bodySmall: textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
