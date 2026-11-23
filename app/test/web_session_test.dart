import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';

void main() {
  test(
    'web sessions survive a fresh repository and disappear after confirmed logout',
    () async {
      var browserCookie = false;
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body.containsKey('refresh_token'), false);
        switch (request.url.path) {
          case '/v1/auth/web/login':
            browserCookie = true;
            return _ok(_session);
          case '/v1/auth/web/refresh':
            expect(body, isEmpty);
            return _ok(browserCookie ? _session : null);
          case '/v1/auth/web/logout':
            expect(body, {'account_id': 'web-account'});
            browserCookie = false;
            return _ok(null);
          default:
            throw StateError('Unexpected web session path');
        }
      });
      addTearDown(client.close);
      final installed = _repo(client, MemorySessionStore());
      expect(await installed.restore(), isNull);
      expect(
        (await installed.login(
          'doni@example.test',
          'password',
        )).tokens.refreshToken,
        isNull,
      );

      final reloadedStore = MemorySessionStore();
      final reloaded = _repo(client, reloadedStore);
      expect((await reloaded.restore())?.account.id, 'web-account');
      expect(
        (await reloadedStore.read())?.toJson().containsKey('refresh_token'),
        false,
      );
      await reloaded.clearSession();
      expect(await reloadedStore.read(), isNull);
      expect(await _repo(client, MemorySessionStore()).restore(), isNull);
    },
  );

  test(
    'a failed web logout leaves the session available for a retry',
    () async {
      final store = MemorySessionStore();
      final client = MockClient(
        (request) async => request.url.path.endsWith('/web/logout')
            ? http.Response('', 503)
            : _ok(_session),
      );
      addTearDown(client.close);
      final repo = _repo(client, store);
      await repo.restore();
      await expectLater(repo.clearSession(), throwsA(isA<AuthException>()));
      expect((await store.read())?.ownerId, 'web-account');
    },
  );

  test(
    'web logout waits for an in-flight refresh before clearing credentials',
    () async {
      final store = MemorySessionStore();
      final started = Completer<void>();
      final finish = Completer<http.Response>();
      final calls = <String>[];
      final client = MockClient((request) {
        calls.add(request.url.path);
        if (request.url.path.endsWith('/web/refresh')) {
          started.complete();
          return finish.future;
        }
        return Future.value(_ok(null));
      });
      addTearDown(client.close);
      final repo = _repo(client, store);
      final refresh = expectLater(
        repo.restore(),
        throwsA(isA<AuthException>()),
      );
      await started.future;
      final logout = repo.clearSession();
      expect(calls, ['/v1/auth/web/refresh']);
      finish.complete(_ok(_session));
      await refresh;
      await logout;
      expect(calls, ['/v1/auth/web/refresh', '/v1/auth/web/logout']);
      expect(await store.read(), isNull);
    },
  );
}

AuthRepository _repo(http.Client client, SessionStore store) => AuthRepository(
  client: client,
  store: store,
  baseUrl: 'https://app.example.test',
  cookieSessions: true,
);

http.Response _ok(Object? data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);

const _session = {
  'access_token': 'browser-access',
  'expires_at': '2100-01-01T00:00:00Z',
  'account': {
    'id': 'web-account',
    'email': 'doni@example.test',
    'role': 'customer',
    'display_name': 'Akun web',
  },
};
