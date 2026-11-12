import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_validator.dart';

/// Pesan netral untuk `POST /auth/password-reset` (anti-enumerasi akun).
const String _passwordResetNeutralMessage = 'Jika email terdaftar, instruksi reset password telah dikirim.';

/// Router modul Autentikasi & Sesi.
///
/// Path di sini RELATIF terhadap titik mount. Pasang di `app_router.dart`:
/// ```dart
/// router.mount('$prefix/auth/', buildAuthRouter(authService).call);
/// ```
///
/// Endpoint:
/// - POST `/register`         publik
/// - POST '/availability'     publik (check apakah email sudah terdaftar) 
/// - POST `/login`            publik
/// - POST `/refresh`          publik (memakai refresh_token di body)
/// - POST `/logout`           publik-toleran (idempoten, token opsional)
/// - POST `/password-reset`   publik (respons selalu netral)
/// - GET  `/me`               butuh Bearer token
/// - POST `/change-password`  butuh Bearer token
/// - PUT  `/profile/avatar`   butuh Bearer token + header Idempotency-Key
///
/// Semua [ApiException] dari validator/service ditangani error boundary di
/// `app_router.dart`, sehingga handler di sini tidak perlu try/catch.
Router buildAuthRouter(AuthService authService, StorageConfig storage) {
  final router = Router();
  final guard = authGuard(authService);

  // --- Publik --------------------------------------------------------------
  router.post('/availability', (Request request) async {
    final body = await _readJsonObject(request);
    final input = AuthValidator.validateAvailability(body);
    final result = await authService.checkAvailability(
      email: input.email,
      username: input.username,
    );
    return _json(result);
  });

  router.post('/register', (Request request) async {
    final body = await _readJsonObject(request);
    final input = AuthValidator.validateRegister(body, storage);
    final user = await authService.register(input);
    return _json(user, statusCode: 201);
  });

  router.post('/login', (Request request) async {
    final body = await _readJsonObject(request);
    final input = AuthValidator.validateLogin(body);
    final result = await authService.login(input);
    return _json(result);
  });

  router.post('/refresh', (Request request) async {
    final body = await _readJsonObject(request);
    final refreshToken = AuthValidator.validateRefreshToken(body);
    final result = await authService.refreshSession(refreshToken);
    return _json(result);
  });

  // Sengaja di luar authGuard: token yang sudah kedaluwarsa tetap boleh
  // "logout" tanpa error (idempoten). Service menerima token null/kosong.
  router.post('/logout', (Request request) async {
    await authService.logout(extractBearerToken(request));
    return _noContent();
  });

  router.post('/password-reset', (Request request) async {
    final body = await _readJsonObject(request);
    final email = AuthValidator.validatePasswordResetEmail(body);
    await authService.requestPasswordReset(email);
    return _json(const <String, Object?>{
      'message': _passwordResetNeutralMessage,
    });
  });

  // --- Terproteksi (authGuard) ---------------------------------------------
  router.get(
    '/me',
    guard((Request request) {
      return _json(request.authActor.toUserJson());
    }),
  );

  router.post(
    '/change-password',
    guard((Request request) async {
      final body = await _readJsonObject(request);
      final input = AuthValidator.validateChangePassword(body);
      await authService.changePassword(request.authActor, input);
      return _noContent();
    }),
  );

  router.put(
    '/profile/avatar',
    guard((Request request) async {
      final body = await _readJsonObject(request);
      final input = AuthValidator.validateAvatarUpdate(
        idempotencyKeyHeader: request.headers['idempotency-key'],
        actorId: request.authActor.id,
        publicBaseUrl: storage.publicBaseUrl,
        body: body,
      );
      final result = await authService.updateProfileAvatar(
        request.authActor,
        input,
      );
      return _json(result);
    }),
  );

  return router;
}

/// Membaca body request sebagai objek JSON.
///
/// JSON rusak melempar [FormatException] -> dipetakan error boundary menjadi
/// 400 `INVALID_JSON`. Body kosong atau bukan objek ditolak di sini.
Future<Map<String, Object?>> _readJsonObject(Request request) async {
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
  return Map<String, Object?>.from(decoded);
}

Response _json(Object? payload, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(payload),
    headers: const {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  );
}

Response _noContent() {
  return Response(204, headers: const {'cache-control': 'no-store'});
}