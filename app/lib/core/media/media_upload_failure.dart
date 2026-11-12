/// Kegagalan terstruktur pada proses pemilihan, validasi keamanan, atau
/// pengunggahan gambar.
sealed class MediaUploadFailure implements Exception {
  const MediaUploadFailure();

  @override
  String toString() => runtimeType.toString();
}

/// File ditolak karena kosong, melebihi batas ukuran (maks 2 MB),
/// header biner (magic bytes) bukan gambar yang diizinkan (JPG/PNG/WEBP),
/// dimensi gambar tidak valid, atau terdeteksi muatan skrip berbahaya.
final class MediaInvalidImageFailure extends MediaUploadFailure {
  const MediaInvalidImageFailure(this.reason);

  final MediaValidationReason reason;
}

enum MediaValidationReason {
  emptyFile,
  fileTooLarge,
  unsupportedFormat,
  corruptedHeader,
  suspiciousScriptPayload,
  invalidActorId,
}

/// Pengguna tidak memberikan izin kamera/galeri atau perangkat tidak mendukung
/// sumber gambar yang dipilih.
final class MediaPickerPermissionFailure extends MediaUploadFailure {
  const MediaPickerPermissionFailure();
}

/// Layanan unggah media belum dikonfigurasi pada environment saat ini.
final class MediaNotConfiguredFailure extends MediaUploadFailure {
  const MediaNotConfiguredFailure();
}

/// Sesi pengguna berakhir atau tidak memiliki izin untuk mengunggah media.
final class MediaUnauthorizedFailure extends MediaUploadFailure {
  const MediaUnauthorizedFailure();
}

/// Koneksi terputus atau melewati batas waktu saat mengunggah gambar.
final class MediaNetworkFailure extends MediaUploadFailure {
  const MediaNetworkFailure();
}

/// Permintaan unggah gambar dibatasi sementara oleh server (HTTP 429).
final class MediaRateLimitedFailure extends MediaUploadFailure {
  const MediaRateLimitedFailure();
}

/// Server menolak unggahan atau mengalami gangguan.
final class MediaServerFailure extends MediaUploadFailure {
  const MediaServerFailure();
}

/// Kegagalan tidak terduga saat memproses atau mengunggah gambar.
final class MediaUnexpectedFailure extends MediaUploadFailure {
  const MediaUnexpectedFailure();
}

/// Menerjemahkan [MediaUploadFailure] ke pesan pengguna berbahasa Indonesia.
String mediaUploadErrorMessage(Object error) {
  return switch (error) {
    MediaInvalidImageFailure(:final reason) => switch (reason) {
      MediaValidationReason.emptyFile =>
        'File gambar kosong atau tidak dapat dibaca.',
      MediaValidationReason.fileTooLarge =>
        'Ukuran gambar maksimal 2 MB. Pilih gambar yang lebih kecil.',
      MediaValidationReason.unsupportedFormat =>
        'Format tidak didukung. Gunakan gambar JPG, PNG, atau WEBP asli.',
      MediaValidationReason.corruptedHeader =>
        'File gambar rusak atau memiliki dimensi yang tidak valid.',
      MediaValidationReason.suspiciousScriptPayload =>
        'Gambar ditolak karena mengandung konten yang tidak aman.',
      MediaValidationReason.invalidActorId =>
        'Sesi pengguna tidak valid untuk mengunggah gambar.',
    },
    MediaPickerPermissionFailure() =>
      'Izin akses kamera atau galeri ditolak oleh perangkat.',
    MediaNotConfiguredFailure() =>
      'Layanan unggah gambar belum terhubung ke server.',
    MediaUnauthorizedFailure() =>
      'Sesi berakhir atau kamu tidak memiliki akses untuk mengubah gambar.',
    MediaNetworkFailure() =>
      'Gagal mengunggah gambar. Periksa koneksi internet lalu coba lagi.',
    MediaRateLimitedFailure() =>
      'Terlalu banyak permintaan unggah gambar. Tunggu sebentar lalu coba lagi.',
    MediaServerFailure() =>
      'Server gagal menyimpan gambar. Coba beberapa saat lagi.',
    MediaUnexpectedFailure() =>
      'Terjadi kendala saat memproses gambar. Silakan coba lagi.',
    _ => 'Terjadi kendala saat memproses gambar. Silakan coba lagi.',
  };
}
