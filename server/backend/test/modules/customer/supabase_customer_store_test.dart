import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/data/supabase_customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:test/test.dart';

import '../../config_test.dart' show validEnvironment;

const _customerId = '11111111-1111-1111-1111-111111111111';
const _menuId = '22222222-2222-2222-2222-222222222222';
const _attemptId = '33333333-3333-3333-3333-333333333333';

void main() {
  final config = AppConfig.fromEnv(EnvConfig.fromMap(validEnvironment()));
  final factory = SupabaseClientFactory(config: config.supabase);

  test('sends authenticated customer ID and decodes RPC JSON object', () async {
    late Uri requestUri;
    late Map<String, dynamic> requestBody;
    final client = MockClient((request) async {
      requestUri = request.url;
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'customer_id': _customerId, 'draft_version': 4}),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final store = SupabaseCustomerStore(factory, httpClient: client);

    final cart = await store.getCart(_customerId);

    expect(requestUri.path, '/rest/v1/rpc/kc_customer_get_cart');
    expect(requestBody, {'p_customer_id': _customerId});
    expect(cart, {'customer_id': _customerId, 'draft_version': 4});
  });

  test('sends customer and operation arguments to matching RPCs', () async {
    final requests = <({String function, Map<String, dynamic> body})>[];
    final client = MockClient((request) async {
      requests.add((
        function: request.url.path.split('/').last,
        body: jsonDecode(request.body) as Map<String, dynamic>,
      ));
      return http.Response(
        jsonEncode({'ok': true}),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final store = SupabaseCustomerStore(factory, httpClient: client);

    await store.addCartItem(
      _customerId,
      menuId: _menuId,
      quantity: 2,
      itemNote: 'tanpa sambal',
      replaceStall: true,
    );
    await store.checkout(
      _customerId,
      customerName: 'Customer',
      attemptId: _attemptId,
      expectedVersion: 4,
    );

    expect(
      requests.map((request) => request.function),
      ['kc_customer_add_cart_item', 'kc_customer_checkout'],
    );
    expect(
      requests.map((request) => request.body),
      [
        <String, dynamic>{
          'p_customer_id': _customerId,
          'p_menu_id': _menuId,
          'p_quantity': 2,
          'p_item_note': 'tanpa sambal',
          'p_replace_stall': true,
        },
        <String, dynamic>{
          'p_customer_id': _customerId,
          'p_customer_name': 'Customer',
          'p_attempt_id': _attemptId,
          'p_expected_version': 4,
        },
      ],
    );
  });

  test('maps allowlisted domain codes and hides PostgREST details', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/kc_customer_checkout')) {
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
        jsonEncode({'message': 'secret database connection details'}),
        500,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final store = SupabaseCustomerStore(factory, httpClient: client);

    await expectLater(
      store.checkout(
        _customerId,
        customerName: 'Customer',
        attemptId: _attemptId,
        expectedVersion: 4,
      ),
      throwsA(
        isA<CustomerFailure>()
            .having(
              (error) => error.code,
              'code',
              CustomerFailureCode.priceChanged,
            )
            .having((error) => error.message, 'message', isNull),
      ),
    );
    await expectLater(
      store.getCart(_customerId),
      throwsA(
        isA<CustomerFailure>()
            .having(
              (error) => error.code,
              'code',
              CustomerFailureCode.unavailable,
            )
            .having((error) => error.message, 'message', isNull),
      ),
    );
  });
}
