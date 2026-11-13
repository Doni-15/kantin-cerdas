import 'dart:typed_data';
import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';

/// Hasil deteksi format gambar dari magic bytes.
typedef DetectedImageFormat = ({String mimeType, String extension});

abstract final class ImageInspector {
  static DetectedImageFormat? detectFormat(Uint8List bytes) {
    if (bytes.length < 12) return null;

    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return (mimeType: 'image/jpeg', extension: 'jpg');
    }

    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return (mimeType: 'image/png', extension: 'png');
    }

    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return (mimeType: 'image/webp', extension: 'webp');
    }

    return null;
  }

  /// Verifikasi keutuhan struktur biner (IHDR/IEND/EOI/VP8 & dimensi PNG).
  static bool verifyStructure(Uint8List bytes, String extension) {
    switch (extension) {
      case 'jpg':
        if (bytes.length < 20) return false;
        var end = bytes.length - 1;
        while (end > 4 && bytes[end] == 0x00) {
          end--;
        }
        return bytes[end - 1] == 0xFF && bytes[end] == 0xD9;

      case 'png':
        if (bytes.length < 33) return false;
        final hasIhdr =
            bytes[12] == 0x49 &&
            bytes[13] == 0x48 &&
            bytes[14] == 0x44 &&
            bytes[15] == 0x52;
        if (!hasIhdr) return false;

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
            width > SecurityConstants.maxDimensionPx ||
            height < 1 ||
            height > SecurityConstants.maxDimensionPx) {
          return false;
        }
        final tailStart = bytes.length - 12;
        return bytes[tailStart + 4] == 0x49 &&
            bytes[tailStart + 5] == 0x45 &&
            bytes[tailStart + 6] == 0x4E &&
            bytes[tailStart + 7] == 0x44;

      case 'webp':
        if (bytes.length < 20) return false;
        return bytes[12] == 0x56 &&
            bytes[13] == 0x50 &&
            bytes[14] == 0x38 &&
            (bytes[15] == 0x20 || bytes[15] == 0x4C || bytes[15] == 0x58);

      default:
        return false;
    }
  }

  /// Batas dimensi per sisi & total piksel untuk semua format
  /// (anti decompression bomb). Gagal parsing dianggap tidak valid.
  static bool isWithinPixelLimit(Uint8List bytes, String extension) {
    final dims = switch (extension) {
      'jpg' => _readJpegDimensions(bytes),
      'png' => _readPngDimensions(bytes),
      'webp' => _readWebpDimensions(bytes),
      _ => null,
    };
    if (dims == null) return false;
    if (dims.width < 1 || dims.height < 1) return false;
    if (dims.width > SecurityConstants.maxDimensionPx ||
        dims.height > SecurityConstants.maxDimensionPx) {
      return false;
    }
    return dims.width * dims.height <= SecurityConstants.maxTotalPixels;
  }

  /// Memindai seluruh byte terhadap sisipan skrip/markup (anti-polyglot).
  /// Lapis tambahan (defense-in-depth), bukan kontrol keamanan utama.
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
    for (final token in SecurityConstants.forbiddenScriptTokens) {
      if (content.contains(token)) return true;
    }
    return false;
  }

  static ({int width, int height})? _readPngDimensions(Uint8List b) {
    if (b.length < 24) return null;
    return (
      width: (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19],
      height: (b[20] << 24) | (b[21] << 16) | (b[22] << 8) | b[23],
    );
  }

  static ({int width, int height})? _readJpegDimensions(Uint8List b) {
    var i = 2; // lewati SOI (FF D8)
    while (i + 3 < b.length) {
      if (b[i] != 0xFF) {
        i++;
        continue;
      }
      final marker = b[i + 1];
      if (marker == 0xFF) {
        i++;
        continue;
      }
      if (marker == 0x00 ||
          marker == 0x01 ||
          (marker >= 0xD0 && marker <= 0xD8)) {
        i += 2;
        continue;
      }
      if (marker == 0xD9 || marker == 0xDA) return null; // EOI/SOS sebelum SOF
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2) return null;

      final isSof =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isSof) {
        if (i + 8 >= b.length) return null;
        return (
          width: (b[i + 7] << 8) | b[i + 8],
          height: (b[i + 5] << 8) | b[i + 6],
        );
      }
      i += 2 + len;
    }
    return null;
  }

  static ({int width, int height})? _readWebpDimensions(Uint8List b) {
    if (b.length < 30) return null;
    switch (String.fromCharCodes(b.sublist(12, 16))) {
      case 'VP8 ':
        if (b[23] != 0x9D || b[24] != 0x01 || b[25] != 0x2A) return null;
        return (
          width: (b[26] | (b[27] << 8)) & 0x3FFF,
          height: (b[28] | (b[29] << 8)) & 0x3FFF,
        );
      case 'VP8L':
        if (b[20] != 0x2F) return null;
        final bits = b[21] | (b[22] << 8) | (b[23] << 16) | (b[24] << 24);
        return (
          width: (bits & 0x3FFF) + 1,
          height: ((bits >> 14) & 0x3FFF) + 1,
        );
      case 'VP8X':
        return (
          width: (b[24] | (b[25] << 8) | (b[26] << 16)) + 1,
          height: (b[27] | (b[28] << 8) | (b[29] << 16)) + 1,
        );
      default:
        return null;
    }
  }
}
