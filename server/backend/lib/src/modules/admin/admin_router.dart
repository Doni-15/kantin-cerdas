import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/admin_service.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/admin_validator.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart'
    hide JsonMap;

/// Router modul Administrasi (`/v1/admin/*`).
///
/// Seluruh endpoint di dalam router ini dilindungi oleh `authGuard` +
/// `requireRoles({'admin'})`.
Router buildAdminRouter({
  required AuthService authService,
  required AdminService adminService,
}) {
  final router = Router();
  final adminGuard = Pipeline()
    .addMiddleware(authGuard(authService))
    .addMiddleware(requireRoles(const <String>{'admin'}))
    .addHandler;

  // 1. Ringkasan Dashboard Admin
  router.get(
    '/summary',
    adminGuard((Request request) async {
      final result = await adminService.getSummary(request.authActor);
      return _json(result);
    }),
  );

  // 2. Daftar Pengguna (Search + Keyset Pagination)
  router.get(
    '/users',
    adminGuard((Request request) async {
      final input = AdminValidator.validateListUsers(
        request.url.queryParameters,
      );
      final result = await adminService.listUsers(
        actor: request.authActor,
        input: input,
      );
      return _json(result);
    }),
  );

  // 3. Detail Pengguna
  router.get(
    '/users/<userId>',
    adminGuard((Request request) async {
      final targetUserId = AdminValidator.validateUserId(
        request.params['userId'],
      );
      final result = await adminService.getUser(
        actor: request.authActor,
        targetUserId: targetUserId,
      );
      if (result == null) {
        throw ApiException.notFound(
          'Pengguna tidak ditemukan.',
          'NOT_FOUND',
        );
      }
      return _json(result);
    }),
  );

  // 4. Ubah Status Akses Pengguna (Aktif / Nonaktif)
  router.post(
    '/users/<userId>/access',
    adminGuard((Request request) async {
      final body = await _readJsonObject(request);
      final input = AdminValidator.validateSetUserAccess(
        rawTargetUserId: request.params['userId'],
        idempotencyKeyHeader: request.headers['idempotency-key'],
        actorId: request.authActor.id,
        body: body,
      );
      final result = await adminService.setUserAccess(
        actor: request.authActor,
        input: input,
      );
      return _json(result);
    }),
  );

  // 5. Daftar Pengajuan Stan Kantin (Filter Status + Keyset Pagination)
  router.get(
    '/applications',
    adminGuard((Request request) async {
      final input = AdminValidator.validateListApplications(
        request.url.queryParameters,
      );
      final result = await adminService.listApplications(
        actor: request.authActor,
        input: input,
      );
      return _json(result);
    }),
  );

  // 6. Detail Pengajuan Stan Kantin
  router.get(
    '/applications/<applicationId>',
    adminGuard((Request request) async {
      final applicationId = AdminValidator.validateApplicationId(
        request.params['applicationId'],
      );
      final result = await adminService.getApplication(
        actor: request.authActor,
        applicationId: applicationId,
      );
      if (result == null) {
        throw ApiException.notFound(
          'Pengajuan stan tidak ditemukan.',
          'NOT_FOUND',
        );
      }
      return _json(result);
    }),
  );

  // 7. Review Pengajuan Stan Kantin (Approve / Reject)
  router.post(
    '/applications/<applicationId>/review',
    adminGuard((Request request) async {
      final body = await _readJsonObject(request);
      final input = AdminValidator.validateReviewApplication(
        rawApplicationId: request.params['applicationId'],
        idempotencyKeyHeader: request.headers['idempotency-key'],
        body: body,
      );
      final result = await adminService.reviewApplication(
        actor: request.authActor,
        input: input,
      );
      return _json(result);
    }),
  );

  return router;
}

Future<JsonMap> _readJsonObject(Request request) async {
  final String raw;
  try {
    raw = await request.readAsString();
  } 
  on FormatException {
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
  } 
  on FormatException {
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