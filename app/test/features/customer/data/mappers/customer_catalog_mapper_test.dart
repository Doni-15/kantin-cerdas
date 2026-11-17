import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_catalog_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_catalog_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/menu_item_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/stall_model.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_catalog_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';

class _StubCatalogDataSource implements CustomerCatalogDataSource {
  const _StubCatalogDataSource(this.loader);

  final Future<CustomerCatalogModel> Function() loader;

  @override
  Future<CustomerCatalogModel> getCatalog() => loader();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerCatalogMapper (LOW-03, HIGH-03, HIGH-05)', () {
    test(
      'CustomerCatalogMapper memetakan katalog valid dan menolak data harga negatif',
      () async {
        const menuModel = MenuItemModel(
          id: 'menu-1',
          name: 'Mie Goreng Spesial',
          stallId: 'stall-1',
          stallName: 'Stan Nusantara',
          block: 'Blok A',
          price: 18000,
          waitTime: '10 menit',
          description: 'Mie goreng telur',
          category: 'Mie',
          available: true,
          imageUrl:
              'https://cdn.kantincerdas.ac.id/owner-1_menu_photo_12345678.jpg',
        );
        final validModel = CustomerCatalogModel(
          stalls: [
            StallModel(
              id: 'stall-1',
              name: 'Stan Nusantara',
              block: 'Blok A',
              waitTime: '10 menit',
              description: 'Aneka masakan lokal',
              menus: const [menuModel],
              isOpen: true,
              imageUrl:
                  'https://cdn.kantincerdas.ac.id/owner-1_stall_photo_12345678.webp',
            ),
          ],
          menus: const [menuModel],
        );

        final entity = validModel.toEntity();
        expect(entity.menus.single.category, 'Mi');
        expect(
          entity.menus.single.imageUrl,
          'https://cdn.kantincerdas.ac.id/owner-1_menu_photo_12345678.jpg',
        );
        expect(entity.stalls.single.name, 'Stan Nusantara');
        expect(
          entity.stalls.single.imageUrl,
          'https://cdn.kantincerdas.ac.id/owner-1_stall_photo_12345678.webp',
        );
        expect(
          entity.stallById('stall-1')?.imageUrl,
          'https://cdn.kantincerdas.ac.id/owner-1_stall_photo_12345678.webp',
        );

        final invalidRepo = CustomerCatalogRepositoryImpl(
          dataSource: _StubCatalogDataSource(
            () async => CustomerCatalogModel(
              stalls: const [],
              menus: const [
                MenuItemModel(
                  id: 'menu-bad',
                  name: 'Nasi Goreng',
                  stallId: 'stall-1',
                  stallName: 'Stan Nusantara',
                  block: 'Blok A',
                  price: -5000,
                  waitTime: '10 menit',
                  description: 'Pedas',
                  category: 'Nasi',
                  available: true,
                ),
              ],
            ),
          ),
        );

        await expectLater(
          invalidRepo.getCatalog(),
          throwsA(isA<CustomerCatalogUnexpectedFailure>()),
        );
      },
    );
  });
}
