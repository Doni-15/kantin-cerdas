import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_catalog_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';

void main() {
  group('Pemetaan HTTP 429 untuk unggahan media dan katalog', () {
    test(
      'pemetaan HTTP 429 menghasilkan MediaRateLimitedFailure dan CustomerCatalogServerFailure secara eksplisit',
      () {
        expect(
          mediaUploadErrorMessage(const MediaRateLimitedFailure()),
          'Terlalu banyak permintaan unggah gambar. Tunggu sebentar lalu coba lagi.',
        );
        expect(
          mapCustomerCatalogApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 429,
              message: 'Too Many Requests',
            ),
          ),
          isA<CustomerCatalogServerFailure>(),
        );
      },
    );
  });
}
