import 'dart:convert';
import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/application/customer_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_failure_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_cart_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

const _customerId = '11111111-1111-1111-1111-111111111111';
const _menuId = '22222222-2222-2222-2222-222222222222';
const _itemId = '33333333-3333-3333-3333-333333333333';

void main() {
  late _FakeCustomerStore store;
  late Handler app;

  setUp(() {
    store = _FakeCustomerStore();
    final service = CustomerService(store: store, readMedia: (_) async => null);
    final router = Router(notFoundHandler: notFoundNoStoreResponse);
    registerCustomerCartRoutes(
      router,
      context: CustomerRouteContext(
        auth: _FakeAuthGateway(),
        avatars: _FakeAvatarStore(),
        service: service,
      ),
    );
    app = _mapRouteFailures(router.call);
  });

  test('reads the authenticated customer cart', () async {
    final response = await _send(app, 'GET', '/cart');

    expect(response.statusCode, 200);
    expect(response.headers['cache-control'], 'no-store');
    expect(_data(response)['draft_version'], 3);
    expect(store.calls.single.name, 'getCart');
    expect(store.calls.single.customerId, _customerId);
  });

  test('adds a cart item using schema defaults and bounded values', () async {
    final response = await _send(
      app,
      'POST',
      '/cart/items',
      body: {'menu_item_id': _menuId},
    );

    expect(response.statusCode, 201);
    expect(_data(response)['items'], isA<List>());
    expect(store.calls.single.name, 'addCartItem');
    expect(store.calls.single.customerId, _customerId);
    expect(store.calls.single.arguments, {
      'menuId': _menuId,
      'quantity': 1,
      'itemNote': '',
      'replaceStall': false,
    });
  });

  test(
    'updates and deletes an item; updates note, acknowledges price, clears cart',
    () async {
      final updated = await _send(
        app,
        'PUT',
        '/cart/items/$_itemId',
        body: {'quantity': 4, 'item_note': 'tanpa bawang'},
      );
      expect(updated.statusCode, 200);
      expect(store.calls.last.name, 'updateCartItem');
      expect(store.calls.last.arguments, {
        'itemId': _itemId,
        'quantity': 4,
        'itemNote': 'tanpa bawang',
      });

      final deleted = await _send(app, 'DELETE', '/cart/items/$_itemId');
      expect(deleted.statusCode, 200);
      expect(store.calls.last.name, 'updateCartItem');
      expect(store.calls.last.arguments, {
        'itemId': _itemId,
        'quantity': 0,
        'itemNote': null,
      });

      final note = await _send(
        app,
        'PUT',
        '/cart/note',
        body: {'general_note': 'antar ke meja'},
      );
      expect(note.statusCode, 200);
      expect(store.calls.last.name, 'setCartNote');
      expect(store.calls.last.arguments, {'generalNote': 'antar ke meja'});

      final acknowledged = await _send(
        app,
        'POST',
        '/cart/acknowledge-prices',
        body: {'expected_version': 2},
      );
      expect(acknowledged.statusCode, 200);
      expect(store.calls.last.name, 'acknowledgeCartPrices');
      expect(store.calls.last.arguments, {'expectedVersion': 2});

      final noVersion = await _send(
        app,
        'POST',
        '/cart/acknowledge-prices',
        body: {},
      );
      expect(noVersion.statusCode, 200);
      expect(store.calls.last.arguments, {'expectedVersion': null});

      final cleared = await _send(app, 'DELETE', '/cart');
      expect(cleared.statusCode, 200);
      expect(store.calls.last.name, 'clearCart');
      expect(store.calls.last.customerId, _customerId);
    },
  );

  test(
    'rejects invalid UUIDs, quantities, notes, booleans, and versions',
    () async {
      final invalidMenu = await _send(
        app,
        'POST',
        '/cart/items',
        body: {'menu_item_id': 'not-a-uuid'},
      );
      expect(invalidMenu.statusCode, 400);

      for (final quantity in [0, 1000]) {
        final invalidQuantity = await _send(
          app,
          'POST',
          '/cart/items',
          body: {'menu_item_id': _menuId, 'quantity': quantity},
        );
        expect(invalidQuantity.statusCode, 400);
      }

      final longItemNote = await _send(
        app,
        'POST',
        '/cart/items',
        body: {
          'menu_item_id': _menuId,
          'item_note': List.filled(301, 'a').join(),
        },
      );
      expect(longItemNote.statusCode, 400);

      final badBoolean = await _send(
        app,
        'POST',
        '/cart/items',
        body: {'menu_item_id': _menuId, 'replace_stall': 'true'},
      );
      expect(badBoolean.statusCode, 400);

      final invalidItemId = await _send(
        app,
        'PUT',
        '/cart/items/not-a-uuid',
        body: {'quantity': 1},
      );
      expect(invalidItemId.statusCode, 400);

      final missingUpdateQuantity = await _send(
        app,
        'PUT',
        '/cart/items/$_itemId',
        body: {},
      );
      expect(missingUpdateQuantity.statusCode, 400);

      final longGeneralNote = await _send(
        app,
        'PUT',
        '/cart/note',
        body: {'general_note': List.filled(501, 'a').join()},
      );
      expect(longGeneralNote.statusCode, 400);

      for (final version in [0, 2147483648, '2']) {
        final invalidVersion = await _send(
          app,
          'POST',
          '/cart/acknowledge-prices',
          body: {'expected_version': version},
        );
        expect(invalidVersion.statusCode, 400);
      }

      expect(store.calls, isEmpty);
    },
  );

  test('maps store failures and enforces authentication', () async {
    store.nextFailure = const CustomerFailure(
      CustomerFailureCode.cartDifferentStall,
    );
    final conflict = await _send(
      app,
      'POST',
      '/cart/items',
      body: {'menu_item_id': _menuId},
    );
    expect(conflict.statusCode, 409);
    expect(_errorCode(conflict), 'CART_DIFFERENT_STALL');

    final unauthorized = await _send(app, 'GET', '/cart', bearer: null);
    expect(unauthorized.statusCode, 401);
  });
}

