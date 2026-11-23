import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:kantin_cerdas_backend/src/core/config/supabase_config.dart';

/// Membuat Supabase client berdasarkan konteks akses.
///
/// Server client menggunakan secret key.
/// User client menggunakan publishable key dan JWT pengguna.
class SupabaseClientFactory {
  const SupabaseClientFactory({required this._config});

  final SupabaseConfig _config;

  /// Client untuk operasi internal yang membutuhkan hak akses server.
  ///
  /// Client ini dapat digunakan sebagai singleton selama lifecycle server.
  SupabaseClient createServerClient({http.Client? httpClient}) {
    return SupabaseClient(
      _config.url.toString(),
      _config.secretKey,
      httpClient: httpClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      postgrestOptions: _postgrestOptions,
      storageOptions: _storageOptions,
    );
  }

  /// Client untuk operasi autentikasi pengguna.
  ///
  /// Gunakan instance terpisah untuk setiap operasi Auth.
  /// Client tidak menyimpan session secara persisten dan tidak melakukan
  /// refresh token otomatis.
  SupabaseClient createAuthClient({
    http.Client? httpClient,
    GotrueAsyncStorage? pkceStorage,
  }) {
    return SupabaseClient(
      _config.url.toString(),
      _config.publishableKey,
      httpClient: httpClient,
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: pkceStorage == null
            ? AuthFlowType.implicit
            : AuthFlowType.pkce,
        pkceAsyncStorage: pkceStorage,
      ),
      postgrestOptions: _postgrestOptions,
      storageOptions: _storageOptions,
    );
  }

  /// Client untuk operasi atas nama pengguna yang sedang terautentikasi.
  ///
  /// Buat client ini untuk konteks request pengguna dan dispose setelah
  /// request selesai. JWT harus sudah diverifikasi oleh lapisan autentikasi.
  SupabaseClient createUserClient({required String accessToken}) {
    final normalizedToken = accessToken.trim();

    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Access token tidak boleh kosong.',
      );
    }

    return SupabaseClient(
      _config.url.toString(),
      _config.publishableKey,
      accessToken: () async => normalizedToken,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      postgrestOptions: _postgrestOptions,
      storageOptions: _storageOptions,
    );
  }

  PostgrestClientOptions get _postgrestOptions {
    return PostgrestClientOptions(
      requestTimeout: _config.requestTimeout,
      retryEnabled: _config.maxRetries > 0,
      retryCount: _config.maxRetries,
    );
  }

  StorageClientOptions get _storageOptions {
    return StorageClientOptions(retryAttempts: _config.maxRetries);
  }
}
