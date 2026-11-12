import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_read_session.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show
        canteenApplicationRepositoryProvider,
        customerAssistantRepositoryProvider,
        customerOrderTrackingRepositoryProvider;

typedef CustomerOrderQuery = ({bool history, String? cursor});
final customerOrderFeedProvider = FutureProvider.autoDispose
    .family<OrderRecordPage, CustomerOrderQuery>((ref, query) async {
      ref.watch(sharedDataRevisionProvider);
      final session = CustomerReadSession(ref);
      final repository = ref.watch(customerOrderTrackingRepositoryProvider);
      final cursor = query.cursor;
      if (cursor != null && cursor.trim().isEmpty) {
        throw const CustomerFeatureInvalidDataFailure();
      }
      try {
        final page = await repository
            .listMyOrders(
              history: query.history,
              cursor: query.cursor,
              limit: 30,
            )
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (page.items.length > 30 ||
            page.items.map((order) => order.id).toSet().length !=
                page.items.length ||
            (page.nextCursor != null && page.nextCursor == query.cursor) ||
            page.items.any(
              (order) =>
                  order.customerId != session.customerId ||
                  order.status.isTerminal != query.history ||
                  !OrderRecordRules.hasConsistentSnapshot(order),
            )) {
          throw const CustomerFeatureInvalidDataFailure();
        }
        return page;
      } on TimeoutException {
        throw const CustomerFeatureReadTimeoutFailure();
      }
    }, retry: (_, _) => null);

final canteenApplicationProvider =
    FutureProvider.autoDispose<CanteenApplication?>((ref) async {
      ref.watch(sharedDataRevisionProvider);
      final session = CustomerReadSession(ref);
      final repository = ref.watch(canteenApplicationRepositoryProvider);
      try {
        final application = await repository.getMyApplication().timeout(
          const Duration(seconds: 30),
        );
        session.check(ref);
        if (application != null &&
            application.applicantId != session.customerId) {
          throw const CustomerFeatureForbiddenFailure();
        }
        return application;
      } on TimeoutException {
        throw const CustomerFeatureReadTimeoutFailure();
      }
    }, retry: (_, _) => null);
