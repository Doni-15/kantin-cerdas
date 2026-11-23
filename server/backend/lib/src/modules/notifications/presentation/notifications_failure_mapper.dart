import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';

ApiException notificationFailureException(NotificationFailure failure) {
  return switch (failure.code) {
    NotificationFailureCode.invalidInput => ApiException(
      statusCode: 400,
      code: 'NOTIFICATION_INVALID_INPUT',
      message: failure.message ?? 'Input notifikasi tidak valid.',
    ),
    NotificationFailureCode.roleNotAllowed => ApiException(
      statusCode: 403,
      code: 'NOTIFICATION_ROLE_NOT_ALLOWED',
      message:
          failure.message ??
          'Notifikasi dan realtime pesanan hanya tersedia untuk Customer dan Owner.',
    ),
    NotificationFailureCode.accountInactive => ApiException(
      statusCode: 403,
      code: 'ACCOUNT_INACTIVE',
      message: failure.message ?? 'Akun tidak aktif.',
    ),
    NotificationFailureCode.deliveryNotFound => ApiException(
      statusCode: 404,
      code: 'NOTIFICATION_DELIVERY_NOT_FOUND',
      message: failure.message ?? 'Data pengiriman notifikasi tidak ditemukan.',
    ),
    NotificationFailureCode.unavailable => ApiException(
      statusCode: 503,
      code: 'NOTIFICATION_SERVICE_UNAVAILABLE',
      message:
          failure.message ??
          'Layanan realtime dan notifikasi sementara tidak tersedia.',
    ),
  };
}
