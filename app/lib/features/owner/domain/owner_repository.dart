import 'dart:typed_data';

import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';

abstract interface class OwnerRepository {
  Future<OwnerDashboard> fetchDashboard(AuthSession session);

  Future<OwnerStallBundle> fetchStall(AuthSession session);

  Future<OwnerStallBundle> createStall(
    AuthSession session, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  });

  Future<OwnerStallBundle> updateStall(
    AuthSession session, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  });

  Future<Uint8List?> fetchStallPhoto(AuthSession session);

  Future<Uint8List> uploadStallPhoto(
    AuthSession session, {
    required Uint8List bytes,
    required String mediaType,
  });

  Future<OwnerStallBundle> removeStallPhoto(AuthSession session);

  Future<OwnerStallBundle> updateSchedule(
    AuthSession session,
    List<OwnerScheduleDay> schedules,
  );

  Future<OwnerStallBundle> publishStall(AuthSession session);

  Future<OwnerStallBundle> setStallOpen(
    AuthSession session, {
    required bool isOpen,
  });

  Future<List<OwnerCategory>> listCategories(AuthSession session);

  Future<OwnerCategory> createCategory(
    AuthSession session, {
    required String name,
  });

  Future<OwnerCategory> renameCategory(
    AuthSession session, {
    required String categoryId,
    required String name,
  });

  Future<void> deleteCategory(
    AuthSession session, {
    required String categoryId,
  });

  Future<List<OwnerMenuItem>> listMenus(
    AuthSession session, {
    bool? archived,
    String query = '',
  });

  Future<OwnerMenuItem> createMenu(
    AuthSession session, {
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  });

  Future<OwnerMenuItem> updateMenu(
    AuthSession session, {
    required String menuId,
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  });

  Future<OwnerMenuItem> setMenuAvailability(
    AuthSession session, {
    required String menuId,
    required bool isAvailable,
  });

  Future<OwnerMenuItem> archiveMenu(
    AuthSession session, {
    required String menuId,
  });

  Future<OwnerMenuItem> restoreMenu(
    AuthSession session, {
    required String menuId,
  });

  Future<Uint8List?> fetchMenuPhoto(
    AuthSession session, {
    required String menuId,
  });

  Future<Uint8List> uploadMenuPhoto(
    AuthSession session, {
    required String menuId,
    required Uint8List bytes,
    required String mediaType,
  });

  Future<OwnerMenuItem> removeMenuPhoto(
    AuthSession session, {
    required String menuId,
  });

  Future<List<OwnerOrderSummary>> listOrders(
    AuthSession session, {
    required bool activeOnly,
    OwnerOrderStatus? status,
    String query = '',
  });

  Future<OwnerOrderDetail> lookupOrder(
    AuthSession session, {
    required String orderNumber,
  });

  Future<OwnerOrderDetail> fetchOrderDetail(
    AuthSession session, {
    required String orderId,
  });

  Future<OwnerOrderDetail> acceptOrder(
    AuthSession session, {
    required String orderId,
  });

  Future<OwnerOrderDetail> rejectOrder(
    AuthSession session, {
    required String orderId,
    required String reason,
  });

  Future<OwnerOrderDetail> markOrderReady(
    AuthSession session, {
    required String orderId,
  });

  Future<OwnerOrderDetail> failOrderFulfillment(
    AuthSession session, {
    required String orderId,
    required String reason,
  });

  Future<OwnerOrderDetail> completeOrder(
    AuthSession session, {
    required String orderId,
    required bool cashReceived,
    required bool foodHandedOver,
  });

  Future<OwnerOrderDetail> markOrderNotPickedUp(
    AuthSession session, {
    required String orderId,
  });

  Future<OwnerOrderDetail> failOrderPickup(
    AuthSession session, {
    required String orderId,
    required String reason,
  });
}
