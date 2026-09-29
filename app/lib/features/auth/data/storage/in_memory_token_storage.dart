import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';

class InMemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<AuthTokens?> read() async {
    return _tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}
