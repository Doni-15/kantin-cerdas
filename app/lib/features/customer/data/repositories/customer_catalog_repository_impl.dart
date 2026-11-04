import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_catalog_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_catalog_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_catalog_repository.dart';

/// Menghubungkan sumber data katalog dengan kontrak domain.
final class CustomerCatalogRepositoryImpl implements CustomerCatalogRepository {
  const CustomerCatalogRepositoryImpl({required this._dataSource});

  final CustomerCatalogDataSource _dataSource;

  @override
  Future<CustomerCatalog> getCatalog() async {
    try {
      final model = await _dataSource.getCatalog();
      return model.toEntity();
    } on CustomerCatalogFailure {
      rethrow;
    } on ApiException catch (exception) {
      throw mapCustomerCatalogApiException(exception);
    } catch (_) {
      throw const CustomerCatalogUnexpectedFailure();
    }
  }
}
