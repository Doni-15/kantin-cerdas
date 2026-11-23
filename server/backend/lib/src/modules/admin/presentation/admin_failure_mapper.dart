import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';

ApiException adminFailureException(AdminFailure failure) {
  final (statusCode, code, defaultMessage) = switch (failure.code) {
    AdminFailureCode.adminRoleRequired => (
      403,
      'ADMIN_ROLE_REQUIRED',
      'Akses ini hanya tersedia untuk akun Admin yang aktif.',
    ),
    AdminFailureCode.adminInactive => (
      403,
      'ACCOUNT_INACTIVE',
      'Akun Admin sedang dinonaktifkan.',
    ),
    AdminFailureCode.applicationNotFound => (
      404,
      'APPLICATION_NOT_FOUND',
      'Pengajuan Owner tidak ditemukan.',
    ),
    AdminFailureCode.applicationAlreadyDecided => (
      409,
      'APPLICATION_ALREADY_DECIDED',
      'Pengajuan Owner ini sudah diputuskan sebelumnya.',
    ),
    AdminFailureCode.alreadyOwner => (
      409,
      'ALREADY_OWNER',
      'Pengguna sudah berstatus Owner.',
    ),
    AdminFailureCode.targetNotCustomer => (
      409,
      'TARGET_NOT_CUSTOMER',
      'Hanya akun Customer yang dapat disetujui menjadi Owner.',
    ),
    AdminFailureCode.userNotFound => (
      404,
      'USER_NOT_FOUND',
      'Akun pengguna tidak ditemukan.',
    ),
    AdminFailureCode.userInactive => (
      409,
      'USER_INACTIVE',
      'Akun pemohon sedang dinonaktifkan.',
    ),
    AdminFailureCode.userAlreadyInactive => (
      409,
      'USER_ALREADY_INACTIVE',
      'Akun pengguna sudah dalam status Nonaktif.',
    ),
    AdminFailureCode.userAlreadyActive => (
      409,
      'USER_ALREADY_ACTIVE',
      'Akun pengguna sudah dalam status Aktif.',
    ),
    AdminFailureCode.selfDeactivationNotAllowed => (
      409,
      'SELF_DEACTIVATION_NOT_ALLOWED',
      'Admin tidak dapat menonaktifkan akunnya sendiri.',
    ),
    AdminFailureCode.lastAdminProtected => (
      409,
      'LAST_ADMIN_PROTECTED',
      'Admin aktif terakhir tidak dapat dinonaktifkan.',
    ),
    AdminFailureCode.activeOrdersPresent => (
      409,
      'ACTIVE_ORDERS_PRESENT',
      'Tindakan ditolak karena akun masih memiliki pesanan aktif.',
    ),
    AdminFailureCode.stallNotFound => (
      404,
      'STALL_NOT_FOUND',
      'Kantin tidak ditemukan.',
    ),
    AdminFailureCode.reasonRequired => (
      422,
      'REASON_REQUIRED',
      'Alasan wajib diisi untuk tindakan ini.',
    ),
    AdminFailureCode.unsupportedMediaType => (
      415,
      'UNSUPPORTED_MEDIA_TYPE',
      'Content-Type harus application/json.',
    ),
    AdminFailureCode.payloadTooLarge => (
      413,
      'PAYLOAD_TOO_LARGE',
      'Ukuran payload melebihi batas yang diizinkan.',
    ),
    AdminFailureCode.invalidInput => (
      400,
      'INVALID_INPUT',
      'Data permintaan Admin tidak valid.',
    ),
    AdminFailureCode.unavailable => (
      503,
      'ADMIN_UNAVAILABLE',
      'Layanan Admin sedang tidak tersedia. Coba lagi beberapa saat.',
    ),
  };

  return ApiException(
    statusCode: statusCode,
    code: code,
    message: failure.message ?? defaultMessage,
  );
}
