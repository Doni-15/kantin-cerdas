import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';

class CustomerDummyData {
  // =========================================================
  // DAPUR BU RINA
  // =========================================================

  static const nasiAyamSambalMatah = MenuItem(
    id: 'menu-001',
    name: 'Nasi Ayam Sambal Matah',
    stallId: 'stall-001',
    stallName: 'Dapur Bu Rina',
    block: 'Blok A',
    price: 18000,
    waitTime: '5–10 menit',
    description:
        'Nasi hangat, ayam suwir, sambal matah, dan lalapan segar.',
    category: 'Nasi',
  );

  static const nasiTelurDadar = MenuItem(
    id: 'menu-002',
    name: 'Nasi Telur Dadar',
    stallId: 'stall-001',
    stallName: 'Dapur Bu Rina',
    block: 'Blok A',
    price: 12000,
    waitTime: '5–10 menit',
    description:
        'Nasi hangat dengan telur dadar.',
    category: 'Nasi',
  );

  static const tehManis = MenuItem(
    id: 'menu-003',
    name: 'Teh Manis',
    stallId: 'stall-001',
    stallName: 'Dapur Bu Rina',
    block: 'Blok A',
    price: 5000,
    waitTime: '2–5 menit',
    description:
        'Teh manis segar.',
    category: 'Minuman',
  );

  static const pisangGoreng = MenuItem(
    id: 'menu-004',
    name: 'Pisang Goreng',
    stallId: 'stall-001',
    stallName: 'Dapur Bu Rina',
    block: 'Blok A',
    price: 8000,
    waitTime: '5–10 menit',
    description:
        'Pisang goreng hangat dan renyah.',
    category: 'Camilan',
  );

  // =========================================================
  // KEDAI PAK UCOK
  // =========================================================

  static const miGomak = MenuItem(
    id: 'menu-005',
    name: 'Mi Gomak',
    stallId: 'stall-002',
    stallName: 'Kedai Pak Ucok',
    block: 'Blok B',
    price: 15000,
    waitTime: '5–10 menit',
    description:
        'Mi gomak dengan bumbu khas yang gurih dan pedas.',
    category: 'Mi',
  );

  static const miKuahSpesial = MenuItem(
    id: 'menu-006',
    name: 'Mi Kuah Spesial',
    stallId: 'stall-002',
    stallName: 'Kedai Pak Ucok',
    block: 'Blok B',
    price: 22000,
    waitTime: '15–20 menit',
    description:
        'Mi kuah dengan telur, sayuran, dan bumbu spesial.',
    category: 'Mi',
  );

  static const esJeruk = MenuItem(
    id: 'menu-007',
    name: 'Es Jeruk',
    stallId: 'stall-002',
    stallName: 'Kedai Pak Ucok',
    block: 'Blok B',
    price: 7000,
    waitTime: '5–10 menit',
    description:
        'Minuman jeruk segar.',
    category: 'Minuman',
    available: false,
  );

  static const kopiSusu = MenuItem(
    id: 'menu-008',
    name: 'Kopi Susu',
    stallId: 'stall-002',
    stallName: 'Kedai Pak Ucok',
    block: 'Blok B',
    price: 10000,
    waitTime: '5–10 menit',
    description:
        'Kopi susu dengan rasa manis dan creamy.',
    category: 'Minuman',
  );

  // =========================================================
  // LIST MENU PER STAN
  // =========================================================

  static const dapurBuRinaMenus = [
    nasiAyamSambalMatah,
    nasiTelurDadar,
    tehManis,
    pisangGoreng,
  ];

  static const kedaiPakUcokMenus = [
    miGomak,
    miKuahSpesial,
    esJeruk,
    kopiSusu,
  ];

  // =========================================================
  // DATA STAN
  // =========================================================

  static const dapurBuRina = Stall(
    id: 'stall-001',
    name: 'Dapur Bu Rina',
    block: 'Blok A',
    waitTime: '5–10 menit',
    description:
        'Masakan rumahan, hangat setiap hari.',
    menus: dapurBuRinaMenus,
  );

  static const kedaiPakUcok = Stall(
    id: 'stall-002',
    name: 'Kedai Pak Ucok',
    block: 'Blok B',
    waitTime: '5–10 menit',
    description:
        'Mi dan minuman khas dengan rasa rumahan.',
    menus: kedaiPakUcokMenus,
  );

  // =========================================================
  // STAN YANG DITAMPILKAN
  // =========================================================

  static const stalls = [
    dapurBuRina,
    kedaiPakUcok,
  ];

  // =========================================================
  // MENU HOMEPAGE
  // =========================================================

  static const homeMenus = [
    nasiAyamSambalMatah,
    nasiTelurDadar,
    miGomak,
    tehManis,
    pisangGoreng,
  ];

  // =========================================================
  // SEMUA MENU UNTUK SEARCH
  // =========================================================

  static const semuaMenu = [
    nasiAyamSambalMatah,
    nasiTelurDadar,
    tehManis,
    pisangGoreng,
    miGomak,
    miKuahSpesial,
    esJeruk,
    kopiSusu,
  ];
}