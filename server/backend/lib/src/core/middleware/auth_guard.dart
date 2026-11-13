import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';

/// Kunci di `Request.context` tempat [AuthenticatedActor] disimpan oleh [authGuard].
const String authActorContextKey = 'kantin.auth.actor';

/// Akses actor terautentikasi dari [Request] yang sudah melewati [authGuard].
extension AuthRequestContext on Request {
  /// Actor jika request sudah melewati [authGuard], selain itu `null`.
  AuthenticatedActor? get authActorOrNull {
    final value = context[authActorContextKey];
    return value is AuthenticatedActor ? value : null;
  }

  /// Actor terautentikasi. Melempar [StateError] jika [authGuard] belum dipasang
  AuthenticatedActor get authActor {
    final actor = authActorOrNull;
    if (actor == null) {
      throw StateError(
        'authActor diakses pada route yang tidak dilindungi authGuard.',
      );
    }
    return actor;
  }
}

/// Mengambil token dari header `Authorization: Bearer <token>`.
/// Mengembalikan `null` bila header tidak ada atau formatnya salah. Dipakai
/// langsung oleh route yang sengaja toleran (mis. logout); route terproteksi
/// cukup memakai [authGuard].
String? extractBearerToken(Request request) {
  final header = request.headers['authorization']?.trim();
  if (header == null || header.isEmpty) return null;

  final parts = header.split(RegExp(r'\s+'));
  if (parts.length != 2 || parts.first.toLowerCase() != 'bearer') return null;

  final token = parts.last.trim();
  return token.isEmpty ? null : token;
}

/// Middleware autentikasi.
///
/// Alur:
/// 1. Ambil Bearer token dari header `Authorization`.
/// 2. Verifikasi token + muat profil otoritatif lewat
///    [AuthService.verifyAccessTokenAndGetUser] (sekaligus menolak akun nonaktif).
/// 3. Simpan [AuthenticatedActor] ke `request.context` (baca via `request.authActor`).
///
/// Semua kegagalan dilempar sebagai [ApiException] dan diubah menjadi response
/// oleh error boundary di `app_router.dart`:
/// - 401 `UNAUTHENTICATED`  : header tidak ada / profil tidak ditemukan
/// - 401 `INVALID_TOKEN`    : format header salah / token tidak valid
/// - 401 `TOKEN_EXPIRED`    : token kedaluwarsa
/// - 403 `ACCOUNT_DISABLED` : akun dinonaktifkan
/// - 429 / 503              : gangguan atau rate limit pada Supabase Auth
Middleware authGuard(AuthService authService) {
  return (Handler inner) {
    return (Request request) async {
      final token = _requireBearerToken(request);
      final actor = await authService.verifyAccessTokenAndGetUser(token);

      return inner(request.change(context: {authActorContextKey: actor}));
    };
  };
}

/// Middleware pembatas role. WAJIB dipasang SETELAH [authGuard].
///
/// Membandingkan `actor.role` dengan [allowedRoles] secara persis (case-sensitive).
/// Jika tidak cocok -> 403 `FORBIDDEN`.
Middleware requireRoles(Set<String> allowedRoles) {
  if (allowedRoles.isEmpty) {
    throw ArgumentError.value(
      allowedRoles,
      'allowedRoles',
      'Minimal satu role harus ditentukan.',
    );
  }
  final allowed = Set<String>.unmodifiable(allowedRoles);

  return (Handler inner) {
    return (Request request) {
      final actor = request.authActor;
      if (!allowed.contains(actor.role)) {
        throw ApiException.forbidden();
      }
      return inner(request);
    };
  };
}

String _requireBearerToken(Request request) {
  final header = request.headers['authorization'];
  if (header == null || header.trim().isEmpty) {
    throw ApiException.unauthenticated(
      'Token akses wajib disertakan.',
      'UNAUTHENTICATED',
    );
  }

  final token = extractBearerToken(request);
  if (token == null) {
    throw ApiException.unauthenticated(
      'Format header Authorization tidak valid. Gunakan "Bearer <token>".',
      'INVALID_TOKEN',
    );
  }
  return token;
}
