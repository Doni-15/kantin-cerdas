import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/auth_tokens.dart';

abstract interface class TokenStorage {
  Future<AuthTokens?> read();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError(
    'tokenStorageProvider must be overridden via production or test overrides.',
  );
});
