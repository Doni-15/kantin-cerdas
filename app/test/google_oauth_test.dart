import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_browser_io.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth_protocol.dart';
import 'package:kantin_cerdas/features/auth/data/session/auth_session_store.dart';

const _project = 'https://abcdefghijklmnopqrst.supabase.co';
final _callback = Uri.parse(mobileGoogleRedirect);

Uri _response(Uri start) {
  final back = Uri.parse(start.queryParameters['redirect_to']!);
  return back.replace(
    queryParameters: {...back.queryParameters, 'code': 'test-auth-code'},
  );
}

void main() {
  test(
    'Google receives a fresh challenge backed by a local verifier',
    () async {
      final challenges = <String>[];
      final states = <String>[];
      final flow = GoogleOAuthFlow(
        supabaseUrl: _project,
        browser:
            ({required authorize, required state, required cancelled}) async {
              final start = authorize(_callback);
              expect(start.path, '/auth/v1/authorize');
              expect(start.origin, _project);
              expect(start.queryParameters['provider'], 'google');
              expect(start.queryParameters['code_challenge_method'], 's256');
              challenges.add(start.queryParameters['code_challenge']!);
              states.add(state);
              return _response(start);
            },
      );
      final first = await flow.requestCode();
      final second = await flow.requestCode();
      String challengeOf(String verifier) => base64UrlEncode(
        sha256.convert(ascii.encode(verifier)).bytes,
      ).replaceAll('=', '');
      expect(first.code, 'test-auth-code');
      expect(challenges, [
        challengeOf(first.verifier),
        challengeOf(second.verifier),
      ]);
      expect(states.toSet(), hasLength(2));
      expect({first.verifier, second.verifier}, hasLength(2));
      expect(states, isNot(contains(first.verifier)));
    },
  );

  test('Google rejects an unrelated or ambiguous callback', () async {
    for (final change in <Uri Function(Uri)>[
      (uri) => uri.replace(host: 'wrong.example.test'),
      (uri) => uri.replace(path: '/wrong-path'),
      (uri) => uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          googleCallbackState: 'wrong-state',
        },
      ),
      (uri) => uri.replace(query: '${uri.query}&code=second'),
      (uri) => uri.replace(query: '${uri.query}&kc_state=second'),
      (uri) => uri.replace(query: 'kc_state=%FF&code=test-auth-code'),
      (uri) => uri.replace(fragment: 'access_token=implicit-token'),
      (uri) => uri.replace(fragment: 'error=server_error&sb='),
    ]) {
      final flow = GoogleOAuthFlow(
        supabaseUrl: _project,
        browser:
            ({required authorize, required state, required cancelled}) async =>
                change(_response(authorize(_callback))),
      );
      await expectLater(flow.requestCode(), throwsA(isA<AuthException>()));
    }
  });

  test(
    'cancellation ends an active browser flow without an auth code',
    () async {
      final opened = Completer<void>();
      final flow = GoogleOAuthFlow(
        supabaseUrl: _project,
        browser:
            ({required authorize, required state, required cancelled}) async {
              final start = authorize(_callback);
              opened.complete();
              await cancelled;
              return _response(start);
            },
      );
      final operation = expectLater(
        flow.requestCode(),
        throwsA(same(googleCancelled)),
      );
      await opened.future;
      flow.cancel();
      await operation;
    },
  );

  test(
    'desktop loopback uses an ephemeral port and ignores unrelated callbacks',
    () async {
      final result = await openLoopbackGoogleBrowser(
        state: 'desktop-state',
        cancelled: Completer<void>().future,
        authorize: (callback) => callback,
        launch: (callback) async {
          expect(callback.host, '127.0.0.1');
          expect(callback.port, isPositive);
          final unrelated = await http.get(
            callback.replace(
              queryParameters: {googleCallbackState: 'unrelated'},
            ),
          );
          expect(unrelated.statusCode, 404);
          final malformed = await http.get(
            callback.replace(query: 'kc_state=%FF&code=malformed'),
          );
          expect(malformed.statusCode, 404);
          final accepted = await http.get(
            callback.replace(
              queryParameters: {
                googleCallbackState: 'desktop-state',
                'code': 'test-desktop-code',
              },
            ),
          );
          expect(accepted.statusCode, 200);
          expect(accepted.headers['cache-control'], 'no-store');
          expect(accepted.body, isNot(contains('test-desktop-code')));
        },
      );
      expect(result.queryParameters['code'], 'test-desktop-code');
    },
  );

  test(
    'parseGoogleProjectUrl enforces HTTPS Cloud URL in production and allows loopback in local debug mode',
    () {
      expect(parseGoogleProjectUrl(_project)?.toString(), _project);
      expect(
        parseGoogleProjectUrl('http://127.0.0.1:18590', allowLocalHttp: false),
        isNull,
      );
      expect(
        parseGoogleProjectUrl(
          'http://127.0.0.1:18590',
          allowLocalHttp: true,
        )?.toString(),
        'http://127.0.0.1:18590',
      );
      expect(
        parseGoogleProjectUrl(
          'http://10.0.2.2:18590',
          allowLocalHttp: true,
        )?.toString(),
        'http://10.0.2.2:18590',
      );
      expect(
        parseGoogleProjectUrl(
          'http://192.168.1.10:18590',
          allowLocalHttp: true,
        ),
        isNull,
      );
    },
  );

  test(
    'resolveGoogleSupabaseUrl discovers backend project, normalizes emulator loopback, and detects project mismatch',
    () async {
      var serverUrl = _project;
      var serverEnabled = true;
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/auth/google/config');
        if (!serverEnabled) {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'GOOGLE_DISABLED',
                'message': 'Login Google belum tersedia.',
              },
            }),
            503,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'google_enabled': true, 'supabase_url': serverUrl},
          }),
          200,
        );
      });
      addTearDown(client.close);

      final cloudRepo = AuthRepository(
        client: client,
        store: MemorySessionStore(),
        baseUrl: 'https://api.example.test',
      );

      // 1. Dynamically discovers SUPABASE_URL when omitted at compile time.
      expect(await cloudRepo.resolveGoogleSupabaseUrl(), _project);

      // 2. Succeeds when Flutter and backend point to the same project.
      expect(
        await cloudRepo.resolveGoogleSupabaseUrl(configuredUrl: _project),
        _project,
      );

      // 3. Rejects mismatched Supabase project between Flutter and backend.
      await expectLater(
        cloudRepo.resolveGoogleSupabaseUrl(
          configuredUrl: 'https://zzzzzzzzzzzzzzzzzzzz.supabase.co',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'GOOGLE_CONFIG_MISMATCH',
          ),
        ),
      );

      // 4. Rejects malformed client SUPABASE_URL before opening browser.
      await expectLater(
        cloudRepo.resolveGoogleSupabaseUrl(
          configuredUrl: 'http://invalid.example.test',
        ),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'GOOGLE_CONFIG'),
        ),
      );

      // 5. Propagates backend 503 GOOGLE_DISABLED clearly.
      serverEnabled = false;
      await expectLater(
        cloudRepo.resolveGoogleSupabaseUrl(),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'GOOGLE_DISABLED'),
        ),
      );

      // 6. Normalizes 127.0.0.1 to 10.0.2.2 when running on Android emulator in debug mode.
      serverEnabled = true;
      serverUrl = 'http://127.0.0.1:18590';
      final emulatorRepo = AuthRepository(
        client: client,
        store: MemorySessionStore(),
        baseUrl: 'http://10.0.2.2:18580',
        allowLocalHttp: true,
      );
      final resolvedLocal = await emulatorRepo.resolveGoogleSupabaseUrl();
      expect(resolvedLocal, 'http://10.0.2.2:18590');

      final flow = GoogleOAuthFlow(
        supabaseUrl: '',
        allowLocalHttp: true,
        browser:
            ({required authorize, required state, required cancelled}) async {
              final start = authorize(_callback);
              expect(start.origin, 'http://10.0.2.2:18590');
              return _response(start);
            },
      );
      final exchanged = await flow.requestCode(supabaseUrl: resolvedLocal);
      expect(exchanged.code, 'test-auth-code');
    },
  );
}
