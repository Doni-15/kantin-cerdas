class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isAccessTokenExpired => DateTime.now().isAfter(expiresAt);
}

/// Penyimpanan token. Token tidak boleh disimpan di UI/Widget.
///
/// Implementasi aktif: PersistentTokenStorage (local storage, tidak terenkripsi).
/// InMemoryTokenStorage hanya untuk test. Saat Backend nyata dipasang,
/// ganti dengan implementasi secure storage.
abstract interface class TokenStorage {
  Future<void> save(AuthTokens tokens);

  Future<AuthTokens?> read();

  Future<void> clear();
}
