import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';

/// Menyimpan token di local storage agar session bertahan setelah aplikasi ditutup.
///
/// Catatan: shared_preferences TIDAK terenkripsi. Cukup untuk tahap dummy;
/// saat Backend nyata dipasang, ganti dengan secure storage.
class PersistentTokenStorage implements TokenStorage {
  const PersistentTokenStorage(this._storage);

  final LocalStorage _storage;

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.writeJson(StorageKeys.authTokens, {
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'expires_at': tokens.expiresAt.toIso8601String(),
    });
  }

  @override
  Future<AuthTokens?> read() async {
    final json = _storage.readJson(StorageKeys.authTokens);

    if (json == null) {
      return null;
    }

    try {
      return AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await _storage.remove(StorageKeys.authTokens);
  }
}
