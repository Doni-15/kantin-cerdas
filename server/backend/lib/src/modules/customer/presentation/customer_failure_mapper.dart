import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';

ApiException customerFailureException(CustomerFailure failure) {
  final (statusCode, code, defaultMessage) = switch (failure.code) {
    CustomerFailureCode.customerRoleRequired => (
      403,
      'CUSTOMER_ROLE_REQUIRED',
      'Tindakan ini hanya tersedia untuk akun Customer.',
    ),
    CustomerFailureCode.alreadyOwner => (
      409,
      'ALREADY_OWNER',
      'Akun ini sudah berstatus Owner.',
    ),
    CustomerFailureCode.stallNotFound => (
      404,
      'STALL_NOT_FOUND',
      'Kantin tidak ditemukan.',
    ),
    CustomerFailureCode.menuNotFound => (
      404,
      'MENU_NOT_FOUND',
      'Menu tidak ditemukan.',
    ),
    CustomerFailureCode.stallClosed => (
      409,
      'STALL_CLOSED',
      'Kantin sedang tutup dan belum menerima pesanan baru.',
    ),
    CustomerFailureCode.ownerInactive => (
      409,
      'OWNER_INACTIVE',
      'Kantin sementara tidak menerima pesanan.',
    ),
    CustomerFailureCode.customerInactive => (
      403,
      'ACCOUNT_INACTIVE',
      'Akun Anda sedang dinonaktifkan.',
    ),
    CustomerFailureCode.emailNotVerified => (
      403,
      'EMAIL_NOT_VERIFIED',
      'Verifikasi email terlebih dahulu sebelum memesan.',
    ),
    CustomerFailureCode.menuArchived => (
      409,
      'MENU_ARCHIVED',
      'Salah satu menu di keranjang tidak tersedia (diarsipkan).',
    ),
    CustomerFailureCode.menuUnavailable => (
      409,
      'MENU_UNAVAILABLE',
      'Salah satu menu di keranjang sedang habis.',
    ),
    CustomerFailureCode.cartDifferentStall => (
      409,
      'CART_DIFFERENT_STALL',
      'Keranjang saat ini berisi menu dari kantin lain. Konfirmasi penggantian isi keranjang terlebih dahulu.',
    ),
    CustomerFailureCode.cartItemNotFound => (
      404,
      'CART_ITEM_NOT_FOUND',
      'Item keranjang tidak ditemukan.',
    ),
    CustomerFailureCode.cartEmpty => (
      409,
      'CART_EMPTY',
      'Keranjang kosong. Tambahkan menu terlebih dahulu.',
    ),
    CustomerFailureCode.cartVersionConflict => (
      409,
      'CART_VERSION_CONFLICT',
      'Keranjang telah diperbarui. Muat ulang ringkasan keranjang sebelum melanjutkan.',
    ),
    CustomerFailureCode.priceChanged => (
      409,
      'PRICE_CHANGED',
      'Harga menu di keranjang telah berubah. Tinjau dan setujui harga terbaru terlebih dahulu.',
    ),
    CustomerFailureCode.idempotencyConflict => (
      409,
      'IDEMPOTENCY_CONFLICT',
      'Permintaan checkout bertentangan dengan pengiriman sebelumnya.',
    ),
    CustomerFailureCode.orderNotFound => (
      404,
      'ORDER_NOT_FOUND',
      'Pesanan tidak ditemukan.',
    ),
    CustomerFailureCode.invalidOrderTransition => (
      409,
      'INVALID_ORDER_TRANSITION',
      'Pesanan sudah diproses dan tidak dapat dibatalkan.',
    ),
    CustomerFailureCode.applicationAlreadyPending => (
      409,
      'APPLICATION_ALREADY_PENDING',
      'Pengajuan Owner sebelumnya masih menunggu pemeriksaan Admin.',
    ),
    CustomerFailureCode.unsupportedMediaType => (
      415,
      'UNSUPPORTED_MEDIA_TYPE',
      'Gunakan Content-Type application/json.',
    ),
    CustomerFailureCode.payloadTooLarge => (
      413,
      'REQUEST_BODY_TOO_LARGE',
      'Ukuran permintaan melebihi batas.',
    ),
    CustomerFailureCode.invalidInput => (
      400,
      'INVALID_INPUT',
      'Periksa kembali data yang dimasukkan.',
    ),
    CustomerFailureCode.unavailable => (
      503,
      'CUSTOMER_UNAVAILABLE',
      'Layanan Customer sedang tidak tersedia. Coba lagi.',
    ),
  };

  return ApiException(
    statusCode: statusCode,
    code: code,
    message: failure.message ?? defaultMessage,
  );
}
