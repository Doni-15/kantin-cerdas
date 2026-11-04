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
///
/// Prinsip keamanan:
/// 1. Nama file asli dari perangkat pengguna SELALU diabaikan dan diganti
///    dengan `{sanitizedUserId}_{category}_{uuidV4}.{ext}`.
/// 2. Format gambar ditentukan murni dari Magic Bytes header biner, bukan dari
///    ekstensi nama file atau klaim MIME OS.
/// 3. Seluruh byte dipindai terhadap payload skrip/polyglot berbahaya
///    (`<script`, `<?php`, `<svg`, `<html`, `javascript:`, dll.).
/// 4. URL gambar hanya mengizinkan skema `https` atau `http` yang bersih tanpa
///    karakter kontrol, kredensial `userInfo`, maupun path traversal (`..`).
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

  /// Daftar tanda tangan ASCII berbahaya (huruf kecil) yang sering disisipkan
  /// pada file gambar polyglot (mis. di dalam metadata EXIF/komentar).
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

  /// Memvalidasi byte gambar secara menyeluruh dan menghasilkan
  /// [ValidatedUploadImage] dengan nama file acak yang aman.
  ///
  /// Melempar [MediaInvalidImageFailure] jika gagal validasi.
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

  /// Membersihkan `actorId` agar hanya berisi `[a-z0-9_-]` maksimal 32 karakter.
  /// Mengembalikan `null` jika tidak ada karakter alfanumerik yang valid.
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

  /// Menghasilkan nama file kanonis yang aman:
  /// `{sanitizedActorId}_{categorySlug}_{uuidV4}.{ext}`.
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

  /// Memeriksa apakah nama file sesuai pola kanonis aman hasil generator.
  static bool isSafeGeneratedFileName(String fileName) {
    return _safeGeneratedFileNamePattern.hasMatch(fileName);
  }

  /// Mendeteksi format gambar murni dari Magic Bytes (header biner).
  static DetectedImageFormat? detectFormatFromMagicBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      return null;
    }

    // 1. JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return DetectedImageFormat.jpeg;
    }

    // 2. PNG: 89 50 4E 47 0D 0A 1A 0A
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

    // 3. WEBP: "RIFF" (52 49 46 46) pada 0..3 dan "WEBP" (57 45 42 50) pada 8..11
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

  /// Memastikan struktur dasar header/trailer gambar valid dan tidak rusak.
  static bool _verifyStructuralIntegrity(
    Uint8List bytes,
    DetectedImageFormat format,
  ) {
    switch (format) {
      case DetectedImageFormat.jpeg:
        // JPEG harus memiliki penanda EOI (FF D9) di akhir file (mengizinkan
        // maksimal beberapa byte padding nol di ujung jika ada) dan ukuran minimal.
        if (bytes.length < 20) {
          return false;
        }
        var end = bytes.length - 1;
        while (end > 4 && bytes[end] == 0x00) {
          end--;
        }
        return bytes[end - 1] == 0xFF && bytes[end] == 0xD9;

      case DetectedImageFormat.png:
        // PNG wajib memiliki chunk IHDR pada byte 12..15 dengan lebar & tinggi
        // 32-bit big-endian pada byte 16..23, serta penanda IEND di akhir.
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
        final width =
            (bytes[16] << 24) |
            (bytes[17] << 16) |
            (bytes[18] << 8) |
            bytes[19];
        final height =
            (bytes[20] << 24) |
            (bytes[21] << 16) |
            (bytes[22] << 8) |
            bytes[23];
        if (width < 1 ||
            width > maxDimensionPx ||
            height < 1 ||
            height > maxDimensionPx) {
          return false;
        }
        // Periksa keberadaan chunk IEND (49 45 4E 44 AE 42 60 82) di 12 byte terakhir
        final tailStart = bytes.length - 12;
        return bytes[tailStart + 4] == 0x49 &&
            bytes[tailStart + 5] == 0x45 &&
            bytes[tailStart + 6] == 0x4E &&
            bytes[tailStart + 7] == 0x44;

      case DetectedImageFormat.webp:
        // WEBP minimal memiliki header RIFF + WEBP + chunk VP8 ('VP8 ', 'VP8L', atau 'VP8X')
        if (bytes.length < 20) {
          return false;
        }
        return bytes[12] == 0x56 &&
            bytes[13] == 0x50 &&
            bytes[14] == 0x38 &&
            (bytes[15] == 0x20 || bytes[15] == 0x4C || bytes[15] == 0x58);
    }
  }

  /// Memindai seluruh byte terhadap pola skrip ASCII berbahaya untuk mencegah
  /// serangan polyglot (file gambar valid yang diselipi kode PHP/JS/HTML/SVG).
  static bool containsSuspiciousScriptPayload(Uint8List bytes) {
    final asciiLower = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      if (byte >= 0x41 && byte <= 0x5A) {
        // Huruf besar A-Z -> ubah ke a-z
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

  /// Menormalisasi dan memvalidasi URL gambar (`imageUrl` / `avatarUrl`).
  ///
  /// - Mengembalikan `null` jika [rawUrl] bernilai `null` atau string kosong.
  /// - Melempar [FormatException] jika URL tidak aman (mis. `javascript:`,
  ///   `data:`, `file:`, karakter kontrol/HTML, `userInfo`, atau `..`).
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

  /// Mengembalikan `true` jika [rawUrl] adalah URL gambar HTTP/HTTPS yang aman.
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
    // RFC 4122 version 4 & variant 10xx
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
