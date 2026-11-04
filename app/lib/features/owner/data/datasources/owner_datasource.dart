import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/data/models/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';

abstract interface class OwnerDataSource {
  bool get isMutationConfigured;
  Future<OwnerStallModel?> getMyStall();
  Future<OwnerMenuPageModel> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  });
  Future<OwnerMenuModel> saveMenu(
    OwnerMenuInput input, {
    required String mutationId,
  });
  Future<void> deleteMenu({
    required String id,
    required int expectedVersion,
    required String mutationId,
  });
  Future<OwnerStallModel> saveStall(
    OwnerStallInput input, {
    required String mutationId,
  });
  Future<OrderRecordPageModel> listOrders({
    required String stallId,
    OrderStatus? status,
    String? cursor,
    int limit = 30,
  });
  Future<OrderRecordModel?> getMyOrder({
    required String stallId,
    required String orderId,
  });
  Future<OrderRecordModel> transitionOrder(
    OwnerOrderTransition input, {
    required String mutationId,
  });
  Future<OwnerMutationLookup> lookupMutation({required String mutationId});
}
