import 'dart:typed_data';

import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';

abstract interface class CustomerRepository {
  Future<CustomerStallDetailBundle> fetchStallDetail(
    AuthSession session, {
    required String stallId,
  });

  Future<Uint8List?> fetchStallPhoto(
    AuthSession session, {
    required String stallId,
  });

  Future<CustomerMenuDetailBundle> fetchMenuDetail(
    AuthSession session, {
    required String menuId,
  });

  Future<Uint8List?> fetchMenuPhoto(
    AuthSession session, {
    required String menuId,
  });

  Future<CustomerCart> fetchCart(AuthSession session);

  Future<CustomerCart> addCartItem(
    AuthSession session, {
    required String menuId,
    int quantity = 1,
    String itemNote = '',
    bool replaceStall = false,
  });

  Future<CustomerCart> updateCartItem(
    AuthSession session, {
    required String itemId,
    required int quantity,
    String? itemNote,
  });

  Future<CustomerCart> deleteCartItem(
    AuthSession session, {
    required String itemId,
  });

  Future<CustomerCart> setCartGeneralNote(
    AuthSession session, {
    required String generalNote,
  });

  Future<CustomerCart> acknowledgeCartPrices(
    AuthSession session, {
    int? expectedVersion,
  });

  Future<CustomerCart> clearCart(AuthSession session);

  Future<CustomerCheckoutAttempt> createCheckoutAttempt(
    AuthSession session, {
    required int expectedVersion,
  });

  Future<CustomerAttemptLookupResult?> fetchOrderByAttempt(
    AuthSession session, {
    required String attemptId,
  });

  Future<CustomerCheckoutResult> checkout(
    AuthSession session, {
    required String attemptId,
    required int expectedVersion,
  });

  Future<({List<CustomerOrderSummary> items, bool hasMore})> listOrders(
    AuthSession session, {
    required bool activeOnly,
    int limit = 30,
    int offset = 0,
  });

  Future<CustomerOrderDetail> fetchOrderDetail(
    AuthSession session, {
    required String orderId,
  });

  Future<CustomerOrderDetail> cancelOrder(
    AuthSession session, {
    required String orderId,
  });

  Future<CustomerOwnerApplicationState> fetchOwnerApplicationState(
    AuthSession session,
  );

  Future<CustomerOwnerApplicationState> submitOwnerApplication(
    AuthSession session, {
    required String plannedStallName,
    required String plannedLocation,
    required String reason,
  });
}
