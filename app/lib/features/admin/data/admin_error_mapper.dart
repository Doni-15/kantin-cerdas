import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

AuthException mapAdminEnvelopeError(
  int statusCode,
  Map<String, dynamic> envelope,
) {
  final error = envelope['error'];
  final code = error is Map<String, dynamic> ? error['code'] : null;
  final mapped = switch ((statusCode, code)) {
    (403, 'ADMIN_ROLE_REQUIRED') => const AuthException(
      'ADMIN_ROLE_REQUIRED',
      'Akses ini hanya tersedia untuk akun Admin yang aktif.',
    ),
    (404, 'APPLICATION_NOT_FOUND') => const AuthException(
      'APPLICATION_NOT_FOUND',
      'Pengajuan Owner tidak ditemukan.',
    ),
    (409, 'APPLICATION_ALREADY_DECIDED') => const AuthException(
      'APPLICATION_ALREADY_DECIDED',
      'Pengajuan ini sudah diputuskan sebelumnya. Data terbaru telah dimuat.',
    ),
    (409, 'ALREADY_OWNER') => const AuthException(
      'ALREADY_OWNER',
      'Pengguna sudah berstatus Owner.',
    ),
    (409, 'TARGET_NOT_CUSTOMER') => const AuthException(
      'TARGET_NOT_CUSTOMER',
      'Hanya akun Customer yang dapat disetujui menjadi Owner.',
    ),
    (404, 'USER_NOT_FOUND') => const AuthException(
      'USER_NOT_FOUND',
      'Akun pengguna tidak ditemukan.',
    ),
    (409, 'USER_INACTIVE') => const AuthException(
      'USER_INACTIVE',
      'Akun pemohon sedang dinonaktifkan.',
    ),
    (409, 'USER_ALREADY_INACTIVE') => const AuthException(
      'USER_ALREADY_INACTIVE',
      'Akun pengguna sudah dalam status Nonaktif.',
    ),
    (409, 'USER_ALREADY_ACTIVE') => const AuthException(
      'USER_ALREADY_ACTIVE',
      'Akun pengguna sudah dalam status Aktif.',
    ),
    (409, 'SELF_DEACTIVATION_NOT_ALLOWED') => const AuthException(
      'SELF_DEACTIVATION_NOT_ALLOWED',
      'Anda tidak dapat menonaktifkan akun Admin Anda sendiri.',
    ),
    (409, 'LAST_ADMIN_PROTECTED') => const AuthException(
      'LAST_ADMIN_PROTECTED',
      'Admin aktif terakhir tidak dapat dinonaktifkan.',
    ),
    (409, 'ACTIVE_ORDERS_PRESENT') => const AuthException(
      'ACTIVE_ORDERS_PRESENT',
      'Akun masih memiliki pesanan aktif sehingga tindakan ditolak.',
    ),
    (404, 'STALL_NOT_FOUND') => const AuthException(
      'STALL_NOT_FOUND',
      'Kantin tidak ditemukan.',
    ),
    (422, 'REASON_REQUIRED') => const AuthException(
      'REASON_REQUIRED',
      'Alasan wajib diisi untuk tindakan ini.',
    ),
    (503, 'ADMIN_UNAVAILABLE') => const AuthException(
      'ADMIN_UNAVAILABLE',
      'Layanan Admin sedang tidak tersedia. Coba lagi beberapa saat.',
    ),
    _ => null,
  };
  return mapped ?? mapAuthEnvelopeError(statusCode, envelope);
}
