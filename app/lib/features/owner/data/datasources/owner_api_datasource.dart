import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_datasource.dart';
import 'package:kantin_cerdas/features/owner/data/models/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';

final class OwnerApiDataSource implements OwnerDataSource {
  const OwnerApiDataSource({this.dio});

  final Dio? dio;

  @override
  bool get isMutationConfigured =>
      dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<OwnerStallModel?> getMyStall() async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>('/v1/owner/stall');
      return OwnerStallModel.fromJson(
        asJsonMap(response.data, fieldName: 'stall'),
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
  Future<OwnerMenuPageModel> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/owner/menus',
        queryParameters: <String, Object?>{
          'stall_id': stallId,
          'search': search,
          'available': ?available,
          'cursor': ?cursor,
          'limit': limit,
        },
      );
      return OwnerMenuPageModel.fromJson(
        asJsonMap(response.data, fieldName: 'menus'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<OwnerMenuModel> saveMenu(
    OwnerMenuInput input, {
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    final payload = <String, Object?>{
      'mutation_id': mutationId,
      'id': input.id,
      'stall_id': input.stallId,
      'name': input.name,
      'description': input.description,
      'category': input.category.name,
      'price_idr': input.priceIdr,
      'is_available': input.isAvailable,
      'expected_version': input.expectedVersion,
      'image_url': input.imageUrl,
    };
    final options = Options(
      headers: <String, Object?>{'Idempotency-Key': mutationId},
    );
    try {
      final response = input.id == null
          ? await client.post<Object?>(
              '/v1/owner/menus',
              data: payload,
              options: options,
            )
          : await client.put<Object?>(
              '/v1/owner/menus/${Uri.encodeComponent(input.id!)}',
              data: payload,
              options: options,
            );
      return OwnerMenuModel.fromJson(
        asJsonMap(response.data, fieldName: 'menu'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> deleteMenu({
    required String id,
    required int expectedVersion,
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      await client.delete<Object?>(
        '/v1/owner/menus/${Uri.encodeComponent(id)}',
        queryParameters: <String, Object?>{'expected_version': expectedVersion},
        data: <String, Object?>{
          'mutation_id': mutationId,
          'expected_version': expectedVersion,
        },
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': mutationId},
        ),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<OwnerStallModel> saveStall(
    OwnerStallInput input, {
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final response = await client.put<Object?>(
        '/v1/owner/stall',
        data: <String, Object?>{
          'id': input.id,
          'mutation_id': mutationId,
          'name': input.name,
          'block': input.block,
          'description': input.description,
          'is_open': input.isOpen,
          'prep_time_min': input.prepTimeMin,
          'expected_version': input.expectedVersion,
          'image_url': input.imageUrl,
        },
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': mutationId},
        ),
      );
      return OwnerStallModel.fromJson(
        asJsonMap(response.data, fieldName: 'stall'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<OrderRecordPageModel> listOrders({
    required String stallId,
    OrderStatus? status,
    String? cursor,
    int limit = 30,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/owner/orders',
        queryParameters: <String, Object?>{
          'stall_id': stallId,
          if (status != null) 'status': status.name,
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
  Future<OrderRecordModel?> getMyOrder({
    required String stallId,
    required String orderId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/owner/orders/${Uri.encodeComponent(orderId)}',
        queryParameters: <String, Object?>{'stall_id': stallId},
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
  Future<OrderRecordModel> transitionOrder(
    OwnerOrderTransition input, {
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/owner/orders/${Uri.encodeComponent(input.orderId)}/transition',
        data: <String, Object?>{
          'mutation_id': mutationId,
          'status': input.status.name,
          'expected_version': input.expectedVersion,
          'reason': input.reason,
          'cash_received': input.cashReceived,
          'food_handed_over': input.foodHandedOver,
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
  Future<OwnerMutationLookup> lookupMutation({
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/operations/owner-mutations/${Uri.encodeComponent(mutationId)}',
      );
      return OwnerMutationLookupModel.fromJson(
        asJsonMap(response.data, fieldName: 'owner_mutation_lookup'),
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
