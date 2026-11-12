/// Sumber pemilihan gambar dari perangkat pengguna.
enum ImagePickSource { camera, gallery }

/// Kategori peruntukan unggahan gambar yang menentukan prefix nama file aman
/// dan folder penyimpanan di backend.
enum MediaUploadCategory {
  profileAvatar('profile_avatar'),
  menuPhoto('menu_photo'),
  stallPhoto('stall_photo');

  const MediaUploadCategory(this.slug);

  /// Identifier aman untuk nama file dan field form-data (`profile_avatar`,
  /// `menu_photo`, `stall_photo`).
  final String slug;
}

/// Format biner gambar yang diizinkan berdasarkan pemeriksaan Magic Bytes.
enum DetectedImageFormat {
  jpeg(mimeType: 'image/jpeg', extension: 'jpg'),
  png(mimeType: 'image/png', extension: 'png'),
  webp(mimeType: 'image/webp', extension: 'webp');

  const DetectedImageFormat({required this.mimeType, required this.extension});

  final String mimeType;
  final String extension;
}
