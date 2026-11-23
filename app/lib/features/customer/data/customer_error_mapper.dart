import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

AuthException mapCustomerEnvelopeError(
  int statusCode,
  Map<String, dynamic> envelope,
) {
  final error = envelope['error'];
  final code = error is Map<String, dynamic> ? error['code'] : null;
  final mapped = switch ((statusCode, code)) {
    (403, 'CUSTOMER_ROLE_REQUIRED') => const AuthException(
      'CUSTOMER_ROLE_REQUIRED',
      'Tindakan ini hanya tersedia untuk akun Customer.',
    ),
    (409, 'ALREADY_OWNER') => const AuthException(
      'ALREADY_OWNER',
      'Akun ini sudah berstatus Owner.',
    ),
    (404, 'STALL_NOT_FOUND') => const AuthException(
      'STALL_NOT_FOUND',
      'Kantin tidak ditemukan atau sudah tidak tersedia.',
    ),
    (404, 'MENU_NOT_FOUND') => const AuthException(
      'MENU_NOT_FOUND',
      'Menu tidak ditemukan.',
    ),
    (409, 'STALL_CLOSED') => const AuthException(
      'STALL_CLOSED',
      'Kantin sedang tutup dan belum menerima pesanan baru.',
    ),
    (409, 'OWNER_INACTIVE') => const AuthException(
      'OWNER_INACTIVE',
      'Kantin sementara tidak menerima pesanan.',
    ),
    (403, 'EMAIL_NOT_VERIFIED') => const AuthException(
      'EMAIL_NOT_VERIFIED',
      'Verifikasi email Anda sebelum membuat pesanan.',
    ),
    (409, 'MENU_ARCHIVED') => const AuthException(
      'MENU_ARCHIVED',
      'Menu tidak tersedia (diarsipkan). Hapus dari keranjang untuk melanjutkan.',
    ),
    (409, 'MENU_UNAVAILABLE') => const AuthException(
      'MENU_UNAVAILABLE',
      'Menu sedang habis. Periksa keranjang Anda.',
    ),
    (409, 'CART_DIFFERENT_STALL') => const AuthException(
      'CART_DIFFERENT_STALL',
      'Keranjang saat ini berisi menu dari kantin lain. Ganti seluruh isi keranjang?',
    ),
    (404, 'CART_ITEM_NOT_FOUND') => const AuthException(
      'CART_ITEM_NOT_FOUND',
      'Item tidak lagi ditemukan di keranjang.',
    ),
    (409, 'CART_EMPTY') => const AuthException(
      'CART_EMPTY',
      'Keranjang kosong. Tambahkan menu terlebih dahulu.',
    ),
    (409, 'CART_VERSION_CONFLICT') => const AuthException(
      'CART_VERSION_CONFLICT',
      'Keranjang telah berubah. Tinjau ulang sebelum mengirim pesanan.',
    ),
    (409, 'PRICE_CHANGED') => const AuthException(
      'PRICE_CHANGED',
      'Harga menu telah berubah. Setujui harga terbaru sebelum melanjutkan checkout.',
    ),
    (409, 'IDEMPOTENCY_CONFLICT') => const AuthException(
      'IDEMPOTENCY_CONFLICT',
      'Upaya checkout ini bertentangan dengan pengiriman sebelumnya. Muat ulang keranjang.',
    ),
    (404, 'ORDER_NOT_FOUND') => const AuthException(
      'ORDER_NOT_FOUND',
      'Pesanan tidak ditemukan.',
    ),
    (409, 'INVALID_ORDER_TRANSITION') => const AuthException(
      'INVALID_ORDER_TRANSITION',
      'Pesanan sudah diproses dan tidak dapat dibatalkan.',
    ),
    (409, 'APPLICATION_ALREADY_PENDING') => const AuthException(
      'APPLICATION_ALREADY_PENDING',
      'Pengajuan sebelumnya masih menunggu pemeriksaan Admin.',
    ),
    (503, 'CUSTOMER_UNAVAILABLE') => const AuthException(
      'CUSTOMER_UNAVAILABLE',
      'Layanan Customer sedang tidak tersedia. Coba lagi.',
    ),
    _ => null,
  };
  return mapped ?? mapAuthEnvelopeError(statusCode, envelope);
}
