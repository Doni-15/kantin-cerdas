import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';

/// Hasil pemilihan gambar mentah dari perangkat sebelum divalidasi oleh
/// [ImageSecurityValidator].
///
/// Sengaja tidak menyimpan nama file asli dari perangkat agar tidak pernah
/// dipercaya atau digunakan oleh aplikasi maupun server.
final class RawPickedImage {
  RawPickedImage({required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final Uint8List bytes;
}

/// Kontrak abstraksi pemilihan gambar dari kamera atau galeri perangkat (DIP).
abstract interface class ImagePickerPort {
  /// Membuka pemilih gambar sesuai [source].
  /// Mengembalikan `null` jika pengguna membatalkan pemilihan.
  Future<RawPickedImage?> pickImage(ImagePickSource source);
}

final imagePickerPortProvider = Provider<ImagePickerPort>((ref) {
  throw UnimplementedError(
    'imagePickerPortProvider must be overridden via production or test overrides.',
  );
});
