import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_detail_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_read_session.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';

/// ID stabil memungkinkan pembacaan ulang setelah restart tanpa objek extra.
/// Seluruh auth state diamati agar hasil sesi lama tidak ditampilkan di sesi baru.
final customerOrderDetailProvider = FutureProvider.autoDispose
    .family<OrderRecord?, String>((ref, orderId) async {
      ref.watch(sharedDataRevisionProvider);
      final session = CustomerReadSession(ref);
      if (orderId.trim().isEmpty) {
        throw const CustomerOrderDetailInvalidReferenceFailure();
      }
      final repository = ref.watch(customerOrderTrackingRepositoryProvider);
      final OrderRecord? order;
      try {
        order = await repository
            .getMyOrder(orderId: orderId)
            .timeout(const Duration(seconds: 30));
      } on TimeoutException {
        throw const CustomerOrderDetailTimeoutFailure();
      }
      session.check(ref);
      if (order != null) {
        if (order.customerId != session.customerId) {
          throw const CustomerFeatureForbiddenFailure();
        }
        if (order.id != orderId ||
            !OrderRecordRules.hasConsistentSnapshot(order)) {
          throw const CustomerOrderDetailInvalidDataFailure();
        }
      }
      return order;
    }, retry: (_, _) => null);
