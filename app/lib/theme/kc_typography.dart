import 'package:flutter/material.dart';

abstract final class KcTypography {
  static const String fontFamily = 'PlusJakartaSans';

  static TextTheme apply(TextTheme base) {
    final textTheme = base.apply(fontFamily: fontFamily);

    TextStyle style(
      TextStyle? baseStyle, {
      required double fontSize,
      required double lineHeight,
      required FontWeight fontWeight,
    }) {
      return (baseStyle ?? const TextStyle(fontFamily: fontFamily)).copyWith(
        fontSize: fontSize,
        height: lineHeight / fontSize,
        fontWeight: fontWeight,
        letterSpacing: 0,
      );
    }

    return textTheme.copyWith(
      // Judul utama halaman.
      headlineLarge: style(
        textTheme.headlineLarge,
        fontSize: 24,
        lineHeight: 32,
        fontWeight: FontWeight.w600,
      ),

      // Alternatif judul halaman yang lebih ringkas.
      headlineMedium: style(
        textTheme.headlineMedium,
        fontSize: 22,
        lineHeight: 30,
        fontWeight: FontWeight.w600,
      ),

      // Judul dialog atau bagian konten yang menonjol.
      headlineSmall: style(
        textTheme.headlineSmall,
        fontSize: 20,
        lineHeight: 28,
        fontWeight: FontWeight.w600,
      ),

      // Judul app bar dan bagian konten.
      titleLarge: style(
        textTheme.titleLarge,
        fontSize: 18,
        lineHeight: 24,
        fontWeight: FontWeight.w600,
      ),

      // Nama menu atau judul item.
      titleMedium: style(
        textTheme.titleMedium,
        fontSize: 16,
        lineHeight: 24,
        fontWeight: FontWeight.w600,
      ),

      // Judul kecil pada konten yang padat.
      titleSmall: style(
        textTheme.titleSmall,
        fontSize: 14,
        lineHeight: 20,
        fontWeight: FontWeight.w600,
      ),

      // Isi teks besar dan dasar teks input.
      bodyLarge: style(
        textTheme.bodyLarge,
        fontSize: 16,
        lineHeight: 24,
        fontWeight: FontWeight.w400,
      ),

      // Deskripsi dan isi teks standar.
      bodyMedium: style(
        textTheme.bodyMedium,
        fontSize: 14,
        lineHeight: 20,
        fontWeight: FontWeight.w400,
      ),

      // Metadata dan keterangan singkat.
      bodySmall: style(
        textTheme.bodySmall,
        fontSize: 12,
        lineHeight: 16,
        fontWeight: FontWeight.w400,
      ),

      // Label tombol dan chip.
      labelLarge: style(
        textTheme.labelLarge,
        fontSize: 14,
        lineHeight: 20,
        fontWeight: FontWeight.w600,
      ),

      // Label navigasi dan kontrol ringkas.
      labelMedium: style(
        textTheme.labelMedium,
        fontSize: 12,
        lineHeight: 16,
        fontWeight: FontWeight.w500,
      ),

      // Label pendukung dengan ukuran minimum yang dipilih aplikasi.
      labelSmall: style(
        textTheme.labelSmall,
        fontSize: 12,
        lineHeight: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
