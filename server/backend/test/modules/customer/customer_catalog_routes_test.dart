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
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_catalog_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

const _customerId = '11111111-1111-1111-1111-111111111111';
const _stallId = '22222222-2222-2222-2222-222222222222';
const _menuId = '33333333-3333-3333-3333-333333333333';
const _missingId = '44444444-4444-4444-4444-444444444444';
const _stallPhotoPath = 'stalls/$_stallId/photo.jpg';

void main() {
  late _FakeCustomerStore store;
  late _FakeMediaStore media;
  late Handler app;

  setUp(() {
    store = _FakeCustomerStore();
    media = _FakeMediaStore();
    final service = CustomerService(store: store, readMedia: media.read);
    final router = Router(notFoundHandler: notFoundNoStoreResponse);
    registerCustomerCatalogRoutes(
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
    'serves stall and menu details and returns 404 for missing records',
    () async {
      final stall = await _send(app, 'GET', '/stalls/$_stallId');
      expect(stall.statusCode, 200);
      expect(stall.headers['cache-control'], 'no-store');
      expect(_data(stall)['stall']['name'], 'Kantin A');

      final menu = await _send(app, 'GET', '/menus/$_menuId');
      expect(menu.statusCode, 200);
      expect(_data(menu)['menu']['name'], 'Nasi Goreng');

      final missingStall = await _send(app, 'GET', '/stalls/$_missingId');
      expect(missingStall.statusCode, 404);
      expect(_errorCode(missingStall), 'STALL_NOT_FOUND');

      final missingMenu = await _send(app, 'GET', '/menus/$_missingId');
      expect(missingMenu.statusCode, 404);
      expect(_errorCode(missingMenu), 'MENU_NOT_FOUND');
    },
  );

  test('normalizes valid UUIDs and rejects malformed UUIDs', () async {
    final uppercaseId = await _send(
      app,
      'GET',
      '/stalls/${_stallId.toUpperCase()}',
    );
    expect(uppercaseId.statusCode, 200);
    expect(store.lastStallId, _stallId);

    final invalid = await _send(app, 'GET', '/menus/not-a-uuid');
    expect(invalid.statusCode, 400);
    expect(_errorCode(invalid), 'INVALID_INPUT');
  });

  test(
    'returns private JPEG bytes or 204 when a valid item has no photo',
    () async {
      final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      media.files[_stallPhotoPath] = jpeg;
      store.stallPhotoPath = _stallPhotoPath;

      final stallPhoto = await _send(app, 'GET', '/stalls/$_stallId/photo');
      expect(stallPhoto.statusCode, 200);
      expect(stallPhoto.headers['content-type'], 'image/jpeg');
      expect(stallPhoto.headers['content-length'], '${jpeg.length}');
      expect(stallPhoto.headers['cache-control'], 'no-store');
      expect(stallPhoto.bodyBytes, jpeg);

      final menuPhoto = await _send(app, 'GET', '/menus/$_menuId/photo');
      expect(menuPhoto.statusCode, 204);
      expect(menuPhoto.headers['cache-control'], 'no-store');

      final missingPhotoResource = await _send(
        app,
        'GET',
        '/stalls/$_missingId/photo',
      );
      expect(missingPhotoResource.statusCode, 404);
    },
  );

  test('requires an authenticated actor', () async {
    final response = await _send(app, 'GET', '/stalls/$_stallId', bearer: null);
    expect(response.statusCode, 401);
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
  String? bearer = 'tok-customer',
}) async {
  final request = Request(
    method,
    Uri.parse('https://api.example.test$path'),
    headers: {
      'host': 'api.example.test',
      if (bearer != null) 'authorization': 'Bearer $bearer',
    },
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
  return _DecodedResponse(response.statusCode, response.headers, json, bytes);
}

Map<String, dynamic> _data(_DecodedResponse response) =>
    response.json!['data'] as Map<String, dynamic>;

String _errorCode(_DecodedResponse response) =>
    (response.json!['error'] as Map<String, dynamic>)['code'] as String;

class _DecodedResponse {
  const _DecodedResponse(
    this.statusCode,
    this.headers,
    this.json,
    this.bodyBytes,
  );

  final int statusCode;
  final Map<String, String> headers;
  final Map<String, dynamic>? json;
  final Uint8List bodyBytes;
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
  String? lastStallId;
  String? lastMenuId;
  String? stallPhotoPath;
  String? menuPhotoPath;

  @override
  Future<Map<String, Object?>?> getStallDetail(String stallId) async {
    lastStallId = stallId;
    if (stallId != _stallId) return null;
    return {
      'stall': {'id': _stallId, 'name': 'Kantin A'},
    };
  }

  @override
  Future<Map<String, Object?>?> getMenuDetail(String menuId) async {
    lastMenuId = menuId;
    if (menuId != _menuId) return null;
    return {
      'menu': {'id': _menuId, 'name': 'Nasi Goreng'},
    };
  }

  @override
  Future<String?> getStallPhotoPath(String stallId) async =>
      stallId == _stallId ? stallPhotoPath : null;

  @override
  Future<String?> getMenuPhotoPath(String menuId) async =>
      menuId == _menuId ? menuPhotoPath : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMediaStore {
  final files = <String, Uint8List>{};

  Future<Uint8List?> read(String objectPath) async => files[objectPath];
}
