import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_order_detail_failure.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_read_session.dart';

final ownerOrderDetailProvider = FutureProvider.autoDispose
    .family<OrderRecord?, String>((ref, orderId) async {
      ref.watch(sharedDataRevisionProvider);
      final session = OwnerReadSession(ref);
      if (orderId.trim().isEmpty) {
        throw const OwnerOrderDetailInvalidReferenceFailure();
      }
      final repository = ref.watch(ownerRepositoryProvider);
      final stallFuture = ref.watch(ownerStallProvider.future);

      try {
        final stall = await stallFuture.timeout(const Duration(seconds: 30));
        session.check(ref);
        if (stall == null) {
          throw const OwnerNoStallFailure();
        }
        if (stall.ownerId != session.ownerId) {
          throw const OwnerForbiddenFailure();
        }
        final order = await repository
            .getMyOrder(stallId: stall.id, orderId: orderId)
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (order != null) {
          if (order.stallId != stall.id) {
            throw const OwnerForbiddenFailure();
          }
          if (order.id != orderId ||
              !OrderRecordRules.hasConsistentSnapshot(order)) {
            throw const OwnerOrderDetailInvalidDataFailure();
          }
        }
        return order;
      } on TimeoutException {
        throw const OwnerOrderDetailTimeoutFailure();
      }
    }, retry: (_, _) => null);
