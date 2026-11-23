abstract interface class CustomerStore {
  Future<Map<String, Object?>?> getStallDetail(String stallId);
  Future<Map<String, Object?>?> getMenuDetail(String menuId);
  Future<String?> getStallPhotoPath(String stallId);
  Future<String?> getMenuPhotoPath(String menuId);
  Future<Map<String, Object?>> getCart(String customerId);

  Future<Map<String, Object?>> addCartItem(
    String customerId, {
    required String menuId,
    required int quantity,
    required String itemNote,
    required bool replaceStall,
  });

  Future<Map<String, Object?>> updateCartItem(
    String customerId, {
    required String itemId,
    required int quantity,
    String? itemNote,
  });

  Future<Map<String, Object?>> setCartNote(
    String customerId, {
    required String generalNote,
  });

  Future<Map<String, Object?>> acknowledgeCartPrices(
    String customerId, {
    int? expectedVersion,
  });

  Future<Map<String, Object?>> clearCart(String customerId);

  Future<Map<String, Object?>> createCheckoutAttempt(
    String customerId, {
    required int expectedVersion,
  });

  Future<Map<String, Object?>?> getOrderByAttempt(
    String customerId, {
    required String attemptId,
  });

  Future<Map<String, Object?>> checkout(
    String customerId, {
    required String customerName,
    required String attemptId,
    required int expectedVersion,
  });

  Future<Map<String, Object?>> listOrders(
    String customerId, {
    required String scope,
    required int limit,
    required int offset,
  });

  Future<Map<String, Object?>?> getOrder(
    String customerId, {
    required String orderId,
  });

  Future<Map<String, Object?>> cancelOrder(
    String customerId, {
    required String orderId,
  });

  Future<Map<String, Object?>> getOwnerApplicationState(String customerId);

  Future<Map<String, Object?>> submitOwnerApplication(
    String customerId, {
    required String plannedStallName,
    required String plannedLocation,
    required String reason,
  });

  Future<Map<String, Object?>> getAdminActiveOrderIndicator(String userId);
}
