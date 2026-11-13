import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/security/image_inspector.dart';
import 'package:kantin_cerdas_backend/src/core/security/image_sanitizer.dart';

/// Hasil validasi: [bytes] sudah dibersihkan (tanpa EXIF/GPS/trailer) dan
/// itulah yang HARUS diunggah/di-hash, bukan byte asli dari client.
typedef ValidatedImage = ({Uint8List bytes, String mimeType, String extension});

/// Pipeline validasi gambar tunggal, dipakai register (avatar Base64) dan
/// `POST /media/images`.
abstract final class ImageGuard {
  static ValidatedImage validate(Uint8List raw, StorageConfig storage) {
    if (raw.length < SecurityConstants.minImageBytes) {
      throw ApiException.unprocessable(
        'File gambar kosong atau tidak ditemukan.',
        code: 'INVALID_IMAGE',
      );
    }

    final maxBytes = storage.maxUploadBytes < SecurityConstants.maxImageBytes
        ? storage.maxUploadBytes
        : SecurityConstants.maxImageBytes;
    if (raw.length > maxBytes) {
      throw ApiException(
        statusCode: 413,
        code: 'FILE_TOO_LARGE',
        message: 'Ukuran file gambar melebihi batas maksimal ${_mb(maxBytes)}.',
      );
    }

    final detected = ImageInspector.detectFormat(raw);
    if (detected == null ||
        !storage.allowedImageTypes.contains(detected.mimeType)) {
      throw const ApiException(
        statusCode: 415,
        code: 'UNSUPPORTED_MEDIA_TYPE',
        message: 'Format gambar tidak didukung. Gunakan JPEG, PNG, atau WebP.',
      );
    }

    // Buang metadata/trailer dulu; semua pemeriksaan berikutnya dan
    // penyimpanan memakai byte yang sudah bersih.
    final clean = ImageSanitizer.sanitize(raw, detected.extension);
    if (clean == null) {
      throw ApiException.unprocessable(
        'Header atau struktur file gambar rusak.',
        code: 'INVALID_IMAGE',
      );
    }

    if (!ImageInspector.verifyStructure(clean, detected.extension)) {
      throw ApiException.unprocessable(
        'Header atau struktur file gambar rusak.',
        code: 'INVALID_IMAGE',
      );
    }

    if (!ImageInspector.isWithinPixelLimit(clean, detected.extension)) {
      throw ApiException.unprocessable(
        'Dimensi gambar tidak valid atau melebihi batas.',
        code: 'INVALID_IMAGE',
      );
    }

    if (ImageInspector.containsSuspiciousScriptPayload(clean)) {
      throw ApiException.unprocessable(
        'File gambar ditolak karena mengandung pola skrip berbahaya.',
        code: 'INVALID_IMAGE',
      );
    }

    return (
      bytes: clean,
      mimeType: detected.mimeType,
      extension: detected.extension,
    );
  }

  static String _mb(int bytes) {
    final mb = bytes / 1048576;
    return '${mb.toStringAsFixed(mb == mb.roundToDouble() ? 0 : 1)} MB';
  }
}
