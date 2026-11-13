import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_validator.dart';

Handler buildCustomerOrdersRouter({
  required AuthService authService,
  required CustomerOrdersService customerOrdersService,
}) {
  final router = Router();

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
    await customerOrdersService.cancelOrder(
      request.authActor,
      validatedId,
      input,
    );
    final result = await customerOrdersService.getOrderDetail(
      request.authActor,
      validatedId,
    );
    return _json(result);
  });

  return const Pipeline()
      .addMiddleware(authGuard(authService))
      .addHandler(router.call);
}

Future<Map<String, dynamic>> _readJsonObject(Request request) async {
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
  if (decoded is! Map) {
    throw ApiException.badRequest(
      'Body harus berupa objek JSON.',
      code: 'INVALID_JSON',
    );
  }
  return Map<String, dynamic>.from(decoded);
}

Response _json(Object? payload) {
  return Response.ok(
    jsonEncode(payload),
    headers: const {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  );
}
