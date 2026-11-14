import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_validator.dart';

Handler buildCustomerOrdersRouter({
  required AuthService authService,
  required CustomerOrdersService customerOrdersService,
}) {
  final router = Router();

  router.post('/', (Request request) async {
    final body = await _readJsonObject(request);
    final input = CustomerOrdersValidator.validateCreateOrder(
      body,
      idempotencyKeyHeader: request.headers['idempotency-key'],
    );
    final result = await customerOrdersService.createOrder(
      request.authActor,
      input,
    );
    return _json(result, statusCode: 201);
  });

  router.get('/', (Request request) async {
    final input = CustomerOrdersValidator.validateListQuery(
      Map<String, String>.from(request.url.queryParameters),
    );
    final result = await customerOrdersService.getOrders(
      request.authActor,
      input,
    );
    return _json(result);
  });

  router.get('/<orderId>', (Request request, String orderId) async {
    final validatedId = CustomerOrdersValidator.validateOrderId(orderId);
    final result = await customerOrdersService.getOrderDetail(
      request.authActor,
      validatedId,
    );
    return _json(result);
  });

  router.post('/<orderId>/cancel', (Request request, String orderId) async {
    final validatedId = CustomerOrdersValidator.validateOrderId(orderId);
    final body = await _readJsonObject(request);
    final input = CustomerOrdersValidator.validateCancelBody(
      body,
      idempotencyKeyHeader: request.headers['idempotency-key'],
    );
    final result = await customerOrdersService.cancelOrder(
      request.authActor,
      validatedId,
      input,
    );
    return _json(result);
  });

  return const Pipeline()
      .addMiddleware(authGuard(authService))
      .addMiddleware(requireRoles(const <String>{'customer', 'owner'}))
      .addHandler(router.call);
}

Future<JsonMap> _readJsonObject(Request request) async {
  final String raw;
  try {
    raw = await request.readAsString();
  } on FormatException {
    throw ApiException.badRequest(
      'Body harus berupa teks UTF-8 yang valid.',
      code: 'INVALID_JSON',
    );
  }
  if (raw.trim().isEmpty) {
    throw ApiException.badRequest(
      'Body JSON wajib diisi.',
      code: 'INVALID_JSON',
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw ApiException.badRequest(
      'Format body JSON tidak valid.',
      code: 'INVALID_JSON',
    );
  }
  if (decoded is! Map<Object?, Object?>) {
    throw ApiException.badRequest(
      'Body harus berupa objek JSON.',
      code: 'INVALID_JSON',
    );
  }
  return JsonMap.from(decoded);
}

Response _json(Object? payload, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(payload),
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  );
}
