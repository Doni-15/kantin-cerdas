import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu_item.dart';

class OwnerCanteenDummyData {
  static const menus = [
    OwnerMenuItem(
      id: 'menu-001',
      name: 'Nasi Ayam Sambal Matah',
      price: 18000,
      category: 'Makanan',
      available: true,
    ),
    OwnerMenuItem(
      id: 'menu-002',
      name: 'Nasi Telur Dadar',
      price: 12000,
      category: 'Makanan',
      available: true,
    ),
    OwnerMenuItem(
      id: 'menu-003',
      name: 'Sayur Asem',
      price: 6000,
      category: 'Makanan',
      available: false,
    ),
    OwnerMenuItem(
      id: 'menu-004',
      name: 'Es Teh Manis',
      price: 5000,
      category: 'Minuman',
      available: true,
    ),
    OwnerMenuItem(
      id: 'menu-005',
      name: 'Nasi Ayam Kecap',
      price: 17000,
      category: 'Makanan',
      available: true,
    ),
    OwnerMenuItem(
      id: 'menu-006',
      name: 'Teh Tawar',
      price: 3000,
      category: 'Minuman',
      available: true,
    ),
  ];
}