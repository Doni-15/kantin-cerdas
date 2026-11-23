import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

AuthException mapOwnerEnvelopeError(
  int statusCode,
  Map<String, dynamic> envelope,
) {
  final error = envelope['error'];
  final code = error is Map<String, dynamic> ? error['code'] : null;
  final mapped = switch ((statusCode, code)) {
    (403, 'OWNER_ROLE_REQUIRED') => const AuthException(
      'OWNER_ROLE_REQUIRED',
      'Akses ini hanya untuk akun Owner yang telah disetujui.',
    ),
    (409, 'STALL_ALREADY_EXISTS') => const AuthException(
      'STALL_ALREADY_EXISTS',
      'Setiap akun Owner hanya boleh memiliki satu kantin.',
    ),
    (404, 'STALL_NOT_FOUND') => const AuthException(
      'STALL_NOT_FOUND',
      'Profil kantin belum ditemukan.',
    ),
    (409, 'STALL_ALREADY_PUBLISHED') => const AuthException(
      'STALL_ALREADY_PUBLISHED',
      'Kantin sudah diterbitkan.',
    ),
    (409, 'STALL_NOT_PUBLISHED') => const AuthException(
      'STALL_NOT_PUBLISHED',
      'Terbitkan kantin terlebih dahulu sebelum mengubah status Buka/Tutup.',
    ),
    (422, 'PUBLISH_PROFILE_INCOMPLETE') => const AuthException(
      'PUBLISH_PROFILE_INCOMPLETE',
      'Lengkapi nama kantin, kampus, dan lokasi fisik terlebih dahulu.',
    ),
    (422, 'PUBLISH_MENU_REQUIRED') => const AuthException(
      'PUBLISH_MENU_REQUIRED',
      'Tambahkan minimal satu menu berstatus Tersedia sebelum menerbitkan.',
    ),
    (409, 'UNPUBLISH_NOT_ALLOWED') => const AuthException(
      'UNPUBLISH_NOT_ALLOWED',
      'Kantin yang sudah diterbitkan tidak dapat dibatalkan publikasinya.',
    ),
    (400, 'INVALID_SCHEDULE') => const AuthException(
      'INVALID_SCHEDULE',
      'Periksa kembali jam operasional yang dimasukkan.',
    ),
    (404, 'CATEGORY_NOT_FOUND') => const AuthException(
      'CATEGORY_NOT_FOUND',
      'Kategori tidak ditemukan.',
    ),
    (409, 'CATEGORY_NAME_EXISTS') => const AuthException(
      'CATEGORY_NAME_EXISTS',
      'Nama kategori sudah digunakan di kantin ini.',
    ),
    (409, 'CATEGORY_NOT_EMPTY') => const AuthException(
      'CATEGORY_NOT_EMPTY',
      'Kategori masih memiliki menu aktif atau arsip. Pindahkan semua menu terlebih dahulu.',
    ),
    (404, 'MENU_NOT_FOUND') => const AuthException(
      'MENU_NOT_FOUND',
      'Menu tidak ditemukan.',
    ),
    (404, 'ORDER_NOT_FOUND') => const AuthException(
      'ORDER_NOT_FOUND',
      'Pesanan tidak ditemukan.',
    ),
    (409, 'INVALID_ORDER_TRANSITION') => const AuthException(
      'INVALID_ORDER_TRANSITION',
      'Status pesanan sudah berubah atau tindakan ini tidak lagi diizinkan.',
    ),
    (422, 'REASON_REQUIRED') => const AuthException(
      'REASON_REQUIRED',
      'Alasan wajib diisi.',
    ),
    (422, 'COMPLETE_CONFIRMATION_REQUIRED') => const AuthException(
      'COMPLETE_CONFIRMATION_REQUIRED',
      'Pastikan uang tunai telah diterima dan makanan telah diserahkan.',
    ),
    (422, 'INVALID_MEDIA_PHOTO') => const AuthException(
      'INVALID_MEDIA_PHOTO',
      'Pilih foto yang valid, maksimal 4096 × 4096 piksel.',
    ),
    (503, 'OWNER_UNAVAILABLE') => const AuthException(
      'OWNER_UNAVAILABLE',
      'Layanan Owner sedang tidak tersedia. Coba lagi beberapa saat.',
    ),
    _ => null,
  };
  return mapped ?? mapAuthEnvelopeError(statusCode, envelope);
}
