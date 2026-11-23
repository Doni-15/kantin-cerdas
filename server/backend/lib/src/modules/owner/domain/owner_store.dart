import 'dart:typed_data';

typedef OwnerScheduleInput = ({
  int dayOfWeek,
  bool isOpenDay,
  String? openTime,
  String? closeTime,
});

abstract interface class OwnerStore {
  Future<Map<String, Object?>> getStall(String ownerId);

  Future<Map<String, Object?>> createStall(
    String ownerId, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  });

  Future<Map<String, Object?>> updateStall(
    String ownerId, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  });

  Future<Map<String, Object?>> setStallPhoto(
    String ownerId, {
    required String? photoPath,
  });

  Future<Map<String, Object?>> setStallSchedule(
    String ownerId,
    List<OwnerScheduleInput> schedules,
  );

  Future<Map<String, Object?>> publishStall(String ownerId);

  Future<Map<String, Object?>> setStallOpen(
    String ownerId, {
    required bool isOpen,
  });

  Future<List<Map<String, Object?>>> listCategories(String ownerId);

  Future<Map<String, Object?>> createCategory(
    String ownerId, {
    required String name,
  });

  Future<Map<String, Object?>> renameCategory(
    String ownerId, {
    required String categoryId,
    required String name,
  });

  Future<void> deleteCategory(String ownerId, {required String categoryId});

  Future<List<Map<String, Object?>>> listMenus(
    String ownerId, {
    bool? archived,
    required String query,
  });

  Future<Map<String, Object?>> createMenu(
    String ownerId, {
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  });

  Future<Map<String, Object?>> updateMenu(
    String ownerId, {
    required String menuId,
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  });

  Future<Map<String, Object?>> setMenuAvailability(
    String ownerId, {
    required String menuId,
    required bool isAvailable,
  });

  Future<Map<String, Object?>> archiveMenu(
    String ownerId, {
    required String menuId,
  });

  Future<Map<String, Object?>> restoreMenu(
    String ownerId, {
    required String menuId,
  });

  Future<Map<String, Object?>> setMenuPhoto(
    String ownerId, {
    required String menuId,
    required String? photoPath,
  });

  Future<Map<String, Object?>> getDashboard(String ownerId);

  Future<Map<String, Object?>> listOrders(
    String ownerId, {
    required String scope,
    String? status,
    required String query,
    required int limit,
    required int offset,
  });

  Future<Map<String, Object?>?> lookupOrder(
    String ownerId, {
    required String orderNumber,
  });

  Future<Map<String, Object?>?> getOrder(
    String ownerId, {
    required String orderId,
  });

  Future<Map<String, Object?>> transitionOrder(
    String ownerId, {
    required String orderId,
    required String action,
    String? reason,
    bool cashReceived = false,
    bool foodHandedOver = false,
  });
}

abstract interface class OwnerMediaStore {
  Future<Uint8List?> read(String objectPath);

  Future<void> write(String objectPath, Uint8List jpegBytes);

  Future<void> delete(String objectPath);
}
