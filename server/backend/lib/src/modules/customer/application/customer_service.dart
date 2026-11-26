import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';

typedef CustomerMediaReader = Future<Uint8List?> Function(String objectPath);

class CustomerService {
  const CustomerService({required this.store, required this.readMedia});

  final CustomerStore store;
  final CustomerMediaReader readMedia;

  Future<Map<String, Object?>> getStallDetail(String stallId) async {
    final detail = await store.getStallDetail(stallId);
    if (detail == null) {
      throw const CustomerFailure(CustomerFailureCode.stallNotFound);
    }
    return detail;
  }

  Future<Map<String, Object?>> getMenuDetail(String menuId) async {
    final detail = await store.getMenuDetail(menuId);
    if (detail == null) {
      throw const CustomerFailure(CustomerFailureCode.menuNotFound);
    }
    return detail;
  }

  Future<Uint8List?> readStallPhoto(String stallId) async {
    final path = await store.getStallPhotoPath(stallId);
    if (path == null || path.trim().isEmpty) return null;
    return readMedia(path);
  }

  Future<Uint8List?> readMenuPhoto(String menuId) async {
    final path = await store.getMenuPhotoPath(menuId);
    if (path == null || path.trim().isEmpty) return null;
    return readMedia(path);
  }

  Future<Map<String, Object?>> getCart(String customerId) =>
      store.getCart(customerId);

  Future<Map<String, Object?>> addCartItem(
    String customerId, {
    required String menuId,
    required int quantity,
    required String itemNote,
    required bool replaceStall,
  }) => store.addCartItem(
    customerId,
    menuId: menuId,
    quantity: quantity,
    itemNote: itemNote,
    replaceStall: replaceStall,
  );

  Future<Map<String, Object?>> updateCartItem(
    String customerId, {
    required String itemId,
    required int quantity,
    String? itemNote,
  }) => store.updateCartItem(
    customerId,
    itemId: itemId,
    quantity: quantity,
    itemNote: itemNote,
  );

  Future<Map<String, Object?>> setCartNote(
    String customerId, {
    required String generalNote,
  }) => store.setCartNote(customerId, generalNote: generalNote);

  Future<Map<String, Object?>> acknowledgeCartPrices(
    String customerId, {
    int? expectedVersion,
  }) => store.acknowledgeCartPrices(
    customerId,
    expectedVersion: expectedVersion,
  );

  Future<Map<String, Object?>> clearCart(String customerId) =>
      store.clearCart(customerId);

  Future<Map<String, Object?>> createCheckoutAttempt(
    String customerId, {
    required int expectedVersion,
  }) => store.createCheckoutAttempt(
    customerId,
    expectedVersion: expectedVersion,
  );

  Future<Map<String, Object?>?> getOrderByAttempt(
    String customerId, {
    required String attemptId,
  }) => store.getOrderByAttempt(customerId, attemptId: attemptId);

  Future<Map<String, Object?>> checkout(
    String customerId, {
    required String customerName,
    required String attemptId,
    required int expectedVersion,
  }) => store.checkout(
    customerId,
    customerName: customerName,
    attemptId: attemptId,
    expectedVersion: expectedVersion,
  );

  Future<Map<String, Object?>> listOrders(
    String customerId, {
    required String scope,
    required int limit,
    required int offset,
  }) => store.listOrders(
    customerId,
    scope: scope,
    limit: limit,
    offset: offset,
  );

  Future<Map<String, Object?>> getOrder(
    String customerId, {
    required String orderId,
  }) async {
    final order = await store.getOrder(customerId, orderId: orderId);
    if (order == null) {
      throw const CustomerFailure(CustomerFailureCode.orderNotFound);
    }
    return order;
  }

  Future<Map<String, Object?>> cancelOrder(
    String customerId, {
    required String orderId,
  }) => store.cancelOrder(customerId, orderId: orderId);

  Future<Map<String, Object?>> getOwnerApplicationState(String customerId) =>
      store.getOwnerApplicationState(customerId);

  Future<Map<String, Object?>> submitOwnerApplication(
    String customerId, {
    required String plannedStallName,
    required String plannedLocation,
    required String reason,
  }) => store.submitOwnerApplication(
    customerId,
    plannedStallName: plannedStallName,
    plannedLocation: plannedLocation,
    reason: reason,
  );

  Future<Map<String, Object?>> getAdminActiveOrderIndicator(String userId) =>
      store.getAdminActiveOrderIndicator(userId);
}
