import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart'
    as controller;
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/data/session/auth_session_store.dart';

class _TestFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> entries = <String, String>{};
  Object? readFailure;
  Object? writeFailure;
  Object? deleteFailure;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (readFailure case final Object error) throw error;
    return entries[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (writeFailure case final Object error) throw error;
    if (value == null) {
      entries.remove(key);
    } else {
      entries[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (deleteFailure case final Object error) throw error;
    entries.remove(key);
  }
}

void main() {
  test(
    'storage key format preserves exact kc.session.v1.<apiBase> namespace',
    () {
      for (final apiBase in [
        '',
        'https://api.example.test',
        'http://10.0.2.2:8080',
        'https://kantin.example.test/api',
      ]) {
        expect(authSessionStorageKey(apiBase), 'kc.session.v1.$apiBase');
      }
    },
  );

  test(
    'MemorySessionStore supports write, read, and clear lifecycle',
    () async {
      final store = MemorySessionStore();
      expect(store, isA<SessionStore>());
      expect(store, isA<controller.MemorySessionStore>());
      expect(await store.read(), isNull);

      final tokens = SessionTokens.fromJson({
        'access_token': 'fixture-access-token',
        'refresh_token': 'fixture-refresh-token',
        'expires_at': '2100-01-01T00:00:00Z',
        'account_id': 'fixture-account-id',
      });
      await store.write(tokens);

      final restored = await store.read();
      expect(restored?.accessToken, 'fixture-access-token');
      expect(restored?.refreshToken, 'fixture-refresh-token');
      expect(restored?.expiresAt, DateTime.utc(2100, 1, 1));
      expect(restored?.ownerId, 'fixture-account-id');

      await store.clear();
      expect(await store.read(), isNull);
    },
  );

  test('SecureSessionStore writes exact JSON format, reads back legacy/current '
      'sessions, and clears by key', () async {
    final backend = _TestFlutterSecureStorage();
    const key = 'kc.session.v1.https://api.example.test';
    final store = SecureSessionStore(backend, key);

    expect(store, isA<SessionStore>());
    expect(store, isA<controller.SecureSessionStore>());
    expect(await store.read(), isNull);

    final tokens = SessionTokens.fromJson({
      'access_token': 'fixture-access-1',
      'refresh_token': 'fixture-refresh-1',
      'expires_at': '2100-05-10T12:30:00.000Z',
      'account_id': 'fixture-owner-1',
    });
    await store.write(tokens);

    // Verify exact persisted JSON schema compatibility for existing users.
    expect(backend.entries.keys, [key]);
    final rawJson = jsonDecode(backend.entries[key]!) as Map<String, dynamic>;
    expect(rawJson, {
      'access_token': 'fixture-access-1',
      'refresh_token': 'fixture-refresh-1',
      'expires_at': '2100-05-10T12:30:00.000Z',
      'account_id': 'fixture-owner-1',
    });

    final readBack = await store.read();
    expect(readBack?.accessToken, 'fixture-access-1');
    expect(readBack?.refreshToken, 'fixture-refresh-1');
    expect(readBack?.expiresAt, DateTime.utc(2100, 5, 10, 12, 30));
    expect(readBack?.ownerId, 'fixture-owner-1');

    // Verify legacy persisted payload without optional account_id is still read.
    backend.entries[key] = jsonEncode({
      'access_token': 'legacy-access',
      'refresh_token': 'legacy-refresh',
      'expires_at': '2100-01-01T00:00:00.000Z',
    });
    final legacyRead = await store.read();
    expect(legacyRead?.accessToken, 'legacy-access');
    expect(legacyRead?.refreshToken, 'legacy-refresh');
    expect(legacyRead?.ownerId, isNull);

    await store.clear();
    expect(backend.entries, isEmpty);
    expect(await store.read(), isNull);
  });

  test('SecureSessionStore maps corrupted JSON and platform read errors to '
      'SESSION_STORAGE_READ without leaking raw details', () async {
    final backend = _TestFlutterSecureStorage();
    const key = 'kc.session.v1.https://api.example.test';
    final store = SecureSessionStore(backend, key);

    for (final corrupted in [
      'not-valid-json',
      '[]',
      '"plain-string"',
      '12345',
      jsonEncode({
        'refresh_token': 'missing-access',
        'expires_at': '2100-01-01T00:00:00Z',
      }),
      jsonEncode({
        'access_token': 'a',
        'refresh_token': 'b',
        'expires_at': 'not-a-date',
      }),
      jsonEncode({
        'access_token': '',
        'refresh_token': 'b',
        'expires_at': '2100-01-01T00:00:00Z',
      }),
    ]) {
      backend.entries[key] = corrupted;
      await expectLater(
        store.read(),
        throwsA(
          isA<AuthException>()
              .having((e) => e.code, 'code', 'SESSION_STORAGE_READ')
              .having(
                (e) => e.message,
                'message',
                'Sesi tersimpan tidak dapat dibaca. Coba lagi atau masuk ulang.',
              ),
        ),
      );
    }

    backend.readFailure = PlatformException(
      code: 'KeyStoreException',
      message: 'internal android keystore failure secret',
    );
    await expectLater(
      store.read(),
      throwsA(
        isA<AuthException>()
            .having((e) => e.code, 'code', 'SESSION_STORAGE_READ')
            .having(
              (e) => e.message,
              'message',
              'Sesi tersimpan tidak dapat dibaca. Coba lagi atau masuk ulang.',
            ),
      ),
    );
  });

  test('SecureSessionStore maps write and clear failures to exact '
      'SESSION_STORAGE_WRITE and SESSION_STORAGE_CLEAR exceptions', () async {
    final backend = _TestFlutterSecureStorage();
    const key = 'kc.session.v1.https://api.example.test';
    final store = SecureSessionStore(backend, key);
    final tokens = SessionTokens.fromJson({
      'access_token': 'fixture-access',
      'refresh_token': 'fixture-refresh',
      'expires_at': '2100-01-01T00:00:00Z',
    });

    backend.writeFailure = PlatformException(
      code: 'StorageWriteError',
      message: 'disk full or keystore locked',
    );
    await expectLater(
      store.write(tokens),
      throwsA(
        isA<AuthException>()
            .having((e) => e.code, 'code', 'SESSION_STORAGE_WRITE')
            .having(
              (e) => e.message,
              'message',
              'Sesi tidak dapat disimpan di perangkat.',
            ),
      ),
    );

    backend.deleteFailure = PlatformException(
      code: 'StorageDeleteError',
      message: 'keystore delete failure',
    );
    await expectLater(
      store.clear(),
      throwsA(
        isA<AuthException>()
            .having((e) => e.code, 'code', 'SESSION_STORAGE_CLEAR')
            .having(
              (e) => e.message,
              'message',
              'Sesi tidak dapat dihapus. Coba lagi.',
            ),
      ),
    );
  });

  test(
    'auth_session_store and auth_controller have no circular dependency',
    () {
      final storeSource = File(
        'lib/features/auth/data/session/auth_session_store.dart',
      ).readAsStringSync();
      final controllerSource = File(
        'lib/features/auth/application/auth_controller.dart',
      ).readAsStringSync();

      expect(storeSource, isNot(contains('auth_controller.dart')));
      expect(controllerSource, isNot(contains('class SecureSessionStore')));
      expect(controllerSource, isNot(contains('class MemorySessionStore')));
    },
  );
}
