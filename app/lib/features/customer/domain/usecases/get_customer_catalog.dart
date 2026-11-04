import 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_catalog_repository.dart';

/// Membaca katalog pelanggan melalui kontrak repository.
class GetCustomerCatalog {
  const GetCustomerCatalog(this._repository);

  final CustomerCatalogRepository _repository;

  /// Meneruskan hasil dan kegagalan pemuatan kepada pemanggil.
  Future<CustomerCatalog> execute() {
    return _repository.getCatalog();
  }
}
