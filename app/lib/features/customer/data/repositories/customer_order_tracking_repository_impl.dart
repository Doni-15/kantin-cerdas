import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/pagination_validator.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_tracking_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_order_tracking_repository.dart';
import 'package:kantin_cerdas/features/orders/data/mappers/order_record_mapper.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

final class CustomerOrderTrackingRepositoryImpl
    implements CustomerOrderTrackingRepository {
  const CustomerOrderTrackingRepositoryImpl({required this._dataSource});

  final CustomerOrderTrackingDataSource _dataSource;

  @override
  bool get isCancellationConfigured => _dataSource.isCancellationConfigured;

  @override
  Future<OrderRecordPage> listMyOrders({
    required bool history,
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final page = await _dataSource.listMyOrders(
        history: history,
        cursor: cursor,
        limit: limit,
      );
      final entity = page.toEntity();
      validateCursorPageBounds(
        limit: limit,
        requestCursor: cursor,
        itemCount: entity.items.length,
        nextCursor: entity.nextCursor,
      );
      return entity;
    } on CustomerFeatureFailure {
      rethrow;
    } on DataParsingException {
      throw const CustomerFeatureInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapCustomerReadApiException(e);
    } catch (_) {
      throw const CustomerFeatureInvalidDataFailure();
    }
  }

  @override
  Future<OrderRecord?> getMyOrder({required String orderId}) async {
    try {
      final model = await _dataSource.getMyOrder(orderId: orderId);
      return model?.toEntity();
    } on CustomerFeatureFailure {
      rethrow;
    } on DataParsingException {
      throw const CustomerFeatureInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapCustomerReadApiException(e);
    } catch (_) {
      throw const CustomerFeatureInvalidDataFailure();
    }
  }

  @override
  Future<OrderRecord> cancelMyOrder(
    CustomerOrderCancellation cancellation, {
    required String mutationId,
  }) async {
    if (!isCancellationConfigured) {
      throw const CustomerOrderCancellationNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.cancelMyOrder(
        cancellation,
        mutationId: mutationId,
      );
      return model.toEntity();
    } on CustomerOrderCancellationFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapCustomerOrderCancellationApiException(e);
    } catch (_) {
      throw const CustomerOrderCancellationUnknownFailure();
    }
  }

  @override
  Future<OrderCancellationLookup> lookupCancellation({
    required String mutationId,
  }) async {
    if (!isCancellationConfigured) {
      throw const CustomerOrderCancellationNotConfiguredFailure();
    }
    if (mutationId.trim().isEmpty) {
      throw const CustomerOrderCancellationUnknownFailure();
    }
    try {
      final result = await _dataSource.lookupCancellation(
        mutationId: mutationId,
      );
      if (result.request.mutationId != mutationId) {
        throw const CustomerOrderCancellationUnknownFailure();
      }
      return result;
    } on CustomerOrderCancellationFailure {
      rethrow;
    } catch (_) {
      throw const CustomerOrderCancellationUnknownFailure();
    }
  }
}
