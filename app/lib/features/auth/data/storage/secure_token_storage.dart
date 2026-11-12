import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/storage/secure_storage_provider.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? defaultSecureStorage;

  static const _storageKey = 'kantin_cerdas.auth.tokens.v1';
  final FlutterSecureStorage _storage;
  Future<void> _pending = Future<void>.value();

  @override
  Future<AuthTokens?> read() {
    return _enqueue<AuthTokens?>(() async {
      final value = await _storage.read(key: _storageKey);

      if (value == null) return null;

      return _decode(value);
    });
  }

  @override
  Future<void> save(AuthTokens tokens) {
    return _enqueue<void>(() async {
      _validateTokens(tokens);

      final value = jsonEncode({
        'access_token': tokens.accessToken,
        'refresh_token': tokens.refreshToken,
        'expires_at': tokens.expiresAt?.toUtc().toIso8601String(),
      });

      await _storage.write(key: _storageKey, value: value);
    });
  }

  @override
  Future<void> clear() {
    return _enqueue<void>(() => _storage.delete(key: _storageKey));
  }

  AuthTokens _decode(String value) {
    final Object? data;

    try {
      data = jsonDecode(value);
    } on FormatException {
      throw const DataParsingException('Stored session contains invalid JSON.');
    }

    if (data case {
      'access_token': final String accessToken,
      'refresh_token': final String? refreshToken,
      'expires_at': final String? expiry,
    }) {
      final DateTime? expiresAt;
      if (expiry == null) {
        expiresAt = null;
      } else {
        expiresAt = parseStrictUtcDateTime(expiry, fieldName: 'expires_at');
      }

      final tokens = AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      _validateTokens(tokens);

      return tokens;
    }

    throw const DataParsingException('Stored session has invalid fields.');
  }

  void _validateTokens(AuthTokens tokens) {
    final refreshToken = tokens.refreshToken;

    if (tokens.accessToken.trim().isEmpty ||
        (refreshToken != null && refreshToken.trim().isEmpty)) {
      throw const DataParsingException('Session contains empty tokens.');
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pending.then<T>((_) => operation());

    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );

    return result;
  }
}
