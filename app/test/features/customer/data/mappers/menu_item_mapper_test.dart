import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/menu_item_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/models/menu_item_model.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';

void main() {
  group('MenuCategory & Normalisasi Kategori', () {
    test('menormalisasi label Mie dan noodles menjadi Mi secara konsisten', () {
      expect(MenuCategory.fromRaw('Mie'), MenuCategory.noodles);
      expect(MenuCategory.fromRaw('Mi'), MenuCategory.noodles);
      expect(MenuCategory.fromRaw('noodles'), MenuCategory.noodles);
      expect(MenuCategory.normalizeLabel('Mie'), 'Mi');
      expect(ownerCategoryLabel(OwnerMenuCategory.noodles), 'Mi');

      const model = MenuItemModel(
        id: 'm-1',
        name: 'Mi Goreng Spesial',
        stallId: 's-1',
        stallName: 'Kantin A',
        block: 'Blok A',
        price: 15000,
        waitTime: '10 mnt',
        description: 'Pedas manis',
        category: 'Mie',
        available: true,
      );
      expect(model.toEntity().category, 'Mi');
    });
  });
}
