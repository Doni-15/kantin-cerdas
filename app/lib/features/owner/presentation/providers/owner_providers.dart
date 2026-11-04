import 'dart:async';

import 'package:characters/characters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/domain/providers/owner_domain_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_read_session.dart';

export 'package:kantin_cerdas/features/owner/domain/providers/owner_domain_providers.dart'
    show ownerRepositoryProvider;

final ownerStallProvider = FutureProvider.autoDispose<OwnerStall?>((ref) async {
  ref.watch(sharedDataRevisionProvider);
  final session = OwnerReadSession(ref);
  final repository = ref.watch(ownerRepositoryProvider);
  try {
    final stall = await repository.getMyStall().timeout(
      const Duration(seconds: 30),
    );
    session.check(ref);
    if (stall != null && stall.ownerId != session.ownerId) {
      throw const OwnerForbiddenFailure();
    }
    return stall;
  } on TimeoutException {
    throw const OwnerReadTimeoutFailure();
  }
}, retry: (_, _) => null);

typedef OwnerMenuQuery = ({String search, bool? available, String? cursor});
final ownerMenusProvider = FutureProvider.autoDispose
    .family<OwnerMenuPage, OwnerMenuQuery>((ref, query) async {
      ref.watch(sharedDataRevisionProvider);
      final session = OwnerReadSession(ref);
      if (query.cursor != null && query.cursor!.trim().isEmpty) {
        throw const OwnerInvalidDataFailure();
      }
      final repository = ref.watch(ownerRepositoryProvider);
      final stallFuture = ref.watch(ownerStallProvider.future);
      if (query.search.characters.length > 120) {
        throw const OwnerInvalidDataFailure();
      }
      try {
        final stall = await stallFuture.timeout(const Duration(seconds: 30));
        session.check(ref);
        if (stall == null) {
          throw const OwnerNoStallFailure();
        }
        final page = await repository
            .listMenus(
              stallId: stall.id,
              search: query.search,
              available: query.available,
              cursor: query.cursor,
              limit: 30,
            )
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (page.items.length > 30 ||
            (page.nextCursor != null && page.nextCursor == query.cursor) ||
            page.items.any(
              (item) =>
                  item.stallId != stall.id ||
                  (query.available != null &&
                      item.isAvailable != query.available),
            )) {
          throw const OwnerInvalidDataFailure();
        }
        return page;
      } on TimeoutException {
        throw const OwnerReadTimeoutFailure();
      }
    }, retry: (_, _) => null);

typedef OwnerOrderQuery = ({OrderStatus? status, String? cursor, int limit});
final ownerOrdersProvider = FutureProvider.autoDispose
    .family<OrderRecordPage, OwnerOrderQuery>((ref, query) async {
      ref.watch(sharedDataRevisionProvider);
      final session = OwnerReadSession(ref);
      if (query.cursor != null && query.cursor!.trim().isEmpty) {
        throw const OwnerInvalidDataFailure();
      }
      final repository = ref.watch(ownerRepositoryProvider);
      final stallFuture = ref.watch(ownerStallProvider.future);
      if (query.limit < 1 || query.limit > 100) {
        throw const OwnerInvalidDataFailure();
      }
      try {
        final stall = await stallFuture.timeout(const Duration(seconds: 30));
        session.check(ref);
        if (stall == null) {
          throw const OwnerNoStallFailure();
        }
        final page = await repository
            .listOrders(
              stallId: stall.id,
              status: query.status,
              cursor: query.cursor,
              limit: query.limit,
            )
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (page.items.length > query.limit ||
            page.items.map((order) => order.id).toSet().length !=
                page.items.length ||
            (page.nextCursor != null && page.nextCursor == query.cursor) ||
            page.items.any(
              (order) =>
                  order.stallId != stall.id ||
                  !OrderRecordRules.hasConsistentSnapshot(order) ||
                  (query.status != null && order.status != query.status),
            )) {
          throw const OwnerInvalidDataFailure();
        }
        return page;
      } on TimeoutException {
        throw const OwnerReadTimeoutFailure();
      }
    }, retry: (_, _) => null);
