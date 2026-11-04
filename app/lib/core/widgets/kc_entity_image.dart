import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';

/// Komponen perender gambar entitas (avatar profil, foto menu, foto stan)
/// yang memvalidasi keamanan URL terlebih dahulu dan menyediakan fallback
/// ikon secara otomatis bila gambar belum ada atau gagal dimuat.
class KcEntityImage extends StatelessWidget {
  const KcEntityImage.avatar({
    super.key,
    required this.imageUrl,
    this.previewBytes,
    this.radius = 32,
    this.fallbackIcon = Icons.person_outline,
    this.semanticLabel,
  }) : _isCircle = true,
       width = radius * 2,
       height = radius * 2,
       borderRadius = 0;

  const KcEntityImage.thumbnail({
    super.key,
    required this.imageUrl,
    this.previewBytes,
    this.width = 56,
    this.height = 56,
    this.borderRadius = KcRadius.card,
    this.fallbackIcon = Icons.restaurant_outlined,
    this.semanticLabel,
  }) : _isCircle = false,
       radius = 0;

  final String? imageUrl;
  final Uint8List? previewBytes;
  final double radius;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;
  final String? semanticLabel;
  final bool _isCircle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetCacheWidth = (width * dpr).round().clamp(32, 2048);
    final targetCacheHeight = (height * dpr).round().clamp(32, 2048);
    final safeUrl = _resolveSafeUrl(imageUrl);
    final bytes = previewBytes;
    final iconSize =
        (_isCircle ? radius : (width < height ? width : height)) * 0.52;

    Widget fallback() {
      return Container(
        width: width,
        height: height,
        color: colors.primaryContainer,
        alignment: Alignment.center,
        child: Icon(
          fallbackIcon,
          size: iconSize.clamp(18.0, 40.0),
          color: colors.onPrimaryContainer,
        ),
      );
    }

    Widget content;
    if (bytes != null && bytes.isNotEmpty) {
      content = Image.memory(
        bytes,
        key: ValueKey<int>(_memoryKey(bytes)),
        width: width,
        height: height,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (safeUrl != null) {
      content = Image.network(
        safeUrl,
        key: ValueKey<String>(safeUrl),
        width: width,
        height: height,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: width,
            height: height,
            color: colors.surfaceContainerHighest,
            alignment: Alignment.center,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          );
        },
      );
    } else {
      content = fallback();
    }

    final clipped = _isCircle
        ? ClipOval(
            child: SizedBox(width: width, height: height, child: content),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(width: width, height: height, child: content),
          );

    if (semanticLabel == null || semanticLabel!.trim().isEmpty) {
      return ExcludeSemantics(child: clipped);
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: clipped),
    );
  }

  static String? _resolveSafeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }
    try {
      return ImageSecurityValidator.normalizeSafeImageUrl(rawUrl);
    } on FormatException {
      return null;
    }
  }

  static int _memoryKey(Uint8List bytes) {
    final len = bytes.length;
    return Object.hash(
      len,
      bytes.first,
      bytes.last,
      bytes[len ~/ 2],
      bytes[len ~/ 4],
    );
  }
}
