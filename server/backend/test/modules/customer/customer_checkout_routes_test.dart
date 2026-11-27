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
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_checkout_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

const _customerId = '11111111-1111-1111-1111-111111111111';
const _attemptId = '22222222-2222-2222-2222-222222222222';
const _orderId = '33333333-3333-3333-3333-333333333333';

void main() {
  late _FakeCustomerStore store;
  late Handler app;

  setUp(() {
    store = _FakeCustomerStore();
    final service = CustomerService(store: store, readMedia: (_) async => null);
    final router = Router(notFoundHandler: notFoundNoStoreResponse);
    registerCustomerCheckoutRoutes(
      router,
      context: CustomerRouteContext(
        auth: _FakeAuthGateway(),
        avatars: _FakeAvatarStore(),
        service: service,
      ),
    );
    app = _mapRouteFailures(router.call);
  });

  test(
    'creates an attempt for the authenticated customer and expected version',
    () async {
      final response = await _send(
        app,
        'POST',
        '/checkout/attempts',
        body: {'expected_version': 6},
      );

      expect(response.statusCode, 201);
      expect(_data(response)['attempt_id'], _attemptId);
      expect(store.calls.single.name, 'createCheckoutAttempt');
      expect(store.calls.single.customerId, _customerId);
      expect(store.calls.single.arguments, {'expectedVersion': 6});
      expect(response.headers['cache-control'], 'no-store');
    },
  );

  test(
    'looks up or recovers an attempt only for the authenticated customer',
    () async {
      final recovered = await _send(app, 'GET', '/orders/attempts/$_attemptId');
      expect(recovered.statusCode, 200);
      expect(_data(recovered)['status'], 'committed');
      expect((_data(recovered)['order'] as Map)['id'], _orderId);
      expect(store.calls.single.name, 'getOrderByAttempt');
      expect(store.calls.single.customerId, _customerId);
      expect(store.calls.single.arguments, {'attemptId': _attemptId});

      store.calls.clear();
      store.attemptResult = null;
      final missing = await _send(app, 'GET', '/orders/attempts/$_attemptId');
      expect(missing.statusCode, 404);
      expect(_errorCode(missing), 'ORDER_NOT_FOUND');
      expect(store.calls.single.customerId, _customerId);
    },
  );

  test(
    'returns 201 for new checkout and 200 for an idempotent replay',
    () async {
      final first = await _send(
        app,
        'POST',
        '/orders',
        body: {
          'attempt_id': _attemptId,
          'expected_version': 6,
          'customer_name': 'untrusted client name',
        },
      );
      expect(first.statusCode, 201);
      expect(_data(first)['replayed'], isFalse);
      expect(store.calls.single.name, 'checkout');
      expect(store.calls.single.customerId, _customerId);
      expect(store.calls.single.arguments, {
        'customerName': 'Customer One',
        'attemptId': _attemptId,
        'expectedVersion': 6,
      });

      store.calls.clear();
      store.checkoutResult = {
        'replayed': true,
        'order': {'id': _orderId},
      };
      final replay = await _send(
        app,
        'POST',
        '/orders',
        body: {'attempt_id': _attemptId, 'expected_version': 6},
      );
      expect(replay.statusCode, 200);
      expect(_data(replay)['replayed'], isTrue);
    },
  );

  test('propagates cart-version and idempotency conflicts as 409', () async {
    store.nextFailure = const CustomerFailure(
      CustomerFailureCode.cartVersionConflict,
    );
    final attemptConflict = await _send(
      app,
      'POST',
      '/checkout/attempts',
      body: {'expected_version': 6},
    );
    expect(attemptConflict.statusCode, 409);
    expect(_errorCode(attemptConflict), 'CART_VERSION_CONFLICT');

    store.nextFailure = const CustomerFailure(
      CustomerFailureCode.idempotencyConflict,
    );
    final replayConflict = await _send(
      app,
      'POST',
      '/orders',
      body: {'attempt_id': _attemptId, 'expected_version': 6},
    );
    expect(replayConflict.statusCode, 409);
    expect(_errorCode(replayConflict), 'IDEMPOTENCY_CONFLICT');

    store.nextFailure = const CustomerFailure(
      CustomerFailureCode.cartVersionConflict,
    );
    final checkoutConflict = await _send(
      app,
      'POST',
      '/orders',
      body: {'attempt_id': _attemptId, 'expected_version': 6},
    );
    expect(checkoutConflict.statusCode, 409);
    expect(_errorCode(checkoutConflict), 'CART_VERSION_CONFLICT');
  });

  test('validates UUIDs and positive database integer versions', () async {
    final missingAttemptVersion = await _send(
      app,
      'POST',
      '/checkout/attempts',
      body: {},
    );
    expect(missingAttemptVersion.statusCode, 400);

    for (final version in [0, -1, 2147483648, '6']) {
      final invalidAttemptVersion = await _send(
        app,
        'POST',
        '/checkout/attempts',
        body: {'expected_version': version},
      );
      expect(invalidAttemptVersion.statusCode, 400);

      final invalidCheckoutVersion = await _send(
        app,
        'POST',
        '/orders',
        body: {'attempt_id': _attemptId, 'expected_version': version},
      );
      expect(invalidCheckoutVersion.statusCode, 400);
    }

    final invalidAttemptId = await _send(
      app,
      'GET',
      '/orders/attempts/not-a-uuid',
    );
    expect(invalidAttemptId.statusCode, 400);

    final invalidCheckoutId = await _send(
      app,
      'POST',
      '/orders',
      body: {'attempt_id': 'not-a-uuid', 'expected_version': 6},
    );
    expect(invalidCheckoutId.statusCode, 400);
    expect(store.calls, isEmpty);
  });

  test(
    'rejects malformed replay result and unauthenticated requests',
    () async {
      store.checkoutResult = {
        'order': {'id': _orderId},
      };
      final malformedResult = await _send(
        app,
        'POST',
        '/orders',
        body: {'attempt_id': _attemptId, 'expected_version': 6},
      );
      expect(malformedResult.statusCode, 503);
      expect(_errorCode(malformedResult), 'CUSTOMER_UNAVAILABLE');

      final unauthorized = await _send(
        app,
        'POST',
        '/checkout/attempts',
        bearer: null,
        body: {'expected_version': 6},
      );
      expect(unauthorized.statusCode, 401);
    },
  );
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
      displayName: 'Customer One',
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
  Map<String, Object?>? attemptResult = {
    'attempt_id': _attemptId,
    'status': 'committed',
    'order': {'id': _orderId},
  };
  Map<String, Object?> checkoutResult = {
    'replayed': false,
    'order': {'id': _orderId},
  };

  void _record(String name, String customerId, Map<String, Object?> arguments) {
    calls.add((name: name, customerId: customerId, arguments: arguments));
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Future<Map<String, Object?>> createCheckoutAttempt(
    String customerId, {
    required int expectedVersion,
  }) async {
    _record('createCheckoutAttempt', customerId, {
      'expectedVersion': expectedVersion,
    });
    return {'attempt_id': _attemptId, 'cart_version': expectedVersion};
  }

  @override
  Future<Map<String, Object?>?> getOrderByAttempt(
    String customerId, {
    required String attemptId,
  }) async {
    _record('getOrderByAttempt', customerId, {'attemptId': attemptId});
    return attemptResult;
  }

  @override
  Future<Map<String, Object?>> checkout(
    String customerId, {
    required String customerName,
    required String attemptId,
    required int expectedVersion,
  }) async {
    _record('checkout', customerId, {
      'customerName': customerName,
      'attemptId': attemptId,
      'expectedVersion': expectedVersion,
    });
    return checkoutResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
