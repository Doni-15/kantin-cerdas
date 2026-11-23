import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/data/session/session_store.dart';

String authSessionStorageKey(String apiBase) => 'kc.session.v1.$apiBase';

class MemorySessionStore implements SessionStore {
  SessionTokens? _tokens;

  @override
  Future<SessionTokens?> read() async => _tokens;

  @override
  Future<void> write(SessionTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}

class SecureSessionStore implements SessionStore {
  const SecureSessionStore(this._storage, this._key);

  final FlutterSecureStorage _storage;
  final String _key;

  @override
  Future<SessionTokens?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) throw const FormatException();
      return SessionTokens.fromJson(data);
    } catch (_) {
      throw const AuthException(
        'SESSION_STORAGE_READ',
        'Sesi tersimpan tidak dapat dibaca. Coba lagi atau masuk ulang.',
      );
    }
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(tokens.toJson()));
    } catch (_) {
      throw const AuthException(
        'SESSION_STORAGE_WRITE',
        'Sesi tidak dapat disimpan di perangkat.',
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      throw const AuthException(
        'SESSION_STORAGE_CLEAR',
        'Sesi tidak dapat dihapus. Coba lagi.',
      );
    }
  }
}
