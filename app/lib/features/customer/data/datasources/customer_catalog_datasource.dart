import 'package:kantin_cerdas/features/customer/data/models/customer_catalog_model.dart';

/// Kontrak sumber data katalog pelanggan.
abstract interface class CustomerCatalogDataSource {
  /// Mengembalikan model katalog setelah pembacaan dan parsing berhasil.
  ///
  /// Implementasi menormalisasi kegagalan transport atau HTTP menjadi
  /// ApiException, serta respons yang tidak valid menjadi
  /// DataParsingException.
  ///
  /// Kegagalan harus diteruskan sebagai error. Daftar kosong hanya sah
  /// ketika memang diberikan oleh sumber data yang berhasil dibaca.
  Future<CustomerCatalogModel> getCatalog();
}
