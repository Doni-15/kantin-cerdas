import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';

AdminFailure mapAdminReadApiException(ApiException error) {
  final statusCode = error.statusCode;
  return switch (error.type) {
    ApiExceptionType.timeout ||
    ApiExceptionType.connection => const AdminReadTimeoutFailure(),
    ApiExceptionType.response
        when statusCode == 429 ||
            (statusCode != null && statusCode >= 500 && statusCode <= 599) =>
      const AdminReadTimeoutFailure(),
    ApiExceptionType.response when statusCode == 401 || statusCode == 403 =>
      const AdminAccessFailure(),
    _ => const AdminInvalidDataFailure(),
  };
}

AdminFailure mapAdminUserAccessApiException(ApiException error) {
  if (error.type == ApiExceptionType.response && error.hasBackendErrorCode) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const AdminAccessFailure();
    }
    if (error.statusCode == 409 || error.code == 'VERSION_CONFLICT') {
      return const AdminUserAccessConflictFailure();
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const AdminUserAccessRejectedFailure();
    }
  }
  return const AdminUserAccessUnknownFailure();
}

AdminFailure mapAdminReviewApiException(ApiException error) {
  if (error.type == ApiExceptionType.response && error.hasBackendErrorCode) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const AdminAccessFailure();
    }
    if (error.statusCode == 409 || error.code == 'VERSION_CONFLICT') {
      return const AdminReviewConflictFailure();
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const AdminReviewRejectedFailure();
    }
  }
  return const AdminReviewUnknownFailure();
}
