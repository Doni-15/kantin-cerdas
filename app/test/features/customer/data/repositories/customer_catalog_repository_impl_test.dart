import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_catalog_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_catalog_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerCatalogRepositoryImpl (LOW-03, HIGH-03, HIGH-05)', () {
    test(
      'CustomerCatalogRepositoryImpl meneruskan CustomerCatalogNotConfiguredFailure secara spesifik',
      () async {
        const repo = CustomerCatalogRepositoryImpl(
          dataSource: CustomerCatalogApiDataSource(),
        );
        await expectLater(
          repo.getCatalog(),
          throwsA(isA<CustomerCatalogNotConfiguredFailure>()),
        );
        expect(
          customerCatalogErrorTitle(
            const CustomerCatalogNotConfiguredFailure(),
          ),
          'Layanan katalog belum terhubung',
        );
        expect(
          customerCatalogErrorTitle(const CustomerCatalogNetworkFailure()),
          'Koneksi katalog terputus',
        );
      },
    );
  });
}
