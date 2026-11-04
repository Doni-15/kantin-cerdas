import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';

OwnerFailure mapOwnerReadApiException(ApiException error) {
  final statusCode = error.statusCode;
  return switch (error.type) {
    ApiExceptionType.timeout ||
    ApiExceptionType.connection => const OwnerReadTimeoutFailure(),
    ApiExceptionType.response
        when statusCode == 429 ||
            (statusCode != null && statusCode >= 500 && statusCode <= 599) =>
      const OwnerReadTimeoutFailure(),
    ApiExceptionType.response when statusCode == 401 || statusCode == 403 =>
      const OwnerForbiddenFailure(),
    ApiExceptionType.response when error.code == 'NO_STALL' =>
      const OwnerNoStallFailure(),
    _ => const OwnerInvalidDataFailure(),
  };
}

OwnerFailure mapOwnerMutationApiException(ApiException error) {
  if (error.type == ApiExceptionType.response && error.hasBackendErrorCode) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const OwnerForbiddenFailure();
    }
    if (error.code == 'NO_STALL') {
      return const OwnerNoStallFailure();
    }
    if (error.statusCode == 409 || error.code == 'VERSION_CONFLICT') {
      return const OwnerConflictFailure();
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const OwnerRejectedFailure();
    }
  }
  return const OwnerUnconfirmedFailure();
}