Handler _mapRouteFailures(Handler handler) => (request) async {
  try {
    return await handler(request);
  } on AuthFailure catch (failure) {
    final error = authFailureException(failure);
    return ApiResponse.error(
      statusCode: error.statusCode,
      code: error.code,
      message: error.message,
      headers: noStoreHeaders,
    );
  } on CustomerFailure catch (failure) {
    final error = customerFailureException(failure);
    return ApiResponse.error(
      statusCode: error.statusCode,
      code: error.code,
      message: error.message,
      headers: noStoreHeaders,
    );
  }
};

Future<_DecodedResponse> _send(
  Handler app,
  String method,
  String path, {
  Map<String, Object?>? body,
  String? bearer = 'tok-customer',
}) async {
  final request = Request(
    method,
    Uri.parse('https://api.example.test$path'),
    headers: {
      'host': 'api.example.test',
      if (bearer != null) 'authorization': 'Bearer $bearer',
      if (body != null) 'content-type': 'application/json',
    },
    body: body == null ? null : jsonEncode(body),
  );
  final response = await app(request);
  final chunks = await response.read().toList();
  final bytes = Uint8List.fromList([for (final chunk in chunks) ...chunk]);
  final text = utf8.decode(bytes, allowMalformed: true);
  Map<String, dynamic>? json;
  if (response.headers['content-type']?.contains('application/json') == true &&
      text.isNotEmpty) {
    json = jsonDecode(text) as Map<String, dynamic>;
  }
  return _DecodedResponse(response.statusCode, response.headers, json);
}

Map<String, dynamic> _data(_DecodedResponse response) =>
    response.json!['data'] as Map<String, dynamic>;

String _errorCode(_DecodedResponse response) =>
    (response.json!['error'] as Map<String, dynamic>)['code'] as String;

class _DecodedResponse {
  const _DecodedResponse(this.statusCode, this.headers, this.json);

  final int statusCode;
  final Map<String, String> headers;
  final Map<String, dynamic>? json;
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<AuthAccount> account(String accessToken) async {
    if (accessToken != 'tok-customer') throw AuthFailure.invalidSession;
    return const AuthAccount(
      id: _customerId,
      email: 'customer@example.test',
      displayName: 'Customer',
      role: AccountRole.customer,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvatarStore implements AvatarStore {
  @override
  Future<bool> exists(String accountId) async => accountId == _customerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomerStore implements CustomerStore {
  final calls =
      <({String name, String customerId, Map<String, Object?> arguments})>[];
  CustomerFailure? nextFailure;

  final _cart = <String, Object?>{
    'items': const [],
    'draft_version': 3,
    'can_checkout': false,
  };

  void _record(
    String name,
    String customerId, [
    Map<String, Object?> arguments = const {},
  ]) {
    calls.add((name: name, customerId: customerId, arguments: arguments));
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Future<Map<String, Object?>> getCart(String customerId) async {
    _record('getCart', customerId);
    return _cart;
  }

  @override
  Future<Map<String, Object?>> addCartItem(
    String customerId, {
    required String menuId,
    required int quantity,
    required String itemNote,
    required bool replaceStall,
  }) async {
    _record('addCartItem', customerId, {
      'menuId': menuId,
      'quantity': quantity,
      'itemNote': itemNote,
      'replaceStall': replaceStall,
    });
    return _cart;
  }

  @override
  Future<Map<String, Object?>> updateCartItem(
    String customerId, {
    required String itemId,
    required int quantity,
    String? itemNote,
  }) async {
    _record('updateCartItem', customerId, {
      'itemId': itemId,
      'quantity': quantity,
      'itemNote': itemNote,
    });
    return _cart;
  }

  @override
  Future<Map<String, Object?>> setCartNote(
    String customerId, {
    required String generalNote,
  }) async {
    _record('setCartNote', customerId, {'generalNote': generalNote});
    return _cart;
  }

  @override
  Future<Map<String, Object?>> acknowledgeCartPrices(
    String customerId, {
    int? expectedVersion,
  }) async {
    _record('acknowledgeCartPrices', customerId, {
      'expectedVersion': expectedVersion,
    });
    return _cart;
  }

  @override
  Future<Map<String, Object?>> clearCart(String customerId) async {
    _record('clearCart', customerId);
    return _cart;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
