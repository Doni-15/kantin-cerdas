import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/canteen_submissions/canteen_submissions_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/canteen_submissions/canteen_submissions_validator.dart';

/// Router modul Pengajuan Kantin (`/v1/customer/canteen-applications`).
///
/// Endpoint:
/// - `GET  /me` : Membaca pengajuan terbaru milik pemohon (`customer` atau `owner`).
///                Mengembalikan `404 APPLICATION_NOT_FOUND` jika belum ada pengajuan.
/// - `POST /`   : Mengirim pengajuan baru atau pengajuan ulang setelah ditolak (`customer`).
Handler buildCanteenSubmissionsRouter({
  required AuthService authService,
  required CanteenSubmissionsService canteenSubmissionsService,
}) {
  final router = Router();

  router.get('/me', (Request request) async {
    final result = await canteenSubmissionsService.getMyApplication(
      request.authActor,
    );
    if (result == null) {
      throw ApiException.notFound(
        'Belum ada pengajuan stan untuk akun ini.',
        'APPLICATION_NOT_FOUND',
      );
    }
    return _json(result);
  });

  router.post('/', (Request request) async {
    final body = await _readJsonObject(request);
    final input = CanteenSubmissionsValidator.validateSubmit(
      body,
      idempotencyKeyHeader: request.headers['idempotency-key'],
    );
    final result = await canteenSubmissionsService.submitApplication(
      request.authActor,
      input,
    );
    return _json(result, statusCode: 201);
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
  if (decoded is! Map) {
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
