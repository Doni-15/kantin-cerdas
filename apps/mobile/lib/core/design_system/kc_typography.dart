import 'package:flutter/material.dart';

abstract final class KcTypography {
  static const String fontFamily = 'PlusJakartaSans';

  static TextTheme apply(TextTheme base) {
    final textTheme = base.apply(fontFamily: fontFamily);

    return textTheme.copyWith(
      /// Judul layar utama.
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      ),

      /// Alternatif judul layar yang sedikit lebih kecil.
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w600,
      ),

      /// Judul bagian.
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w600,
      ),

      /// Judul item / emphasis sedang.
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w500,
      ),

      /// Teks utama besar.
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      ),

      /// Teks utama normal.
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),

      /// Informasi pendukung.
      bodySmall: textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
      ),

      /// Label aksi utama.
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),

      /// Label kecil.
      labelMedium: textTheme.labelMedium?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),

      // Judul layar ringkas atau judul dialog.
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
      ),

      // Judul kecil, misalnya judul kartu yang padat.
      titleSmall: textTheme.titleSmall?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),

      // Label pendukung; tetap terbaca.
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
