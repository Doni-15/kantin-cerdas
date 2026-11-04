import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';

/// Mengubah error API katalog menjadi [CustomerCatalogFailure] domain.
CustomerCatalogFailure mapCustomerCatalogApiException(ApiException exception) {
  final statusCode = exception.statusCode;

  return switch (exception.type) {
    ApiExceptionType.connection ||
    ApiExceptionType.timeout => const CustomerCatalogNetworkFailure(),
    ApiExceptionType.response
        when statusCode == 429 ||
            (statusCode != null && statusCode >= 500 && statusCode <= 599) =>
      const CustomerCatalogServerFailure(),
    ApiExceptionType.response ||
    ApiExceptionType.cancelled ||
    ApiExceptionType.unexpected => const CustomerCatalogUnexpectedFailure(),
  };
}
