import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';

/// Kontrak repositori pengunggahan gambar yang telah divalidasi ke layanan media
/// backend dan mengembalikan URL gambar kanonis (`https://...` atau `http://...`).
abstract interface class MediaUploadRepository {
  bool get isConfigured;

  /// Mengunggah [image] yang sudah tervalidasi dan mengembalikan URL gambar
  /// yang aman.
  Future<String> uploadImage(ValidatedUploadImage image);
}

final mediaUploadRepositoryProvider = Provider<MediaUploadRepository>((ref) {
  throw UnimplementedError(
    'mediaUploadRepositoryProvider must be overridden via production or test overrides.',
  );
});
