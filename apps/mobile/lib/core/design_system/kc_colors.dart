import 'package:flutter/material.dart';

abstract final class KcColors {
  static final ColorScheme light = _create(Brightness.light);
  static final ColorScheme dark = _create(Brightness.dark);

  static ColorScheme _create(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    Color pick(int light, int dark) => Color(isDark ? dark : light);

    final primary            = pick(0xFFC74418, 0xFFFFB596);
    final onPrimary          = pick(0xFFFFFFFF, 0xFF3B1608);
    final primaryContainer   = pick(0xFFFFEDE5, 0xFF49291C);
    final onPrimaryContainer = pick(0xFF743015, 0xFFFFDBCA);

    return ColorScheme.fromSeed(
      seedColor   : const Color(0xFFC74418),
      brightness  : brightness,
    ).copyWith(
      primary             : primary,
      onPrimary           : onPrimary,
      primaryContainer    : primaryContainer,
      onPrimaryContainer  : onPrimaryContainer,

      // Aksen yang konsisten untuk chip dan navigasi terpilih.
      secondary             : primary,
      onSecondary           : onPrimary,
      secondaryContainer    : primaryContainer,
      onSecondaryContainer  : onPrimaryContainer,

      tertiary                : pick(0xFF247A45, 0xFF8FD5A6),
      onTertiary              : pick(0xFFFFFFFF, 0xFF10381F),
      tertiaryContainer       : pick(0xFFE8F4EC, 0xFF183522),
      onTertiaryContainer     : pick(0xFF18552F, 0xFFB8EFC9),

      surface                 : pick(0xFFFFFFFF, 0xFF171513),
      surfaceDim              : pick(0xFFE8E4DF, 0xFF171513),
      surfaceBright           : pick(0xFFFFFFFF, 0xFF3A332D),
      surfaceContainerLowest  : pick(0xFFFFFFFF, 0xFF12100F),
      surfaceContainerLow     : pick(0xFFFFFFFF, 0xFF211E1B),
      surfaceContainer        : pick(0xFFF6F5F2, 0xFF2A2521),
      surfaceContainerHigh    : pick(0xFFF0EDE8, 0xFF322C27),
      surfaceContainerHighest : pick(0xFFE8E4DF, 0xFF3A332D),

      onSurface         : pick(0xFF252525, 0xFFF5F2EF),
      onSurfaceVariant  : pick(0xFF616161, 0xFFC6BEB8),

      // Untuk batas kontrol yang perlu mudah terlihat.
      outline           : pick(0xFF857A72, 0xFF95877D),

      // Untuk divider dan batas kartu yang lebih halus.
      outlineVariant    : pick(0xFFE6E3DF, 0xFF433B34),

      error             : pick(0xFFB3261E, 0xFFFFB4AB),
      onError           : pick(0xFFFFFFFF, 0xFF690005),
      errorContainer    : pick(0xFFFFEDEA, 0xFF4A211E),
      onErrorContainer  : pick(0xFF8C1D18, 0xFFFFDAD6),

      inverseSurface    : pick(0xFF302B27, 0xFFF5F2EF),
      onInverseSurface  : pick(0xFFF5F2EF, 0xFF252525),
      inversePrimary    : pick(0xFFFFB596, 0xFFC74418),

      surfaceTint : primary,
      shadow      : Colors.black,
      scrim       : Colors.black,
    );
  }
}

/// Pasangan warna untuk teks/ikon status dan latarnya.
/// Warna foreground dipakai di atas container yang bersesuaian.
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
    success           : Color(0xFF247A45),
    successContainer  : Color(0xFFE8F4EC),
    warning           : Color(0xFF805500),
    warningContainer  : Color(0xFFFFF1D6),
    info              : Color(0xFF285F8F),
    infoContainer     : Color(0xFFEAF2FA),
  );

  static const dark = KcStatusColors(
    success           : Color(0xFF8FD5A6),
    successContainer  : Color(0xFF183522),
    warning           : Color(0xFFF2CD7B),
    warningContainer  : Color(0xFF382B12),
    info              : Color(0xFFA8CFFA),
    infoContainer     : Color(0xFF182D42),
  );

  static KcStatusColors of(BuildContext context) {
    final colors = Theme.of(context).extension<KcStatusColors>();
    assert(colors != null, 'Gunakan KcTheme pada MaterialApp.');
    return colors!;
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
      success           : success ?? this.success,
      successContainer  : successContainer ?? this.successContainer,
      warning           : warning ?? this.warning,
      warningContainer  : warningContainer ?? this.warningContainer,
      info              : info ?? this.info,
      infoContainer     : infoContainer ?? this.infoContainer,
    );
  }

  @override
  KcStatusColors lerp(covariant KcStatusColors? other, double t) {
    if (other == null) return this;

    return KcStatusColors(
      success           : Color.lerp(success, other.success, t)!,
      successContainer  : Color.lerp(successContainer, other.successContainer, t)!,
      warning           : Color.lerp(warning, other.warning, t)!,
      warningContainer  : Color.lerp(warningContainer, other.warningContainer, t)!,
      info              : Color.lerp(info, other.info, t)!,
      infoContainer     : Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}