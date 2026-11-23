import 'dart:typed_data';

import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/customer/data/customer_error_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_repository.dart';

class CustomerApiRepository implements CustomerRepository {
  const CustomerApiRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<CustomerStallDetailBundle> fetchStallDetail(
    AuthSession session, {
    required String stallId,
  }) async {
    final data = await _send(session, 'GET', ['customer', 'stalls', stallId]);
    return _decode(
      () => CustomerStallDetailBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Uint8List?> fetchStallPhoto(
    AuthSession session, {
    required String stallId,
  }) => _auth.sendAuthenticatedMedia(session, 'GET', [
    'customer',
    'stalls',
    stallId,
    'photo',
  ], onEnvelopeError: mapCustomerEnvelopeError);

  @override
  Future<CustomerMenuDetailBundle> fetchMenuDetail(
    AuthSession session, {
    required String menuId,
  }) async {
    final data = await _send(session, 'GET', ['customer', 'menus', menuId]);
    return _decode(
      () => CustomerMenuDetailBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Uint8List?> fetchMenuPhoto(
    AuthSession session, {
    required String menuId,
  }) => _auth.sendAuthenticatedMedia(session, 'GET', [
    'customer',
    'menus',
    menuId,
    'photo',
  ], onEnvelopeError: mapCustomerEnvelopeError);

  @override
  Future<CustomerCart> fetchCart(AuthSession session) async {
    final data = await _send(session, 'GET', ['customer', 'cart']);
    return _decode(() => CustomerCart.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<CustomerCart> addCartItem(
    AuthSession session, {
    required String menuId,
    int quantity = 1,
    String itemNote = '',
    bool replaceStall = false,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['customer', 'cart', 'items'],
      body: {
        'menu_item_id': menuId,
        'quantity': quantity,
        'item_note': itemNote,
        'replace_stall': replaceStall,
      },
    );
    return _decode(() => CustomerCart.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<CustomerCart> updateCartItem(
    AuthSession session, {
    required String itemId,
    required int quantity,
    String? itemNote,
  }) async {
    final data = await _send(
      session,
      'PUT',
      ['customer', 'cart', 'items', itemId],
      body: {'quantity': quantity, 'item_note': ?itemNote},
    );
    return _decode(() => CustomerCart.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<CustomerCart> deleteCartItem(
    AuthSession session, {
    required String itemId,
  }) async {
    final data = await _send(session, 'DELETE', [
      'customer',
      'cart',
      'items',
      itemId,
    ]);
    return _decode(() => CustomerCart.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<CustomerCart> setCartGeneralNote(
    AuthSession session, {
    required String generalNote,
  }) async {
    final data = await _send(
      session,
      'PUT',
      ['customer', 'cart', 'note'],
      body: {'general_note': generalNote},
    );
    return _decode(() => CustomerCart.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<CustomerCart> acknowledgeCartPrices(
    AuthSession session, {
    int? expectedVersion,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['customer', 'cart', 'acknowledge-prices'],
      body: {'expected_version': ?expectedVersion},
    );
    return _decode(() => CustomerCart.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<CustomerCart> clearCart(AuthSession session) async {
    final data = await _send(session, 'DELETE', ['customer', 'cart']);
    return _decode(() => CustomerCart.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<CustomerCheckoutAttempt> createCheckoutAttempt(
    AuthSession session, {
    required int expectedVersion,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['customer', 'checkout', 'attempts'],
      body: {'expected_version': expectedVersion},
    );
    return _decode(
      () => CustomerCheckoutAttempt.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<CustomerAttemptLookupResult?> fetchOrderByAttempt(
    AuthSession session, {
    required String attemptId,
  }) async {
    try {
      final data = await _send(session, 'GET', [
        'customer',
        'orders',
        'attempts',
        attemptId,
      ]);
      return _decode(
        () =>
            CustomerAttemptLookupResult.fromJson(data as Map<String, dynamic>),
      );
    } on AuthException catch (error) {
      if (error.code == 'ORDER_NOT_FOUND') return null;
      rethrow;
    }
  }

  @override
  Future<CustomerCheckoutResult> checkout(
    AuthSession session, {
    required String attemptId,
    required int expectedVersion,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['customer', 'orders'],
      body: {'attempt_id': attemptId, 'expected_version': expectedVersion},
    );
    return _decode(
      () => CustomerCheckoutResult.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<({List<CustomerOrderSummary> items, bool hasMore})> listOrders(
    AuthSession session, {
    required bool activeOnly,
    int limit = 30,
    int offset = 0,
  }) async {
    final data = await _send(
      session,
      'GET',
      ['customer', 'orders'],
      query: {
        'scope': activeOnly ? 'active' : 'history',
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    return _decode(() {
      final map = data as Map<String, dynamic>;
      final rawItems = map['items'] as List<dynamic>;
      return (
        items: List<CustomerOrderSummary>.unmodifiable([
          for (final row in rawItems)
            CustomerOrderSummary.fromJson(row as Map<String, dynamic>),
        ]),
        hasMore: map['has_more'] == true,
      );
    });
  }

  @override
  Future<CustomerOrderDetail> fetchOrderDetail(
    AuthSession session, {
    required String orderId,
  }) async {
    final data = await _send(session, 'GET', ['customer', 'orders', orderId]);
    return _decode(
      () => CustomerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<CustomerOrderDetail> cancelOrder(
    AuthSession session, {
    required String orderId,
  }) async {
    final data = await _send(session, 'POST', [
      'customer',
      'orders',
      orderId,
      'cancel',
    ], body: const <String, Object?>{});
    return _decode(
      () => CustomerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<CustomerOwnerApplicationState> fetchOwnerApplicationState(
    AuthSession session,
  ) async {
    final data = await _send(session, 'GET', ['customer', 'owner-application']);
    return _decode(
      () =>
          CustomerOwnerApplicationState.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<CustomerOwnerApplicationState> submitOwnerApplication(
    AuthSession session, {
    required String plannedStallName,
    required String plannedLocation,
    required String reason,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['customer', 'owner-application'],
      body: {
        'planned_stall_name': plannedStallName,
        'planned_location': plannedLocation,
        'reason': reason,
      },
    );
    return _decode(
      () =>
          CustomerOwnerApplicationState.fromJson(data as Map<String, dynamic>),
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
    onEnvelopeError: mapCustomerEnvelopeError,
  );

  T _decode<T>(T Function() parse) {
    const error = AuthException(
      'INVALID_CUSTOMER_RESPONSE',
      'Server mengirim data yang tidak valid. Coba lagi.',
    );
    try {
      return parse();
    } on FormatException {
      throw error;
    } on TypeError {
      throw error;
    }
  }
}
