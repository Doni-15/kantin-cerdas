import 'package:flutter/material.dart';

abstract final class KcColors {
  static final ColorScheme light = _create(Brightness.light);
  static final ColorScheme dark = _create(Brightness.dark);

  static ColorScheme _create(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    Color pick(int light, int dark) => Color(isDark ? dark : light);

    final primary = pick(0xFFB83D13, 0xFFFF9A62);
    final onPrimary = pick(0xFFFFFFFF, 0xFF321708);
    final primaryContainer = pick(0xFFFFF0E9, 0xFF43291D);
    final onPrimaryContainer = pick(0xFF6B2A12, 0xFFFFDCC8);

    return ColorScheme.fromSeed(
      seedColor: const Color(0xFFB83D13),
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      primaryFixed: const Color(0xFFFFDCC8),
      primaryFixedDim: const Color(0xFFFFB68A),
      onPrimaryFixed: const Color(0xFF321708),
      onPrimaryFixedVariant: const Color(0xFF6B2A12),

      // Aksen pendukung lebih tenang.
      // Pilihan aktif tetap memakai container bernuansa merek.
      secondary: pick(0xFF8A4A2F, 0xFFE5B39A),
      onSecondary: pick(0xFFFFFFFF, 0xFF352017),
      secondaryContainer: primaryContainer,
      onSecondaryContainer: onPrimaryContainer,
      secondaryFixed: const Color(0xFFFFE0D0),
      secondaryFixedDim: const Color(0xFFE5B39A),
      onSecondaryFixed: const Color(0xFF352017),
      onSecondaryFixedVariant: const Color(0xFF703C26),

      // Aksen netral pendukung.
      // Gunakan KcStatusColors.success untuk status positif.
      tertiary: pick(0xFF52525B, 0xFFD4D4DC),
      onTertiary: pick(0xFFFFFFFF, 0xFF282830),
      tertiaryContainer: pick(0xFFEFEFF2, 0xFF303038),
      onTertiaryContainer: pick(0xFF303038, 0xFFEFEFF2),
      tertiaryFixed: const Color(0xFFE4E4EC),
      tertiaryFixedDim: const Color(0xFFC8C8D2),
      onTertiaryFixed: const Color(0xFF282830),
      onTertiaryFixedVariant: const Color(0xFF494952),

      // Halaman terang sedikit abu-abu agar kartu putih terpisah.
      // Permukaan gelap menggunakan abu-abu netral.
      surface: pick(0xFFFAFAFA, 0xFF161618),
      surfaceDim: pick(0xFFE8E8EB, 0xFF161618),
      surfaceBright: pick(0xFFFFFFFF, 0xFF38383D),
      surfaceContainerLowest: pick(0xFFFFFFFF, 0xFF0F0F11),
      surfaceContainerLow: pick(0xFFFFFFFF, 0xFF1F1F22),
      surfaceContainer: pick(0xFFF4F4F5, 0xFF27272A),
      surfaceContainerHigh: pick(0xFFEEEEF0, 0xFF2F2F33),
      surfaceContainerHighest: pick(0xFFE8E8EB, 0xFF38383D),

      onSurface: pick(0xFF252528, 0xFFF5F5F6),
      onSurfaceVariant: pick(0xFF5F5F69, 0xFFC4C4CC),

      // Batas kontrol yang perlu terlihat jelas.
      outline: pick(0xFF7B7B85, 0xFF94949E),

      // Divider dan batas kartu yang lebih halus.
      outlineVariant: pick(0xFFE1E1E6, 0xFF414147),

      error: pick(0xFFB3261E, 0xFFFFB4AB),
      onError: pick(0xFFFFFFFF, 0xFF690005),
      errorContainer: pick(0xFFFFEDEA, 0xFF4A211E),
      onErrorContainer: pick(0xFF8C1D18, 0xFFFFDAD6),

      inverseSurface: pick(0xFF29292E, 0xFFF5F5F6),
      onInverseSurface: pick(0xFFF5F5F6, 0xFF252528),
      inversePrimary: pick(0xFFFF9A62, 0xFFB83D13),

      surfaceTint: primary,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }
}

/// Pasangan warna untuk teks/ikon status dan latarnya.
/// Gunakan success/warning/info sebagai foreground di atas container-nya.
@immutable
class KcStatusColors extends ThemeExtension<KcStatusColors> {
  const KcStatusColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  /// Menunggu / Menunggu konfirmasi.
  Color get waiting => warning;
  Color get waitingContainer => warningContainer;

  /// Diproses.
  Color get processing => info;
  Color get processingContainer => infoContainer;

  /// Siap diambil.
  Color get ready => success;
  Color get readyContainer => successContainer;

  /// Selesai.
  Color get completed => success;
  Color get completedContainer => successContainer;

  static const light = KcStatusColors(
    success: Color(0xFF247A45),
    successContainer: Color(0xFFE8F4EC),
    warning: Color(0xFF805500),
    warningContainer: Color(0xFFFFF1D6),
    info: Color(0xFF285F8F),
    infoContainer: Color(0xFFEAF2FA),
  );

  static const dark = KcStatusColors(
    success: Color(0xFF8FD5A6),
    successContainer: Color(0xFF183522),
    warning: Color(0xFFF2CD7B),
    warningContainer: Color(0xFF382B12),
    info: Color(0xFFA8CFFA),
    infoContainer: Color(0xFF182D42),
  );

  static KcStatusColors of(BuildContext context) {
    final colors = Theme.of(context).extension<KcStatusColors>();

    if (colors == null) {
      throw FlutterError(
        'KcStatusColors tidak ditemukan pada Theme aktif. '
        'Gunakan KcTheme.light dan KcTheme.dark pada MaterialApp.',
      );
    }

    return colors;
  }

  @override
  KcStatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return KcStatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  KcStatusColors lerp(covariant KcStatusColors? other, double t) {
    if (other == null) return this;

    return KcStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}
