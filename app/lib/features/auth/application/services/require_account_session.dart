import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

AuthSession requireAccountSession(AuthSession? session, String accountId) {
  if (session == null || session.account.id != accountId) {
    throw const AuthException('INVALID_SESSION', 'Silakan masuk kembali.');
  }
  return session;
}
