import 'dart:typed_data';

import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/owner/data/owner_error_mapper.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_repository.dart';

class OwnerApiRepository implements OwnerRepository {
  const OwnerApiRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<OwnerDashboard> fetchDashboard(AuthSession session) async {
    final data = await _send(session, 'GET', ['owner', 'dashboard']);
    return _decode(() => OwnerDashboard.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<OwnerStallBundle> fetchStall(AuthSession session) async {
    final data = await _send(session, 'GET', ['owner', 'stall']);
    return _decode(
      () => OwnerStallBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerStallBundle> createStall(
    AuthSession session, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['owner', 'stall'],
      body: {
        'name': name,
        'campus': campus,
        'block': block,
        'description': description,
        'wait_minutes': waitMinutes,
      },
    );
    return _decode(
      () => OwnerStallBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerStallBundle> updateStall(
    AuthSession session, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  }) async {
    final data = await _send(
      session,
      'PUT',
      ['owner', 'stall'],
      body: {
        'name': name,
        'campus': campus,
        'block': block,
        'description': description,
        'wait_minutes': waitMinutes,
      },
    );
    return _decode(
      () => OwnerStallBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Uint8List?> fetchStallPhoto(AuthSession session) =>
      _auth.sendAuthenticatedMedia(session, 'GET', [
        'owner',
        'stall',
        'photo',
      ], onEnvelopeError: mapOwnerEnvelopeError);

  @override
  Future<Uint8List> uploadStallPhoto(
    AuthSession session, {
    required Uint8List bytes,
    required String mediaType,
  }) async {
    final result = await _auth.sendAuthenticatedMedia(
      session,
      'PUT',
      ['owner', 'stall', 'photo'],
      bytes: bytes,
      mediaType: mediaType,
      onEnvelopeError: mapOwnerEnvelopeError,
    );
    if (result == null) throw authBadResponseException;
    return result;
  }

  @override
  Future<OwnerStallBundle> removeStallPhoto(AuthSession session) async {
    final data = await _send(session, 'DELETE', ['owner', 'stall', 'photo']);
    return _decode(
      () => OwnerStallBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerStallBundle> updateSchedule(
    AuthSession session,
    List<OwnerScheduleDay> schedules,
  ) async {
    final data = await _send(
      session,
      'PUT',
      ['owner', 'stall', 'schedule'],
      body: {
        'schedules': [for (final day in schedules) day.toJson()],
      },
    );
    return _decode(
      () => OwnerStallBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerStallBundle> publishStall(AuthSession session) async {
    final data = await _send(session, 'POST', ['owner', 'stall', 'publish']);
    return _decode(
      () => OwnerStallBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerStallBundle> setStallOpen(
    AuthSession session, {
    required bool isOpen,
  }) async {
    final data = await _send(
      session,
      'PUT',
      ['owner', 'stall', 'open-status'],
      body: {'is_open': isOpen},
    );
    return _decode(
      () => OwnerStallBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<List<OwnerCategory>> listCategories(AuthSession session) async {
    final data = await _send(session, 'GET', ['owner', 'categories']);
    return _decode(() {
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>;
      return List<OwnerCategory>.unmodifiable([
        for (final item in items)
          OwnerCategory.fromJson(item as Map<String, dynamic>),
      ]);
    });
  }

  @override
  Future<OwnerCategory> createCategory(
    AuthSession session, {
    required String name,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['owner', 'categories'],
      body: {'name': name},
    );
    return _decode(() => OwnerCategory.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<OwnerCategory> renameCategory(
    AuthSession session, {
    required String categoryId,
    required String name,
  }) async {
    final data = await _send(
      session,
      'PUT',
      ['owner', 'categories', categoryId],
      body: {'name': name},
    );
    return _decode(() => OwnerCategory.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<void> deleteCategory(
    AuthSession session, {
    required String categoryId,
  }) async {
    await _send(session, 'DELETE', ['owner', 'categories', categoryId]);
  }

  @override
  Future<List<OwnerMenuItem>> listMenus(
    AuthSession session, {
    bool? archived,
    String query = '',
  }) async {
    final data = await _send(
      session,
      'GET',
      ['owner', 'menus'],
      query: {
        if (archived != null) 'archived': '$archived',
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return _decode(() {
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>;
      return List<OwnerMenuItem>.unmodifiable([
        for (final item in items)
          OwnerMenuItem.fromJson(item as Map<String, dynamic>),
      ]);
    });
  }

  @override
  Future<OwnerMenuItem> createMenu(
    AuthSession session, {
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['owner', 'menus'],
      body: {
        'name': name,
        'category_id': categoryId,
        'price': price,
        'is_available': isAvailable,
        'description': description,
      },
    );
    return _decode(() => OwnerMenuItem.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<OwnerMenuItem> updateMenu(
    AuthSession session, {
    required String menuId,
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  }) async {
    final data = await _send(
      session,
      'PUT',
      ['owner', 'menus', menuId],
      body: {
        'name': name,
        'category_id': categoryId,
        'price': price,
        'is_available': isAvailable,
        'description': description,
      },
    );
    return _decode(() => OwnerMenuItem.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<OwnerMenuItem> setMenuAvailability(
    AuthSession session, {
    required String menuId,
    required bool isAvailable,
  }) async {
    final data = await _send(
      session,
      'PUT',
      ['owner', 'menus', menuId, 'availability'],
      body: {'is_available': isAvailable},
    );
    return _decode(() => OwnerMenuItem.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<OwnerMenuItem> archiveMenu(
    AuthSession session, {
    required String menuId,
  }) async {
    final data = await _send(session, 'POST', [
      'owner',
      'menus',
      menuId,
      'archive',
    ], body: const <String, Object?>{});
    return _decode(() => OwnerMenuItem.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<OwnerMenuItem> restoreMenu(
    AuthSession session, {
    required String menuId,
  }) async {
    final data = await _send(session, 'POST', [
      'owner',
      'menus',
      menuId,
      'restore',
    ], body: const <String, Object?>{});
    return _decode(() => OwnerMenuItem.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<Uint8List?> fetchMenuPhoto(
    AuthSession session, {
    required String menuId,
  }) => _auth.sendAuthenticatedMedia(session, 'GET', [
    'owner',
    'menus',
    menuId,
    'photo',
  ], onEnvelopeError: mapOwnerEnvelopeError);

  @override
  Future<Uint8List> uploadMenuPhoto(
    AuthSession session, {
    required String menuId,
    required Uint8List bytes,
    required String mediaType,
  }) async {
    final result = await _auth.sendAuthenticatedMedia(
      session,
      'PUT',
      ['owner', 'menus', menuId, 'photo'],
      bytes: bytes,
      mediaType: mediaType,
      onEnvelopeError: mapOwnerEnvelopeError,
    );
    if (result == null) throw authBadResponseException;
    return result;
  }

  @override
  Future<OwnerMenuItem> removeMenuPhoto(
    AuthSession session, {
    required String menuId,
  }) async {
    final data = await _send(session, 'DELETE', [
      'owner',
      'menus',
      menuId,
      'photo',
    ]);
    return _decode(() => OwnerMenuItem.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<List<OwnerOrderSummary>> listOrders(
    AuthSession session, {
    required bool activeOnly,
    OwnerOrderStatus? status,
    String query = '',
  }) async {
    final data = await _send(
      session,
      'GET',
      ['owner', 'orders'],
      query: {
        'scope': activeOnly ? 'active' : 'history',
        if (status != null) 'status': status.apiValue,
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return _decode(() {
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>;
      return List<OwnerOrderSummary>.unmodifiable([
        for (final item in items)
          OwnerOrderSummary.fromJson(item as Map<String, dynamic>),
      ]);
    });
  }

  @override
  Future<OwnerOrderDetail> lookupOrder(
    AuthSession session, {
    required String orderNumber,
  }) async {
    final data = await _send(
      session,
      'GET',
      ['owner', 'orders', 'lookup'],
      query: {'code': orderNumber.trim()},
    );
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> fetchOrderDetail(
    AuthSession session, {
    required String orderId,
  }) async {
    final data = await _send(session, 'GET', ['owner', 'orders', orderId]);
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> acceptOrder(
    AuthSession session, {
    required String orderId,
  }) async {
    final data = await _send(session, 'POST', [
      'owner',
      'orders',
      orderId,
      'accept',
    ], body: const <String, Object?>{});
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> rejectOrder(
    AuthSession session, {
    required String orderId,
    required String reason,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['owner', 'orders', orderId, 'reject'],
      body: {'reason': reason},
    );
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> markOrderReady(
    AuthSession session, {
    required String orderId,
  }) async {
    final data = await _send(session, 'POST', [
      'owner',
      'orders',
      orderId,
      'ready',
    ], body: const <String, Object?>{});
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> failOrderFulfillment(
    AuthSession session, {
    required String orderId,
    required String reason,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['owner', 'orders', orderId, 'fail-fulfillment'],
      body: {'reason': reason},
    );
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> completeOrder(
    AuthSession session, {
    required String orderId,
    required bool cashReceived,
    required bool foodHandedOver,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['owner', 'orders', orderId, 'complete'],
      body: {'cash_received': cashReceived, 'food_handed_over': foodHandedOver},
    );
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> markOrderNotPickedUp(
    AuthSession session, {
    required String orderId,
  }) async {
    final data = await _send(session, 'POST', [
      'owner',
      'orders',
      orderId,
      'not-picked-up',
    ], body: const <String, Object?>{});
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<OwnerOrderDetail> failOrderPickup(
    AuthSession session, {
    required String orderId,
    required String reason,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['owner', 'orders', orderId, 'fail-pickup'],
      body: {'reason': reason},
    );
    return _decode(
      () => OwnerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Object?> _send(
    AuthSession session,
    String method,
    List<String> path, {
    Map<String, String>? query,
    Object? body,
  }) => _auth.sendAuthenticated(
    session,
    method,
    path,
    query: query,
    body: body,
    onEnvelopeError: mapOwnerEnvelopeError,
  );
}

T _decode<T>(T Function() read) {
  try {
    return read();
  } on FormatException {
    throw authBadResponseException;
  } on TypeError {
    throw authBadResponseException;
  }
}
