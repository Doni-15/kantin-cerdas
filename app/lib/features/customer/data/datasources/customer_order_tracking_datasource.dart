import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';

abstract interface class CustomerOrderTrackingDataSource {
  bool get isConfigured;
  bool get isCancellationConfigured;

  Future<OrderRecordPageModel> listMyOrders({
    required bool history,
    String? cursor,
    int limit = 30,
  });

  Future<OrderRecordModel?> getMyOrder({required String orderId});

  Future<OrderRecordModel> cancelMyOrder(
    CustomerOrderCancellation cancellation, {
    required String mutationId,
  });

  Future<OrderCancellationLookup> lookupCancellation({
    required String mutationId,
  });
}
