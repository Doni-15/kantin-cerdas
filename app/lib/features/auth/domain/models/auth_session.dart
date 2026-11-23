import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_json.dart';

class SessionTokens {
  SessionTokens.fromJson(
    Map<String, dynamic> json, {
    String? ownerId,
    bool cookieSession = false,
  }) : accessToken = requiredAuthText(json, 'access_token'),
       refreshToken = cookieSession
           ? null
           : requiredAuthText(json, 'refresh_token'),
       expiresAt = DateTime.parse(requiredAuthText(json, 'expires_at')).toUtc(),
       ownerId = ownerId ?? optionalAuthText(json, 'account_id');

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String? ownerId;

  Map<String, Object> toJson() => {
    'access_token': accessToken,
    'refresh_token': ?refreshToken,
    'expires_at': expiresAt.toIso8601String(),
    'account_id': ?ownerId,
  };
}

class AuthSession {
  const AuthSession(this.tokens, this.account);
  final SessionTokens tokens;
  final AuthAccount account;
}
