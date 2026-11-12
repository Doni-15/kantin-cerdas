import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_tracking_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_order_models.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';

final class CustomerOrderTrackingApiDataSource
    implements CustomerOrderTrackingDataSource {
  const CustomerOrderTrackingApiDataSource({this.dio});

  final Dio? dio;

  @override
  bool get isConfigured => dio != null && AppEnvironment.isApiConfigured;

  @override
  bool get isCancellationConfigured => isConfigured;

  @override
  Future<OrderRecordPageModel> listMyOrders({
    required bool history,
    String? cursor,
    int limit = 30,
  }) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const CustomerFeatureNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/customer/orders',
        queryParameters: <String, Object?>{
          'history': history,
          'cursor': ?cursor,
          'limit': limit,
        },
      );
      return OrderRecordPageModel.fromJson(
        asJsonMap(response.data, fieldName: 'orders'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<OrderRecordModel?> getMyOrder({required String orderId}) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const CustomerFeatureNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/customer/orders/${Uri.encodeComponent(orderId)}',
      );
      return OrderRecordModel.fromJson(
        asJsonMap(response.data, fieldName: 'order'),
      );
    } on DioException catch (error) {
      final apiErr = mapDioException(error);
      if (apiErr.statusCode == 404 && apiErr.hasBackendErrorCode) {
        return null;
      }
      throw apiErr;
    }
  }

  @override
  Future<OrderRecordModel> cancelMyOrder(
    CustomerOrderCancellation cancellation, {
    required String mutationId,
  }) async {
    final client = dio;
    if (!isCancellationConfigured || client == null) {
      throw const CustomerOrderCancellationNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/customer/orders/${Uri.encodeComponent(cancellation.orderId)}/cancel',
        data: <String, Object?>{
          'mutation_id': mutationId,
          'expected_version': cancellation.expectedVersion,
        },
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': mutationId},
        ),
      );
      return OrderRecordModel.fromJson(
        asJsonMap(response.data, fieldName: 'order'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<OrderCancellationLookup> lookupCancellation({
    required String mutationId,
  }) async {
    final client = dio;
    if (!isCancellationConfigured || client == null) {
      throw const CustomerOrderCancellationNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/operations/order-cancellations/${Uri.encodeComponent(mutationId)}',
      );
      return OrderCancellationLookupModel.fromJson(
        asJsonMap(response.data, fieldName: 'order_cancellation_lookup'),
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
