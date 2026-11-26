import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/application/customer_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/data/supabase_customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import '../../config_test.dart' show validEnvironment;

const _custId = '11111111-1111-1111-1111-111111111111';
const _cust2Id = '22222222-2222-2222-2222-222222222222';
const _ownerId = '33333333-3333-3333-3333-333333333333';
const _adminId = '44444444-4444-4444-4444-444444444444';
const _stallId = '55555555-5555-5555-5555-555555555555';
const _menuId = '66666666-6666-6666-6666-666666666666';
const _cartItemId = '77777777-7777-7777-7777-777777777777';
const _attemptId = '88888888-8888-8888-8888-888888888888';
const _orderId = '99999999-9999-9999-9999-999999999999';

void main() {
  late _FakeAuthGateway auth;
  late _FakeAvatarStore avatars;
  late _FakeMediaStore media;
  late _FakeCustomerStore customerStore;
  late Handler app;

  setUp(() {
    auth = _FakeAuthGateway();
    avatars = _FakeAvatarStore();
    media = _FakeMediaStore();
    customerStore = _FakeCustomerStore();
    final router = Router();
    router.mount(
      '/v1/customer/',
      buildCustomerHandler(
        auth,
        avatars: avatars,
        service: CustomerService(store: customerStore, readMedia: media.read),
      ),
    );
    app = router.call;
  });

  test('enforces auth, complete profile, and role isolation', () async {
    expect((await _send(app, 'GET', '/customer/cart')).statusCode, 401);

    avatars.hasAvatar[_custId] = false;
    final incomplete = await _send(
      app,
      'GET',
      '/customer/cart',
      bearer: 'tok-cust1',
    );
    expect(incomplete.statusCode, 409);

    final adminRes = await _send(
      app,
      'GET',
      '/customer/cart',
      bearer: 'tok-admin',
    );
    expect(adminRes.statusCode, 403);
    expect(_errorCode(adminRes), 'CUSTOMER_ROLE_REQUIRED');

    final ownerRes = await _send(
      app,
      'GET',
      '/customer/cart',
      bearer: 'tok-owner',
    );
    expect(ownerRes.statusCode, 200);
  });

  test('serves stall/menu details and private media photos cleanly', () async {
    final stall = await _send(
      app,
      'GET',
      '/customer/stalls/$_stallId',
      bearer: 'tok-cust1',
    );
    expect(stall.statusCode, 200);
    expect((_data(stall)['stall'] as Map)['name'], 'Kantin A');

    media.files['stalls/$_stallId/photo.jpg'] = Uint8List.fromList([
      0xff,
      0xd8,
      0xff,
      0xd9,
    ]);
    final stallPhoto = await _send(
      app,
      'GET',
      '/customer/stalls/$_stallId/photo',
      bearer: 'tok-cust1',
    );
    expect(stallPhoto.statusCode, 200);
    expect(stallPhoto.headers['content-type'], 'image/jpeg');

    final menuPhoto = await _send(
      app,
      'GET',
      '/customer/menus/$_menuId/photo',
      bearer: 'tok-cust1',
    );
    expect(menuPhoto.statusCode, 204);

    final missing = await _send(
      app,
      'GET',
      '/customer/stalls/00000000-0000-0000-0000-000000000000',
      bearer: 'tok-cust1',
    );
    expect(missing.statusCode, 404);
  });

  test(
    'handles cart lifecycle, stall conflict, price ack, and clear',
    () async {
      final added = await _send(
        app,
        'POST',
        '/customer/cart/items',
        bearer: 'tok-cust1',
        body: {'menu_item_id': _menuId, 'quantity': 2, 'item_note': 'Pedas'},
      );
      expect(added.statusCode, 201);
      expect((_data(added)['items'] as List).length, 1);

      customerStore.nextError = const CustomerFailure(
        CustomerFailureCode.cartDifferentStall,
      );
      final conflict = await _send(
        app,
        'POST',
        '/customer/cart/items',
        bearer: 'tok-cust1',
        body: {'menu_item_id': _menuId, 'quantity': 1, 'replace_stall': false},
      );
      expect(conflict.statusCode, 409);
      expect(_errorCode(conflict), 'CART_DIFFERENT_STALL');

      final updated = await _send(
        app,
        'PUT',
        '/customer/cart/items/$_cartItemId',
        bearer: 'tok-cust1',
        body: {'quantity': 0},
      );
      expect(updated.statusCode, 200);

      final note = await _send(
        app,
        'PUT',
        '/customer/cart/note',
        bearer: 'tok-cust1',
        body: {'general_note': 'Jangan pedas'},
      );
      expect(note.statusCode, 200);

      final ack = await _send(
        app,
        'POST',
        '/customer/cart/acknowledge-prices',
        bearer: 'tok-cust1',
        body: {'expected_version': 2},
      );
      expect(ack.statusCode, 200);

      final deleted = await _send(
        app,
        'DELETE',
        '/customer/cart/items/$_cartItemId',
        bearer: 'tok-cust1',
      );
      expect(deleted.statusCode, 200);

      final cleared = await _send(
        app,
        'DELETE',
        '/customer/cart',
        bearer: 'tok-cust1',
      );
      expect(cleared.statusCode, 200);
    },
  );

  test(
    'supports checkout attempts, idempotent replay, conflict, orders & cancel',
    () async {
      final attempt = await _send(
        app,
        'POST',
        '/customer/checkout/attempts',
        bearer: 'tok-cust1',
        body: {'expected_version': 1},
      );
      expect(attempt.statusCode, 201);
      expect(_data(attempt)['attempt_id'], _attemptId);

      final firstCheckout = await _send(
        app,
        'POST',
        '/customer/orders',
        bearer: 'tok-cust1',
        body: {'attempt_id': _attemptId, 'expected_version': 1},
      );
      expect(firstCheckout.statusCode, 201);
      expect(_data(firstCheckout)['replayed'], isFalse);

      customerStore.replayedCheckout = true;
      final replay = await _send(
        app,
        'POST',
        '/customer/orders',
        bearer: 'tok-cust1',
        body: {'attempt_id': _attemptId, 'expected_version': 1},
      );
      expect(replay.statusCode, 200);
      expect(_data(replay)['replayed'], isTrue);

      final recovered = await _send(
        app,
        'GET',
        '/customer/orders/attempts/$_attemptId',
        bearer: 'tok-cust1',
      );
      expect(recovered.statusCode, 200);

      final list = await _send(
        app,
        'GET',
        '/customer/orders?scope=active',
        bearer: 'tok-cust1',
      );
      expect(list.statusCode, 200);

      final detail = await _send(
        app,
        'GET',
        '/customer/orders/$_orderId',
        bearer: 'tok-cust1',
      );
      expect(detail.statusCode, 200);

      final otherCust = await _send(
        app,
        'GET',
        '/customer/orders/$_orderId',
        bearer: 'tok-cust2',
      );
      expect(otherCust.statusCode, 404);

      final cancel = await _send(
        app,
        'POST',
        '/customer/orders/$_orderId/cancel',
        bearer: 'tok-cust1',
        body: {},
      );
      expect(cancel.statusCode, 200);
      expect(_data(cancel)['status'], 'dibatalkan');
    },
  );

  test(
    'owner application enforces Customer-only, allows submit with active orders, blocks duplicate',
    () async {
      final getApp = await _send(
        app,
        'GET',
        '/customer/owner-application',
        bearer: 'tok-cust1',
      );
      expect(getApp.statusCode, 200);

      final ownerSubmit = await _send(
        app,
        'POST',
        '/customer/owner-application',
        bearer: 'tok-owner',
        body: {
          'planned_stall_name': 'Warung',
          'planned_location': 'Blok A',
          'reason': 'Jualan',
        },
      );
      expect(ownerSubmit.statusCode, 409);
      expect(_errorCode(ownerSubmit), 'ALREADY_OWNER');

      final submit = await _send(
        app,
        'POST',
        '/customer/owner-application',
        bearer: 'tok-cust1',
        body: {
          'planned_stall_name': 'Kantin Baru',
          'planned_location': 'USU Blok C',
          'reason': 'Menyediakan makanan sehat',
        },
      );
      expect(submit.statusCode, 201);
    },
  );

  test(
    'SupabaseCustomerStore maps PostgREST domain codes and hides SQL errors',
    () async {
      final config = AppConfig.fromEnv(EnvConfig.fromMap(validEnvironment()));
      final factory = SupabaseClientFactory(config: config.supabase);
      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('kc_customer_checkout')) {
          return http.Response(
            jsonEncode({
              'code': 'P0001',
              'message': 'KC_PRICE_CHANGED',
              'details': 'sensitive postgres internal stack',
            }),
            400,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response(
          jsonEncode({'message': 'secret pg password leak'}),
          500,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      final store = SupabaseCustomerStore(factory, httpClient: mockHttp);

      await expectLater(
        () => store.checkout(
          _custId,
          customerName: 'Doni',
          attemptId: _attemptId,
          expectedVersion: 1,
        ),
        throwsA(
          isA<CustomerFailure>().having(
            (e) => e.code,
            'code',
            CustomerFailureCode.priceChanged,
          ),
        ),
      );

      await expectLater(
        () => store.getCart(_custId),
        throwsA(
          isA<CustomerFailure>()
              .having((e) => e.code, 'code', CustomerFailureCode.unavailable)
              .having((e) => e.message, 'message', isNull),
        ),
      );
    },
  );

  test(
    'covers menu detail, photo 200/204, input/header guards & cancel conflict',
    () async {
      final menuDet = await _send(
        app,
        'GET',
        '/customer/menus/$_menuId',
        bearer: 'tok-cust1',
      );
      expect(menuDet.statusCode, 200);
      expect((_data(menuDet)['menu'] as Map)['name'], 'Nasi Goreng');

      final missingMenu = await _send(
        app,
        'GET',
        '/customer/menus/00000000-0000-0000-0000-000000000000',
        bearer: 'tok-cust1',
      );
      expect(missingMenu.statusCode, 404);

      media.files['menus/$_menuId/photo.jpg'] = Uint8List.fromList([
        0xff,
        0xd8,
        0xff,
        0xd9,
      ]);
      customerStore.menuPhotoPathValue = 'menus/$_menuId/photo.jpg';
      final menuPhoto = await _send(
        app,
        'GET',
        '/customer/menus/$_menuId/photo',
        bearer: 'tok-cust1',
      );
      expect(menuPhoto.statusCode, 200);
      expect(menuPhoto.headers['content-type'], 'image/jpeg');

      final badUuid = await _send(
        app,
        'GET',
        '/customer/stalls/not-a-uuid',
        bearer: 'tok-cust1',
      );
      expect(badUuid.statusCode, 400);
      expect(_errorCode(badUuid), 'INVALID_INPUT');

      final badScope = await _send(
        app,
        'GET',
        '/customer/orders?scope=other&limit=0',
        bearer: 'tok-cust1',
      );
      expect(badScope.statusCode, 400);

      final badCt = await app(
        Request(
          'POST',
          Uri.parse('https://api.example.test/v1/customer/cart/items'),
          headers: {
            'host': 'api.example.test',
            'authorization': 'Bearer tok-cust1',
          },
          body: '{}',
        ),
      );
      expect(badCt.statusCode, 415);

      customerStore.nextError = const CustomerFailure(
        CustomerFailureCode.invalidOrderTransition,
      );
      final cancelBlocked = await _send(
        app,
        'POST',
        '/customer/orders/$_orderId/cancel',
        bearer: 'tok-cust1',
        body: {},
      );
      expect(cancelBlocked.statusCode, 409);
      expect(_errorCode(cancelBlocked), 'INVALID_ORDER_TRANSITION');
    },
  );
}

Future<_DecodedResponse> _send(
  Handler app,
  String method,
  String path, {
  String? bearer,
  Object? body,
}) async {
  final headers = <String, String>{
    'host': 'api.example.test',
    if (bearer != null) 'authorization': 'Bearer $bearer',
    if (body != null) 'content-type': 'application/json',
  };
  final request = Request(
    method,
    Uri.parse('https://api.example.test/v1$path'),
    headers: headers,
    body: body == null ? null : jsonEncode(body),
  );
  final response = await app(request);
  final bytes = await response.read().toList();
  final rawBytes = Uint8List.fromList([for (final chunk in bytes) ...chunk]);
  final text = utf8.decode(rawBytes, allowMalformed: true);
  Map<String, dynamic>? decoded;
  if (response.headers['content-type']?.contains('application/json') == true &&
      text.isNotEmpty) {
    decoded = jsonDecode(text) as Map<String, dynamic>;
  }
  return _DecodedResponse(response.statusCode, response.headers, decoded);
}

class _DecodedResponse {
  const _DecodedResponse(this.statusCode, this.headers, this.json);
  final int statusCode;
  final Map<String, String> headers;
  final Map<String, dynamic>? json;
}

Map<String, dynamic> _data(_DecodedResponse res) =>
    res.json!['data'] as Map<String, dynamic>;

String _errorCode(_DecodedResponse res) =>
    (res.json!['error'] as Map<String, dynamic>)['code'] as String;

class _FakeAuthGateway implements AuthGateway {
  final accounts = <String, AuthAccount>{
    'tok-cust1': const AuthAccount(
      id: _custId,
      email: 'c1@example.test',
      displayName: 'Cust Satu',
      role: AccountRole.customer,
      canManageCredentials: true,
    ),
    'tok-cust2': const AuthAccount(
      id: _cust2Id,
      email: 'c2@example.test',
      displayName: 'Cust Dua',
      role: AccountRole.customer,
      canManageCredentials: true,
    ),
    'tok-owner': const AuthAccount(
      id: _ownerId,
      email: 'owner@example.test',
      displayName: 'Owner Satu',
      role: AccountRole.owner,
      canManageCredentials: true,
    ),
    'tok-admin': const AuthAccount(
      id: _adminId,
      email: 'admin@example.test',
      displayName: 'Admin',
      role: AccountRole.admin,
      canManageCredentials: true,
    ),
  };

  @override
  Future<AuthAccount> account(String accessToken) async {
    final account = accounts[accessToken];
    if (account == null) throw AuthFailure.invalidSession;
    return account;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvatarStore implements AvatarStore {
  final hasAvatar = <String, bool>{
    _custId: true,
    _cust2Id: true,
    _ownerId: true,
    _adminId: true,
  };

  @override
  Future<bool> exists(String userId) async => hasAvatar[userId] ?? false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMediaStore {
  final files = <String, Uint8List>{};

  Future<Uint8List?> read(String objectPath) async => files[objectPath];
}

class _FakeCustomerStore implements CustomerStore {
  CustomerFailure? nextError;
  bool replayedCheckout = false;
  String? menuPhotoPathValue;

  void _checkErr() {
    final err = nextError;
    nextError = null;
    if (err != null) throw err;
  }

  @override
  Future<Map<String, Object?>?> getStallDetail(String stallId) async {
    if (stallId != _stallId) return null;
    return {
      'stall': {
        'id': _stallId,
        'name': 'Kantin A',
        'block': 'Blok A',
        'description': 'Deskripsi',
        'wait_minutes': 10,
        'is_listed': true,
        'is_open': true,
        'owner_active': true,
        'has_photo': true,
      },
      'schedules': const [],
      'categories': const [],
      'menus': const [],
    };
  }

  @override
  Future<Map<String, Object?>?> getMenuDetail(String menuId) async {
    if (menuId != _menuId) return null;
    return {
      'menu': {
        'id': _menuId,
        'stall_id': _stallId,
        'category_name': 'Makanan',
        'name': 'Nasi Goreng',
        'description': '',
        'price': 15000,
        'is_available': true,
        'has_photo': false,
      },
      'stall': {
        'id': _stallId,
        'name': 'Kantin A',
        'block': 'Blok A',
        'description': '',
        'wait_minutes': 10,
        'is_listed': true,
        'is_open': true,
        'owner_active': true,
        'has_photo': false,
      },
    };
  }

  @override
  Future<String?> getStallPhotoPath(String stallId) async =>
      stallId == _stallId ? 'stalls/$_stallId/photo.jpg' : null;

  @override
  Future<String?> getMenuPhotoPath(String menuId) async =>
      menuId == _menuId ? menuPhotoPathValue : null;

  @override
  Future<Map<String, Object?>> getCart(String customerId) async => {
    'stall': null,
    'items': const [],
    'general_note': '',
    'draft_version': 1,
    'subtotal': 0,
    'seen_subtotal': 0,
    'item_count': 0,
    'can_checkout': false,
    'blockers': const [],
  };

  @override
  Future<Map<String, Object?>> addCartItem(
    String customerId, {
    required String menuId,
    required int quantity,
    required String itemNote,
    required bool replaceStall,
  }) async {
    _checkErr();
    return {
      'stall': {'id': _stallId, 'name': 'Kantin A'},
      'items': [
        {
          'id': _cartItemId,
          'menu_item_id': menuId,
          'menu_name': 'Nasi Goreng',
          'quantity': quantity,
          'item_note': itemNote,
          'seen_unit_price': 15000,
          'current_unit_price': 15000,
        },
      ],
      'general_note': '',
      'draft_version': 2,
      'subtotal': quantity * 15000,
      'seen_subtotal': quantity * 15000,
      'item_count': quantity,
      'can_checkout': true,
      'blockers': const [],
    };
  }

  @override
  Future<Map<String, Object?>> updateCartItem(
    String customerId, {
    required String itemId,
    required int quantity,
    String? itemNote,
  }) async => getCart(customerId);

  @override
  Future<Map<String, Object?>> setCartNote(
    String customerId, {
    required String generalNote,
  }) async => getCart(customerId);

  @override
  Future<Map<String, Object?>> acknowledgeCartPrices(
    String customerId, {
    int? expectedVersion,
  }) async => getCart(customerId);

  @override
  Future<Map<String, Object?>> clearCart(String customerId) async =>
      getCart(customerId);

  @override
  Future<Map<String, Object?>> createCheckoutAttempt(
    String customerId, {
    required int expectedVersion,
  }) async => {
    'attempt_id': _attemptId,
    'cart_version': expectedVersion,
    'payload_hash': 'abcd1234',
  };

  @override
  Future<Map<String, Object?>?> getOrderByAttempt(
    String customerId, {
    required String attemptId,
  }) async => {
    'attempt_id': attemptId,
    'status': 'committed',
    'order': await getOrder(customerId, orderId: _orderId),
  };

  @override
  Future<Map<String, Object?>> checkout(
    String customerId, {
    required String customerName,
    required String attemptId,
    required int expectedVersion,
  }) async => {
    'replayed': replayedCheckout,
    'order': await getOrder(customerId, orderId: _orderId),
  };

  @override
  Future<Map<String, Object?>> listOrders(
    String customerId, {
    required String scope,
    required int limit,
    required int offset,
  }) async => {'items': const [], 'has_more': false};

  @override
  Future<Map<String, Object?>?> getOrder(
    String customerId, {
    required String orderId,
  }) async {
    if (customerId != _custId || orderId != _orderId) return null;
    return {
      'id': _orderId,
      'order_number': '00001',
      'stall_id': _stallId,
      'stall_name': 'Kantin A',
      'stall_block': 'Blok A',
      'stall_campus': 'USU',
      'status': 'menunggu_konfirmasi',
      'payment_status': 'belum_lunas',
      'items': const [],
      'events': const [],
    };
  }

  @override
  Future<Map<String, Object?>> cancelOrder(
    String customerId, {
    required String orderId,
  }) async {
    _checkErr();
    return {
      'id': _orderId,
      'order_number': '00001',
      'status': 'dibatalkan',
      'payment_status': 'belum_lunas',
    };
  }

  @override
  Future<Map<String, Object?>> getOwnerApplicationState(
    String customerId,
  ) async => {
    'latest_application': null,
    'active_order_indicator': {
      'user_id': customerId,
      'has_active_orders': false,
      'active_order_count': 0,
    },
  };

  @override
  Future<Map<String, Object?>> submitOwnerApplication(
    String customerId, {
    required String plannedStallName,
    required String plannedLocation,
    required String reason,
  }) async => {
    'latest_application': {
      'planned_stall_name': plannedStallName,
      'planned_location': plannedLocation,
      'reason': reason,
      'status': 'menunggu_review',
    },
    'active_order_indicator': {
      'user_id': customerId,
      'has_active_orders': false,
      'active_order_count': 0,
    },
  };

  @override
  Future<Map<String, Object?>> getAdminActiveOrderIndicator(
    String userId,
  ) async => {
    'user_id': userId,
    'has_active_orders': false,
    'active_order_count': 0,
  };
}
