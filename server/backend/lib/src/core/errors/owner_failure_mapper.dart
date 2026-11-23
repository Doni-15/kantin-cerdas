import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';

ApiException ownerFailureException(OwnerFailure failure) {
  final (statusCode, code, defaultMessage) = switch (failure.code) {
    OwnerFailureCode.ownerRoleRequired => (
      403,
      'OWNER_ROLE_REQUIRED',
      'Akses ini hanya untuk akun Owner yang telah disetujui.',
    ),
    OwnerFailureCode.stallAlreadyExists => (
      409,
      'STALL_ALREADY_EXISTS',
      'Setiap akun Owner hanya dapat memiliki satu kantin.',
    ),
    OwnerFailureCode.stallNotFound => (
      404,
      'STALL_NOT_FOUND',
      'Profil kantin belum dibuat.',
    ),
    OwnerFailureCode.stallAlreadyPublished => (
      409,
      'STALL_ALREADY_PUBLISHED',
      'Kantin sudah diterbitkan sebelumnya.',
    ),
    OwnerFailureCode.stallNotPublished => (
      409,
      'STALL_NOT_PUBLISHED',
      'Terbitkan kantin terlebih dahulu sebelum mengubah status Buka/Tutup.',
    ),
    OwnerFailureCode.publishProfileIncomplete => (
      422,
      'PUBLISH_PROFILE_INCOMPLETE',
      'Lengkapi nama kantin, kampus, dan lokasi fisik sebelum menerbitkan.',
    ),
    OwnerFailureCode.publishMenuRequired => (
      422,
      'PUBLISH_MENU_REQUIRED',
      'Tambahkan minimal satu menu berstatus Tersedia sebelum menerbitkan kantin.',
    ),
    OwnerFailureCode.unpublishNotAllowed => (
      409,
      'UNPUBLISH_NOT_ALLOWED',
      'Kantin yang sudah diterbitkan tidak dapat dibatalkan publikasinya.',
    ),
    OwnerFailureCode.invalidSchedule => (
      400,
      'INVALID_SCHEDULE',
      'Format jam operasional tidak valid.',
    ),
    OwnerFailureCode.categoryNotFound => (
      404,
      'CATEGORY_NOT_FOUND',
      'Kategori tidak ditemukan.',
    ),
    OwnerFailureCode.categoryNameExists => (
      409,
      'CATEGORY_NAME_EXISTS',
      'Nama kategori sudah digunakan di kantin ini.',
    ),
    OwnerFailureCode.categoryNotEmpty => (
      409,
      'CATEGORY_NOT_EMPTY',
      'Kategori masih memiliki menu aktif atau arsip. Pindahkan semua menu terlebih dahulu.',
    ),
    OwnerFailureCode.menuNotFound => (
      404,
      'MENU_NOT_FOUND',
      'Menu tidak ditemukan.',
    ),
    OwnerFailureCode.orderNotFound => (
      404,
      'ORDER_NOT_FOUND',
      'Pesanan tidak ditemukan.',
    ),
    OwnerFailureCode.invalidOrderTransition => (
      409,
      'INVALID_ORDER_TRANSITION',
      'Status pesanan sudah berubah atau tindakan tidak diizinkan pada status ini.',
    ),
    OwnerFailureCode.reasonRequired => (
      422,
      'REASON_REQUIRED',
      'Alasan wajib diisi untuk tindakan ini.',
    ),
    OwnerFailureCode.completeConfirmationRequired => (
      422,
      'COMPLETE_CONFIRMATION_REQUIRED',
      'Konfirmasikan bahwa uang tunai telah diterima dan makanan telah diserahkan.',
    ),
    OwnerFailureCode.invalidImage => (
      422,
      'INVALID_MEDIA_PHOTO',
      'Pilih foto yang valid dengan ukuran hingga 4096 × 4096 piksel.',
    ),
    OwnerFailureCode.unsupportedMediaType => (
      415,
      'UNSUPPORTED_MEDIA_TYPE',
      'Format foto harus JPEG, PNG, atau WebP.',
    ),
    OwnerFailureCode.imageTooLarge => (
      413,
      'REQUEST_BODY_TOO_LARGE',
      'Ukuran foto maksimal 2 MB.',
    ),
    OwnerFailureCode.invalidInput => (
      400,
      'INVALID_INPUT',
      'Periksa kembali data yang dimasukkan.',
    ),
    OwnerFailureCode.unavailable => (
      503,
      'OWNER_UNAVAILABLE',
      'Layanan Owner sedang tidak tersedia. Coba lagi.',
    ),
  };

  return ApiException(
    statusCode: statusCode,
    code: code,
    message: failure.message ?? defaultMessage,
  );
}
