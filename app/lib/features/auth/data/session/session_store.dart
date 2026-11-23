import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

abstract interface class SessionStore {
  Future<SessionTokens?> read();
  Future<void> write(SessionTokens tokens);
  Future<void> clear();
}

typedef SessionLock = Future<T> Function<T>(Future<T> Function() operation);
