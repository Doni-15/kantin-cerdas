import 'dart:math';
import 'dart:typed_data';

import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';

/// Representasi gambar yang telah lolos pemeriksaan keamanan biner (Magic Bytes,
/// pemindaian anti-polyglot/script, batas ukuran) dan telah diberi nama file
/// kanonis acak yang aman.
final class ValidatedUploadImage {
  ValidatedUploadImage._({
    required Uint8List bytes,
    required this.safeFileName,
    required this.format,
    required this.category,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final Uint8List bytes;
  final String safeFileName;
  final DetectedImageFormat format;
  final MediaUploadCategory category;

  String get mimeType => format.mimeType;
  int get sizeBytes => bytes.length;
}

/// Validator keamanan Zero-Trust untuk input file gambar dan URL gambar.
abstract final class ImageSecurityValidator {
  static const int minImageBytes = 32;
  static const int maxImageBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxDimensionPx = 8192;
  static const int maxUrlLength = 512;

  static final RegExp _nonSafeActorChars = RegExp(r'[^a-z0-9_-]');
  static final RegExp _unsafeUrlChars = RegExp(r'[\x00-\x20\x7F<>"\x27\\`]');
  static final RegExp _safeGeneratedFileNamePattern = RegExp(
    r'^[a-z0-9_-]{1,32}_(profile_avatar|menu_photo|stall_photo)_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|png|webp)$',
  );

  static const List<String> _forbiddenScriptTokens = <String>[
    '<script',
    '</script',
    '<?php',
    '<?=',
    '<svg',
    '<!doctype',
    '<html',
    '<iframe',
    '<object',
    '<embed',
    'javascript:',
    'vbscript:',
    'data:text/html',
    'onerror=',
    'onload=',
  ];

  static ValidatedUploadImage validateAndPrepare({
    required Uint8List bytes,
    required String actorId,
    required MediaUploadCategory category,
  }) {
    if (bytes.isEmpty || bytes.length < minImageBytes) {
      throw const MediaInvalidImageFailure(MediaValidationReason.emptyFile);
    }
    if (bytes.length > maxImageBytes) {
      throw const MediaInvalidImageFailure(MediaValidationReason.fileTooLarge);
    }

    final sanitizedActor = sanitizeActorId(actorId);
    if (sanitizedActor == null) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.invalidActorId,
      );
    }

    final format = detectFormatFromMagicBytes(bytes);
    if (format == null) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.unsupportedFormat,
      );
    }

    if (!_verifyStructuralIntegrity(bytes, format)) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.corruptedHeader,
      );
    }

    if (containsSuspiciousScriptPayload(bytes)) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.suspiciousScriptPayload,
      );
    }

    final safeFileName = generateSafeFileName(
      actorId: sanitizedActor,
      category: category,
      format: format,
    );

    return ValidatedUploadImage._(
      bytes: bytes,
      safeFileName: safeFileName,
      format: format,
      category: category,
    );
  }

  static String? sanitizeActorId(String rawActorId) {
    final cleaned = rawActorId
        .trim()
        .toLowerCase()
        .replaceAll(_nonSafeActorChars, '')
        .replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
    if (cleaned.isEmpty) {
      return null;
    }
    final truncated = cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
    if (!RegExp(r'[a-z0-9]').hasMatch(truncated)) {
      return null;
    }
    return truncated;
  }

  static String generateSafeFileName({
    required String actorId,
    required MediaUploadCategory category,
    required DetectedImageFormat format,
  }) {
    final sanitizedActor = sanitizeActorId(actorId);
    if (sanitizedActor == null) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.invalidActorId,
      );
    }
    final uuid = _generateSecureUuidV4();
    final fileName =
        '${sanitizedActor}_${category.slug}_$uuid.${format.extension}';
    if (!_safeGeneratedFileNamePattern.hasMatch(fileName)) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.invalidActorId,
      );
    }
    return fileName;
  }

  static bool isSafeGeneratedFileName(String fileName) {
    return _safeGeneratedFileNamePattern.hasMatch(fileName);
  }

  static DetectedImageFormat? detectFormatFromMagicBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      return null;
    }

    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return DetectedImageFormat.jpeg;
    }

    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return DetectedImageFormat.png;
    }

    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return DetectedImageFormat.webp;
    }

    return null;
  }

  static bool _verifyStructuralIntegrity(
    Uint8List bytes,
    DetectedImageFormat format,
  ) {
    switch (format) {
      case DetectedImageFormat.jpeg:
        if (bytes.length < 20) {
          return false;
        }
        var end = bytes.length - 1;
        while (end > 4 && bytes[end] == 0x00) {
          end--;
        }
        if (bytes[end - 1] != 0xFF || bytes[end] != 0xD9) {
          return false;
        }
        final sofDims = _extractJpegDimensionsIfPresent(bytes);
        if (sofDims != null) {
          final (w, h) = sofDims;
          if (w < 1 || w > maxDimensionPx || h < 1 || h > maxDimensionPx) {
            return false;
          }
        }
        return true;

      case DetectedImageFormat.png:
        if (bytes.length < 33) {
          return false;
        }
        final hasIhdr =
            bytes[12] == 0x49 &&
            bytes[13] == 0x48 &&
            bytes[14] == 0x44 &&
            bytes[15] == 0x52;
        if (!hasIhdr) {
          return false;
        }
        final bd = ByteData.sublistView(bytes);
        final width = bd.getUint32(16, Endian.big);
        final height = bd.getUint32(20, Endian.big);
        if (width < 1 ||
            width > maxDimensionPx ||
            height < 1 ||
            height > maxDimensionPx) {
          return false;
        }
        final tailStart = bytes.length - 12;
        return bytes[tailStart + 4] == 0x49 &&
            bytes[tailStart + 5] == 0x45 &&
            bytes[tailStart + 6] == 0x4E &&
            bytes[tailStart + 7] == 0x44;

      case DetectedImageFormat.webp:
        if (bytes.length < 20) {
          return false;
        }
        final isVp8 =
            bytes[12] == 0x56 &&
            bytes[13] == 0x50 &&
            bytes[14] == 0x38 &&
            (bytes[15] == 0x20 || bytes[15] == 0x4C || bytes[15] == 0x58);
        if (!isVp8) {
          return false;
        }
        final webpDims = _extractWebpDimensionsIfPresent(bytes);
        if (webpDims != null) {
          final (w, h) = webpDims;
          if (w < 1 || w > maxDimensionPx || h < 1 || h > maxDimensionPx) {
            return false;
          }
        }
        return true;
    }
  }

  /// Mengekstrak dimensi (width, height) jika segmen SOF JPEG ditemukan.
  static (int, int)? _extractJpegDimensionsIfPresent(Uint8List bytes) {
    var i = 2;
    while (i + 8 < bytes.length) {
      if (bytes[i] != 0xFF) {
        i++;
        continue;
      }
      while (i < bytes.length && bytes[i] == 0xFF) {
        i++;
      }
      if (i >= bytes.length) break;
      final marker = bytes[i];
      i++;
      if (marker == 0xD8 ||
          marker == 0xD9 ||
          (marker >= 0xD0 && marker <= 0xD7) ||
          marker == 0x01) {
        continue;
      }
      if (i + 1 >= bytes.length) return null;
      final length = (bytes[i] << 8) | bytes[i + 1];
      if (length < 2 || i + length > bytes.length) return null;
      final isSof =
          (marker >= 0xC0 && marker <= 0xC3) ||
          (marker >= 0xC5 && marker <= 0xC7) ||
          (marker >= 0xC9 && marker <= 0xCB) ||
          (marker >= 0xCD && marker <= 0xCF);
      if (isSof && length >= 7 && i + 6 < bytes.length) {
        final height = (bytes[i + 3] << 8) | bytes[i + 4];
        final width = (bytes[i + 5] << 8) | bytes[i + 6];
        return (width, height);
      }
      i += length;
    }
    return null;
  }

  /// Mengekstrak dimensi (width, height) jika header frame VP8/VP8L/VP8X lengkap.
  static (int, int)? _extractWebpDimensionsIfPresent(Uint8List bytes) {
    final chunkType = bytes[15];
    if (chunkType == 0x20 &&
        bytes.length >= 30 &&
        bytes[23] == 0x9D &&
        bytes[24] == 0x01 &&
        bytes[25] == 0x2A) {
      final width = ((bytes[27] << 8) | bytes[26]) & 0x3FFF;
      final height = ((bytes[29] << 8) | bytes[28]) & 0x3FFF;
      return (width, height);
    } else if (chunkType == 0x4C && bytes.length >= 25 && bytes[20] == 0x2F) {
      final b0 = bytes[21];
      final b1 = bytes[22];
      final b2 = bytes[23];
      final b3 = bytes[24];
      final width = 1 + (b0 | ((b1 & 0x3F) << 8));
      final height = 1 + ((b1 >> 6) | (b2 << 2) | ((b3 & 0x0F) << 10));
      return (width, height);
    } else if (chunkType == 0x58 && bytes.length >= 30) {
      final width = 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
      final height = 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
      return (width, height);
    }
    return null;
  }

  static bool containsSuspiciousScriptPayload(Uint8List bytes) {
    final asciiLower = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      if (byte >= 0x41 && byte <= 0x5A) {
        asciiLower.writeCharCode(byte + 32);
      } else if (byte >= 0x20 && byte <= 0x7E) {
        asciiLower.writeCharCode(byte);
      } else if (byte == 0x09 || byte == 0x0A || byte == 0x0D) {
        asciiLower.writeCharCode(0x20);
      } else {
        asciiLower.writeCharCode(0x00);
      }
    }
    final content = asciiLower.toString();
    for (final token in _forbiddenScriptTokens) {
      if (content.contains(token)) {
        return true;
      }
    }
    return false;
  }

  static String? normalizeSafeImageUrl(
    String? rawUrl, {
    String fieldName = 'image_url',
  }) {
    if (rawUrl == null) {
      return null;
    }
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length > maxUrlLength || _unsafeUrlChars.hasMatch(trimmed)) {
      throw FormatException('URL gambar ($fieldName) tidak valid.');
    }
    if (trimmed.contains('..') ||
        trimmed.contains(r'\') ||
        trimmed.toLowerCase().contains('%2e%2e') ||
        trimmed.toLowerCase().contains('%5c')) {
      throw FormatException(
        'URL gambar ($fieldName) mengandung path tidak aman.',
      );
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        !uri.hasAuthority ||
        uri.host.trim().isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw FormatException('URL gambar ($fieldName) harus berupa HTTP/HTTPS.');
    }
    return uri.toString();
  }

  static bool isValidSafeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return false;
    }
    try {
      return normalizeSafeImageUrl(rawUrl) != null;
    } on FormatException {
      return false;
    }
  }

  static String _generateSecureUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
