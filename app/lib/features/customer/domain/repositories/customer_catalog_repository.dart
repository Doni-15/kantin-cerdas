import 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';

/// Kontrak pembacaan katalog pelanggan.
abstract interface class CustomerCatalogRepository {
  /// Mengembalikan katalog ketika pemuatan berhasil.
  ///
  /// Katalog kosong sah jika sumber data memang mengembalikan daftar kosong.
  /// Kegagalan diteruskan melalui Future sebagai error dan tidak boleh
  /// diganti dengan katalog kosong atau data contoh.
  Future<CustomerCatalog> getCatalog();
}
