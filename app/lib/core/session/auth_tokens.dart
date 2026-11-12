class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  /// Tanpa waktu kedaluwarsa, keabsahan tetap harus diperiksa ke server.
  bool isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !expiry.toUtc().isAfter(now.toUtc());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthTokens &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.expiresAt?.toUtc() == expiresAt?.toUtc());

  @override
  int get hashCode =>
      Object.hash(accessToken, refreshToken, expiresAt?.toUtc());
}
