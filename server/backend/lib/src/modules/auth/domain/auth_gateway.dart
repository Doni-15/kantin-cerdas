export 'package:kantin_cerdas_backend/src/core/auth/auth_failure.dart';

enum AccountRole { customer, owner, admin }

class AuthAccount {
  const AuthAccount({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.suggestedName,
    this.googlePhoto,
    this.canManageCredentials = false,
  });

  final String id;
  final String email;
  final AccountRole role;
  final String? displayName;
  final String? suggestedName;
  final Uri? googlePhoto;
  final bool canManageCredentials;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.account,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final AuthAccount account;
}

const androidEmailVerificationRedirect =
    'id.kantincerdas.oauth://auth/verify-email';

abstract interface class AuthGateway {
  Future<void> register(
    String email,
    String password, {
    String? name,
    bool androidRedirect = true,
  });

  Future<void> resendRegistration(String email, {bool androidRedirect = true});
  Future<AuthSession> verifyRegistration(String email, String code);
  Future<AuthSession> verifyRegistrationLink(String tokenHash);
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> loginWithGoogle({
    required String idToken,
    required String googleAccessToken,
    String? nonce,
  });

  Future<AuthSession> exchangeGoogleCode(String code, String verifier);
  Future<AuthSession> refresh(String refreshToken);
  Future<AuthAccount> account(String accessToken);
  Future<AuthAccount> setDisplayName(AuthAccount actor, String displayName);
  Future<void> logout(String accessToken);
  Future<void> requestPasswordReset(String email);
  Future<void> checkPasswordResetLink(String tokenHash);
  Future<void> resetPassword(String email, String code, String password);
  Future<void> resetPasswordLink(String tokenHash, String password);

  Future<void> changeCredentials(
    String accessToken,
    String currentPassword, {
    String? email,
    String? password,
  });
  Future<void> confirmEmailChange(String tokenHash);
}
