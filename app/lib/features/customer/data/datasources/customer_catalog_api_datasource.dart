import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_catalog_model.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';

/// Sumber data HTTP untuk katalog pelanggan.
final class CustomerCatalogApiDataSource implements CustomerCatalogDataSource {
  const CustomerCatalogApiDataSource({this.dio});

  final Dio? dio;

  bool get isConfigured => dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<CustomerCatalogModel> getCatalog() async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const CustomerCatalogNotConfiguredFailure();
    }

    try {
      final response = await client.get<Object?>('/v1/catalog');
      return CustomerCatalogModel.fromJson(
        asJsonMap(response.data, fieldName: 'catalog'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
