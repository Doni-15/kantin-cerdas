import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:kantin_cerdas_backend/src/app/bootstrap.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/core/media/avatar_image.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/supabase_auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/supabase_avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/data/supabase_catalog_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'config_test.dart' show validEnvironment;

const _email = 'pelanggan@example.test';
const _password = ' frasa sandi contoh ';
const _userId = '0be785ca-5d09-4ad0-9fa0-a6180dff01c1';
const _headers = {'content-type': 'application/json'};
const _webOrigin = 'https://app.example.test';

void main() {
  Handler appWith(
    Future<http.Response> Function(http.Request) respond, {
    Duration timeout = const Duration(seconds: 1),
    String? origin = _webOrigin,
    String? emailLinkHost,
    SignupFailureReporter? onSignupFailure,
    bool googleEnabled = true,
    bool hasPhoto = true,
    String sessionStatus = 'active',
    bool canRecover = true,
  }) {
    final config = AppConfig.fromEnv(
      EnvConfig.fromMap(
        validEnvironment(
          overrides: {
            'RATE_LIMIT_ENABLED': 'false',
            'LOG_REQUEST_ENABLED': 'false',
            'AUTH_WEB_ORIGIN': ?origin,
            'AUTH_EMAIL_LINK_HOST': ?emailLinkHost,
            'AUTH_GOOGLE_ENABLED': '$googleEnabled',
          },
        ),
      ),
    );
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/rest/v1/rpc/kc_auth_session_status':
          expect(request.headers['apikey'], 'sb_secret_test');
          expect(jsonDecode(request.body), {
            'p_user_id': _userId,
            'p_session_id': _sessionId,
          });
          return http.Response(
            jsonEncode(sessionStatus),
            200,
            headers: _headers,
            request: request,
          );
        case '/rest/v1/rpc/kc_auth_can_recover_password':
          expect(request.headers['apikey'], 'sb_secret_test');
          expect(jsonDecode(request.body), {'p_email': _email});
          return http.Response(
            jsonEncode(canRecover),
            200,
            headers: _headers,
            request: request,
          );
      }
      if (request.method == 'HEAD' &&
          request.url.path.startsWith('/storage/v1/object/')) {
        return http.Response('', hasPhoto ? 200 : 404);
      }
      return respond(request);
    });
    addTearDown(client.close);
    return buildAppHandler(
      config,
      catalogStore: SupabaseCatalogStore(
        SupabaseClientFactory(config: config.supabase),
        httpClient: client,
      ),
      avatarStore: SupabaseAvatarStore(
        SupabaseClientFactory(config: config.supabase),
        timeout: timeout,
        client: client,
      ),
      authGateway: SupabaseAuthGateway(
        SupabaseAuthDataSource(
          clientFactory: SupabaseClientFactory(config: config.supabase),
          httpClient: client,
          requestTimeout: timeout,
        ),
        config: config.auth,
        onSignupFailure: onSignupFailure,
      ),
    );
  }

  test('recovery link preflight only consults the private RPC', () async {
    final hash = List.filled(64, 'a').join();
    var pending = true;
    final app = appWith((request) async {
      expect(request.url.path, '/rest/v1/rpc/kc_auth_recovery_link_pending');
      expect(request.headers['apikey'], 'sb_secret_test');
      expect(jsonDecode(request.body), {
        'p_token_hash': hash,
        'p_ttl_seconds': 3600,
      });
      return http.Response(
        jsonEncode(pending),
        200,
        headers: _headers,
        request: request,
      );
    });
    Future<Response> check() =>
        _send(app, 'POST', '/password-reset/check', body: {'token_hash': hash});
    expect((await check()).statusCode, 200);
    pending = false;
    await _expectError(await check(), 400, 'INVALID_CODE');
  });

  group('catalog API', () {
    const id = '10000000-0000-0000-0000-000000000001';
    const next = '20000000-0000-0000-0000-000000000002';
    const after = '00000000-0000-0000-0000-000000000001';
    const item = {'id': id, 'name': 'Dapur Nusantara'};

    test('checks the bearer and pages with the last included ID', () async {
      var calls = 0;
      final app = appWith((request) async {
        if (++calls == 1) {
          expect(request.url.path, '/auth/v1/user');
          expect(request.headers['authorization'], 'Bearer $_accessToken');
          return _json(200, _user(metadata: {'display_name': 'Doni'}));
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/rest/v1/rpc/kc_catalog_menu');
        expect(request.headers['apikey'], 'sb_secret_test');
        expect(jsonDecode(request.body), {
          'p_query': 'Nasi & ayam',
          'p_after': after,
          'p_stall_id': id,
          'p_limit': 2,
        });
        return http.Response(
          jsonEncode([
            {'id': id, 'item': item},
            {
              'id': next,
              'item': {'id': next, 'name': 'Stan lain'},
            },
          ]),
          200,
          headers: _headers,
          request: request,
        );
      });
      final response = await _sendCatalog(
        app,
        '/menu?q=Nasi%20%26%20ayam&limit=1&cursor=$after&stall_id=$id',
      );
      expect(response.headers['cache-control'], 'no-store');
      expect(await _data(response, status: 200), {
        'items': [item],
        'next_cursor': id,
      });
      expect(calls, 2);
    });

    test('requires a bearer before calling any provider', () async {
      final app = appWith((_) async => fail('Must not contact the provider'));
      await _expectError(
        await _sendCatalog(app, '/stalls', bearer: null),
        401,
        'INVALID_SESSION',
      );
    });

    test('rejects invalid and ambiguous query parameters', () async {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/user');
        return _json(200, _user(metadata: {'display_name': 'Doni'}));
      });
      for (final query in [
        'q=a&q=b',
        'q=%00',
        'limit=41',
        'cursor=..',
        'stall_id=$id',
      ]) {
        await _expectError(
          await _sendCatalog(app, '/stalls?$query'),
          400,
          'INVALID_CATALOG_QUERY',
        );
      }
    });

    test('returns a safe 404 for an unlisted or missing stall', () async {
      final app = appWith((request) async {
        if (request.url.path == '/auth/v1/user') {
          return _json(200, _user(metadata: {'display_name': 'Doni'}));
        }
        expect(request.url.path, '/rest/v1/rpc/kc_catalog_stalls');
        expect(jsonDecode(request.body), {
          'p_query': '',
          'p_after': null,
          'p_stall_id': id,
          'p_limit': 1,
        });
        return http.Response('[]', 200, headers: _headers, request: request);
      });
      await _expectError(
        await _sendCatalog(app, '/stalls/$id'),
        404,
        'STALL_NOT_FOUND',
      );
    });

    test('hides provider details and rejects inconsistent rows', () async {
      final app = appWith((request) async {
        if (request.url.path == '/auth/v1/user') {
          return _json(200, _user(metadata: {'display_name': 'Doni'}));
        }
        return http.Response(
          jsonEncode([
            {'id': next, 'item': item, 'other': 'provider-internal-detail'},
          ]),
          200,
          headers: _headers,
          request: request,
        );
      });
      await _expectError(
        await _sendCatalog(app, '/stalls'),
        503,
        'CATALOG_UNAVAILABLE',
      );
    });
  });

  test(
    'login submits the password grant and preserves password spaces',
    () async {
      final app = appWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/v1/token');
        expect(request.url.queryParameters, {'grant_type': 'password'});
        expect(request.headers['apikey'], 'sb_publishable_test');
        final data = jsonDecode(request.body) as Map<String, Object?>;
        expect(data['email'], _email);
        expect(data['password'], _password);
        return _json(200, _session());
      });
      final response = await _send(
        app,
        'POST',
        '/login',
        body: {'email': ' Pelanggan@Example.Test ', 'password': _password},
      );
      final body = await _data(response, status: 200);
      expect(response.headers['cache-control'], 'no-store');
      expect(body['access_token'], _accessToken);
      expect(body['expires_at'], '2033-05-18T03:33:20.000Z');
      expect(body['account'], containsPair('role', 'customer'));
      expect(body['account'], containsPair('profile_complete', false));
    },
  );

  test(
    'registration has a neutral response and never returns a session',
    () async {
      for (final duplicate in [false, true]) {
        final app = appWith((request) async {
          expect(request.url.path, '/auth/v1/signup');
          final data = jsonDecode(request.body) as Map<String, Object?>;
          expect(data['data'], {'registration_name': 'Nama Pelanggan'});
          return duplicate
              ? _providerError(422, 'user_already_exists')
              : _json(200, _session());
        });
        final data = await _data(
          await _send(
            app,
            'POST',
            '/register',
            body: {
              'email': _email,
              'password': _password,
              'role': 'admin',
              'display_name': 'Nama Pelanggan',
            },
          ),
          status: 202,
        );
        expect(data, {'next': 'verify_email'});
      }
    },
  );

  test(
    'email verification exchanges the correct code type for a session',
    () async {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/verify');
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body, containsPair('type', 'signup'));
        expect(body, containsPair('token', '012345'));
        return _json(200, _session());
      });
      final body = await _data(
        await _send(
          app,
          'POST',
          '/verify-email',
          body: {'email': _email, 'code': '012345'},
        ),
        status: 200,
      );
      expect(body['access_token'], _accessToken);
    },
  );

  test(
    'signup confirms an ambiguous conflict before acknowledging it',
    () async {
      for (final existing in [true, false]) {
        final requests = <String>[];
        final app = appWith((request) async {
          final path = request.url.path;
          requests.add(path);
          if (path == '/auth/v1/signup') {
            return _json(500, {
              'code': 'unexpected_failure',
              'message': 'Database error saving new user',
            });
          }
          expect(path, '/rest/v1/rpc/kc_auth_registration_exists');
          expect(request.headers['apikey'], 'sb_secret_test');
          expect(jsonDecode(request.body), {'p_email': _email});
          return http.Response(
            jsonEncode(existing),
            200,
            headers: _headers,
            request: request,
          );
        });
        final response = await _send(
          app,
          'POST',
          '/register',
          body: {'email': _email, 'password': _password},
        );
        if (existing) {
          expect(await _data(response, status: 202), {'next': 'verify_email'});
        } else {
          await _expectError(response, 503, 'AUTH_UNAVAILABLE');
        }
        expect(requests, [
          '/auth/v1/signup',
          '/rest/v1/rpc/kc_auth_registration_exists',
        ]);
      }
    },
  );

  test(
    'signup maps provider errors without exposing provider details',
    () async {
      for (final (upstreamCode, status, code) in [
        (
          'email_address_not_authorized',
          422,
          'SIGNUP_EMAIL_DELIVERY_RESTRICTED',
        ),
        ('email_address_invalid', 422, 'SIGNUP_EMAIL_INVALID'),
        ('validation_failed', 400, 'INVALID_INPUT'),
      ]) {
        final diagnostics = <(String, int?)>[];
        final app = appWith(
          (_) async => _providerError(400, upstreamCode),
          onSignupFailure: (code, status) => diagnostics.add((code, status)),
        );
        await _expectError(
          await _send(
            app,
            'POST',
            '/register',
            body: {'email': _email, 'password': _password},
          ),
          status,
          code,
        );
        expect(diagnostics, [(upstreamCode, 400)]);
      }
    },
  );

  test(
    'signup and resend use the Android email redirect only for non-browser requests',
    () async {
      const host = 'auth.example.test';
      final redirects = <(String, String?)>[];
      final app = appWith((request) async {
        redirects.add((
          request.url.path,
          request.url.queryParameters['redirect_to'],
        ));
        if (request.url.path.endsWith('/signup')) {
          return _json(200, _session());
        }
        expect(jsonDecode(request.body), containsPair('type', 'signup'));
        expect(jsonDecode(request.body), containsPair('email', _email));
        return _json(200, {});
      }, emailLinkHost: host);

      await _data(
        await _send(
          app,
          'POST',
          '/register',
          body: {
            'email': _email,
            'password': _password,
            'redirect_to': 'https://override.test/',
          },
        ),
        status: 202,
      );
      await _data(
        await _send(
          app,
          'POST',
          '/verify-email/resend',
          body: {'email': _email, 'redirect_to': 'https://override.test/'},
        ),
        status: 202,
      );
      await _data(
        await app(
          Request(
            'POST',
            Uri.parse('$_webOrigin/v1/auth/register'),
            headers: {
              'host': 'app.example.test',
              ..._headers,
              'origin': _webOrigin,
              'sec-fetch-site': 'same-origin',
            },
            body: jsonEncode({
              'email': _email,
              'password': _password,
              'redirect_to': 'https://override.test/',
            }),
          ),
        ),
        status: 202,
      );
      await _data(
        await app(
          Request(
            'POST',
            Uri.parse('$_webOrigin/v1/auth/verify-email/resend'),
            headers: {
              'host': 'app.example.test',
              ..._headers,
              'origin': _webOrigin,
              'sec-fetch-site': 'same-origin',
            },
            body: jsonEncode({
              'email': _email,
              'redirect_to': 'https://override.test/',
            }),
          ),
        ),
        status: 202,
      );
      expect(redirects, [
        ('/auth/v1/signup', 'id.kantincerdas.oauth://auth/verify-email'),
        ('/auth/v1/resend', 'id.kantincerdas.oauth://auth/verify-email'),
        ('/auth/v1/signup', null),
        ('/auth/v1/resend', null),
      ]);
    },
  );

  test('signup redacts unknown provider diagnostics', () async {
    final diagnostics = <(String, int?)>[];
    final app = appWith(
      (_) async => _providerError(503, 'provider-internal-detail'),
      onSignupFailure: (code, status) => diagnostics.add((code, status)),
    );
    await _expectError(
      await _send(
        app,
        'POST',
        '/register',
        body: {'email': _email, 'password': _password},
      ),
      503,
      'AUTH_UNAVAILABLE',
    );
    expect(diagnostics, [('provider_error', 503)]);
  });

  test(
    'resend returns the same acknowledgement for an unknown email',
    () async {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/resend');
        final data = jsonDecode(request.body) as Map<String, Object?>;
        expect(data, containsPair('email', _email));
        expect(data, containsPair('type', 'signup'));
        return _providerError(404, 'user_not_found');
      });
      final body = await _data(
        await _send(
          app,
          'POST',
          '/verify-email/resend',
          body: {'email': _email},
        ),
        status: 202,
      );
      expect(body, {'next': 'verify_email'});
    },
  );

  test('resend does not acknowledge provider delivery errors', () async {
    for (final (status, providerCode, appCode) in [
      (429, 'over_email_send_rate_limit', 'AUTH_RATE_LIMITED'),
      (503, 'unexpected_failure', 'AUTH_UNAVAILABLE'),
    ]) {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/resend');
        return _providerError(status, providerCode);
      });
      await _expectError(
        await _send(
          app,
          'POST',
          '/verify-email/resend',
          body: {'email': _email},
        ),
        status,
        appCode,
      );
    }
  });

  test('rejects a returned session without verified email', () async {
    final app = appWith((_) async => _json(200, _session(confirmed: false)));
    await _expectError(
      await _send(
        app,
        'POST',
        '/login',
        body: {'email': _email, 'password': _password},
      ),
      403,
      'EMAIL_NOT_VERIFIED',
    );
  });

  test('rejects mismatched claims before contacting the provider', () async {
    final app = appWith(
      (_) async => fail('Provider must not receive this token'),
    );
    for (final claim in [
      {'iss': 'https://other.example.test/auth/v1'},
      {'aud': 'other'},
      {'exp': 0},
      {'role': 'service_role'},
      {'session_id': 'invalid'},
    ]) {
      await _expectError(
        await _send(app, 'GET', '/me', bearer: _jwt(overridden: claim)),
        401,
        'INVALID_SESSION',
      );
    }
  });

  test(
    'blocks a revoked session and an inactive account from private routes',
    () async {
      for (final (state, status, code) in [
        ('invalid', 401, 'INVALID_SESSION'),
        ('inactive', 403, 'ACCOUNT_INACTIVE'),
      ]) {
        final app = appWith((request) async {
          expect(request.url.path, '/auth/v1/user');
          return _json(200, _user());
        }, sessionStatus: state);
        await _expectError(
          await _send(app, 'GET', '/me', bearer: _accessToken),
          status,
          code,
        );
        await _expectError(await _sendCatalog(app, '/stalls'), status, code);
      }
    },
  );

  test(
    'does not complete a profile or open catalog without a stored photo',
    () async {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/user');
        return _json(200, _user(metadata: {'display_name': 'Doni'}));
      }, hasPhoto: false);
      await _expectError(
        await _send(
          app,
          'PUT',
          '/profile',
          bearer: _accessToken,
          body: {'display_name': 'Doni'},
        ),
        409,
        'PROFILE_INCOMPLETE',
      );
      await _expectError(
        await _sendCatalog(app, '/stalls'),
        409,
        'PROFILE_INCOMPLETE',
      );
    },
  );

  test('Google opt-in rejects exchanges before any provider call', () async {
    final app = appWith(
      (_) async => fail('Provider must not receive this code'),
      googleEnabled: false,
    );
    await _expectError(
      await _send(app, 'GET', '/google/config'),
      503,
      'GOOGLE_DISABLED',
    );
    await _expectError(
      await _send(
        app,
        'POST',
        '/google/exchange',
        body: {'code': 'fixture-code', 'code_verifier': 'a' * 43},
      ),
      503,
      'GOOGLE_DISABLED',
    );
  });

  test(
    'Google config endpoint exposes the backend Supabase URL and exchange rejects mismatched client Supabase URLs',
    () async {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/token');
        return _json(200, {
          ..._session(),
          'user': _user(
            metadata: {
              'full_name': 'Nama Metadata Google',
              'picture': 'https://lh3.googleusercontent.com/meta-avatar',
            },
            identities: [_identity('google')],
          ),
        });
      });

      final configRes = await _send(app, 'GET', '/google/config');
      expect(configRes.headers['cache-control'], 'no-store');
      expect(await _data(configRes, status: 200), {
        'google_enabled': true,
        'supabase_url': 'https://exampleprojectref001.supabase.co',
      });

      await _expectError(
        await _send(
          app,
          'POST',
          '/google/exchange',
          body: {
            'code': 'fixture-code',
            'code_verifier': 'a' * 43,
            'supabase_url': 'https://otherproject12345678.supabase.co',
          },
        ),
        400,
        'INVALID_INPUT',
      );

      final matched = await _data(
        await _send(
          app,
          'POST',
          '/google/exchange',
          body: {
            'code': 'fixture-code',
            'code_verifier': 'a' * 43,
            'supabase_url': 'https://exampleprojectref001.supabase.co',
          },
        ),
        status: 200,
      );
      expect(
        matched['account'],
        containsPair('suggested_name', 'Nama Metadata Google'),
      );
      expect(
        matched['account'],
        containsPair(
          'google_photo',
          'https://lh3.googleusercontent.com/meta-avatar',
        ),
      );
    },
  );

  test(
    'Google-only account cannot request local password reset or changes',
    () async {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/user');
        return _json(200, _user(identities: [_identity('google')]));
      }, canRecover: false);
      expect(
        await _data(
          await _send(app, 'POST', '/password-reset', body: {'email': _email}),
          status: 202,
        ),
        {'next': 'check_email'},
      );
      await _expectError(
        await _send(
          app,
          'POST',
          '/account/password',
          bearer: _accessToken,
          body: {'password': _password, 'new_password': 'new secure password'},
        ),
        403,
        'PROVIDER_MANAGED',
      );
    },
  );

  test(
    'email and password updates prove the current password with Supabase',
    () async {
      for (final (path, field, value) in [
        ('/account/email', 'email', 'new@example.test'),
        ('/account/password', 'password', 'new secure password'),
      ]) {
        final user = _user(identities: [_identity('email')]);
        final methods = <String>[];
        final app = appWith((request) async {
          methods.add('${request.method} ${request.url.path}');
          if (request.method == 'GET') return _json(200, user);
          switch (request.url.path) {
            case '/auth/v1/token':
              expect(
                jsonDecode(request.body),
                containsPair('password', _password),
              );
              return _json(200, {..._session(), 'user': user});
            case '/auth/v1/user':
              expect(request.method, 'PUT');
              expect(jsonDecode(request.body), containsPair(field, value));
              return _json(200, user);
            case '/auth/v1/logout':
              expect(request.url.queryParameters, {'scope': 'local'});
              return http.Response('', 204);
            default:
              fail('Unexpected operation');
          }
        });
        final res = await _send(
          app,
          'POST',
          path,
          bearer: _accessToken,
          body: {
            'password': _password,
            (field == 'password' ? 'new_password' : field): value,
          },
        );
        expect(res.statusCode, field == 'password' ? 200 : 202);
        expect(methods, [
          'GET /auth/v1/user',
          'POST /auth/v1/token',
          'PUT /auth/v1/user',
          'POST /auth/v1/logout',
        ]);
      }
    },
  );

  test('email link recovery uses a typed one-time hash', () async {
    var first = true;
    final app = appWith((request) async {
      switch (request.url.path) {
        case '/auth/v1/verify':
          final payload = jsonDecode(request.body);
          expect(payload, containsPair('type', 'recovery'));
          expect(payload, containsPair('token_hash', 'c' * 64));
          expect(payload, isNot(contains('email')));
          if (!first) return _providerError(403, 'otp_expired');
          first = false;
          return _json(200, _session());
        case '/auth/v1/user':
          expect(request.method, 'PUT');
          return _json(200, _user());
        case '/auth/v1/logout':
          return http.Response('', 204);
        default:
          fail('Unexpected operation');
      }
    });
    final body = {'token_hash': 'c' * 64, 'password': _password};
    expect(
      (await _send(
        app,
        'POST',
        '/password-reset/confirm',
        body: body,
      )).statusCode,
      200,
    );
    await _expectError(
      await _send(app, 'POST', '/password-reset/confirm', body: body),
      400,
      'INVALID_CODE',
    );
  });

  test(
    'imports the verified Google photo without replacing a saved avatar',
    () async {
      const url = 'https://lh3.googleusercontent.com/example-avatar';
      final source = image.encodePng(image.Image(width: 12, height: 12));
      Uint8List? saved;
      var downloads = 0;
      final app = appWith((request) async {
        if (request.url.path == '/auth/v1/user') {
          return _json(
            200,
            _user(
              identities: [
                _identity('google', {'picture': url}),
              ],
            ),
          );
        }
        if (request.url.toString() == url) {
          downloads++;
          expect(request.followRedirects, isFalse);
          expect(request.headers['authorization'], isNull);
          return http.Response.bytes(
            source,
            200,
            headers: {'content-type': 'image/png'},
          );
        }
        expect(
          request.url.path,
          endsWith('/kantin-avatars/$_userId/avatar.jpg'),
        );
        if (request.method == 'POST') {
          expect(request.headers['x-upsert'], 'false');
          final upload = latin1.decode(request.bodyBytes);
          final start = upload.indexOf('\xff\xd8');
          final end = upload.lastIndexOf('\xff\xd9');
          expect(start, greaterThanOrEqualTo(0));
          expect(end, greaterThan(start));
          final jpeg = Uint8List.sublistView(request.bodyBytes, start, end + 2);
          saved = jpeg;
          expect(image.decodeJpg(jpeg)?.width, 12);
          return _json(409, {'statusCode': '409', 'message': 'Already saved'});
        }
        final existing = saved;
        return existing == null
            ? _json(404, {
                'statusCode': '404',
                'code': 'NoSuchKey',
                'message': 'Object not found',
              })
            : http.Response.bytes(
                existing,
                200,
                headers: {'content-type': 'image/jpeg'},
              );
      });
      for (var attempt = 0; attempt < 2; attempt++) {
        final result = await _send(
          app,
          'POST',
          '/profile/photo/google',
          bearer: _accessToken,
        );
        expect(result.statusCode, 200);
        expect(result.headers['content-type'], 'image/jpeg');
        expect(await result.read().expand((chunk) => chunk).toList(), saved);
      }
      expect(downloads, 1);
    },
  );

  test('Google uses the ID token grant and offers a suggested name', () async {
    final app = appWith((request) async {
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'id_token');
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body, containsPair('provider', 'google'));
      expect(body, containsPair('id_token', 'test-google-id'));
      expect(body, containsPair('access_token', 'test-google-access'));
      expect(body, containsPair('nonce', 'test-nonce'));
      return _json(200, {
        ..._session(),
        'user': _user(
          identities: [
            _identity('google', {'full_name': 'Nama Google'}),
          ],
        ),
      });
    });
    final body = await _data(
      await _send(
        app,
        'POST',
        '/google',
        body: {
          'id_token': 'test-google-id',
          'google_access_token': 'test-google-access',
          'nonce': 'test-nonce',
        },
      ),
      status: 200,
    );
    expect(body['account'], containsPair('suggested_name', 'Nama Google'));
    expect(body['account'], containsPair('profile_complete', false));
  });

  test(
    'refresh sends an explicit token and returns the rotated pair',
    () async {
      final app = appWith((request) async {
        expect(request.url.queryParameters['grant_type'], 'refresh_token');
        expect(jsonDecode(request.body), {'refresh_token': 'previous-refresh'});
        return _json(200, _session());
      });
      final body = await _data(
        await _send(
          app,
          'POST',
          '/refresh',
          body: {'refresh_token': 'previous-refresh'},
        ),
        status: 200,
      );
      expect(body['refresh_token'], 'rotated-refresh');
    },
  );

  test(
    'refresh distinguishes a rejected session from provider failure',
    () async {
      for (final (status, upstreamCode, clientStatus, clientCode) in [
        (400, 'refresh_token_not_found', 401, 'INVALID_SESSION'),
        (429, 'over_request_rate_limit', 429, 'AUTH_RATE_LIMITED'),
        (503, 'unexpected_failure', 503, 'AUTH_UNAVAILABLE'),
      ]) {
        final app = appWith((_) async => _providerError(status, upstreamCode));
        await _expectError(
          await _send(
            app,
            'POST',
            '/refresh',
            body: {'refresh_token': 'test-refresh'},
          ),
          clientStatus,
          clientCode,
        );
      }
    },
  );

  test('upstream timeout leaves the session recoverable', () async {
    final blocked = Completer<http.Response>();
    final app = appWith(
      (_) => blocked.future,
      timeout: const Duration(milliseconds: 30),
    );
    try {
      await _expectError(
        await _send(app, 'GET', '/me', bearer: _accessToken),
        503,
        'AUTH_UNAVAILABLE',
      );
    } finally {
      blocked.complete(_json(200, _user()));
    }
  });

  test('a profile update can only target the verified account', () async {
    final paths = <String>[];
    final app = appWith((request) async {
      paths.add(request.url.path);
      if (request.method == 'GET') {
        expect(request.headers['authorization'], 'Bearer $_accessToken');
        return _json(200, _user(metadata: {'kantin_role': 'admin'}));
      }
      expect(request.method, 'PUT');
      expect(request.headers['apikey'], 'sb_secret_test');
      expect(jsonDecode(request.body), {
        'user_metadata': {'display_name': 'Doni'},
      });
      return _json(
        200,
        _user(metadata: {'display_name': 'Doni', 'kantin_role': 'admin'}),
      );
    });
    final data = await _data(
      await _send(
        app,
        'PUT',
        '/profile',
        bearer: _accessToken,
        body: {
          'id': 'different-account',
          'role': 'admin',
          'display_name': '  Doni  ',
        },
      ),
      status: 200,
    );
    expect(paths, ['/auth/v1/user', '/auth/v1/admin/users/$_userId']);
    expect(data, containsPair('id', _userId));
    expect(data, containsPair('role', 'customer'));
    expect(data, containsPair('profile_complete', true));
  });

  test('logout asks Supabase to revoke just the current session', () async {
    final app = appWith((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/v1/logout');
      expect(request.url.queryParameters, {'scope': 'local'});
      expect(request.headers['authorization'], 'Bearer $_accessToken');
      return http.Response('', 204);
    });
    final response = await _send(app, 'POST', '/logout', bearer: _accessToken);
    expect(response.statusCode, 200);
    expect(jsonDecode(await response.readAsString()), {
      'success': true,
      'data': null,
    });
  });

  test(
    'reset is neutral for an unknown address and never returns tokens',
    () async {
      final app = appWith((request) async {
        switch (request.url.path) {
          case '/auth/v1/recover':
            return _providerError(404, 'user_not_found');
          case '/auth/v1/verify':
            expect(jsonDecode(request.body), containsPair('type', 'recovery'));
            return _json(200, _session());
          case '/auth/v1/user':
            expect(request.method, 'PUT');
            expect(request.headers['authorization'], 'Bearer $_accessToken');
            expect(
              jsonDecode(request.body),
              containsPair('password', _password),
            );
            return _json(200, _user());
          case '/auth/v1/logout':
            expect(request.url.queryParameters, {'scope': 'local'});
            return http.Response('', 204);
          default:
            throw StateError('Unexpected provider path');
        }
      });
      expect(
        await _data(
          await _send(app, 'POST', '/password-reset', body: {'email': _email}),
          status: 202,
        ),
        {'next': 'check_email'},
      );
      final response = await _send(
        app,
        'POST',
        '/password-reset/confirm',
        body: {'email': _email, 'code': '012345', 'password': _password},
      );
      expect(response.statusCode, 200);
      expect(jsonDecode(await response.readAsString()), {
        'success': true,
        'data': null,
      });
    },
  );

  test(
    'avatar upload normalizes a PNG and only uses the verified account path',
    () async {
      var uploaded = false;
      Uint8List? stored;
      final app = appWith((request) async {
        if (request.url.path == '/auth/v1/user') {
          expect(request.headers['authorization'], 'Bearer $_accessToken');
          return _json(200, _user());
        }
        expect(request.headers['apikey'], 'sb_secret_test');
        if (request.method == 'POST') {
          expect(
            request.url.path,
            endsWith('/kantin-avatars/$_userId/avatar.jpg'),
          );
          expect(request.headers['x-upsert'], 'true');
          uploaded = true;
          return _json(200, {'Key': 'kantin-avatars/$_userId/avatar.jpg'});
        }
        if (request.method == 'GET') {
          expect(
            request.url.path,
            endsWith('/kantin-avatars/$_userId/avatar.jpg'),
          );
          final current = stored;
          if (current == null) {
            return _json(404, {
              'statusCode': '404',
              'message': 'Object not found',
            });
          }
          return http.Response.bytes(
            current,
            200,
            headers: {'content-type': 'image/jpeg'},
          );
        }
        fail('Unexpected storage operation');
      });
      final absent = await _sendPhoto(app, 'GET');
      expect(absent.statusCode, 204);
      final upload = await _sendPhoto(
        app,
        'PUT',
        body: image.encodePng(image.Image(width: 900, height: 450)),
      );
      expect(upload.statusCode, 200);
      expect(upload.headers['content-type'], 'image/jpeg');
      expect(upload.headers['cache-control'], 'no-store');
      expect(uploaded, true);
      stored = Uint8List.fromList(
        await upload.read().expand((chunk) => chunk).toList(),
      );
      final decoded = image.decodeJpg(stored);
      expect(decoded?.width, 512);
      expect(decoded?.height, 256);
      final photo = await _sendPhoto(app, 'GET');
      expect(photo.statusCode, 200);
      expect(await photo.read().expand((chunk) => chunk).toList(), stored);
      expect((await _sendPhoto(app, 'DELETE')).statusCode, 404);
      expect((await _sendPhoto(app, 'GET')).statusCode, 200);
    },
  );

  test(
    'JPEG, PNG, and WebP avatars produce plain single-frame JPEGs',
    () async {
      final original = image.Image(width: 25, height: 42);
      for (final (mediaType, bytes) in [
        ('image/jpeg', image.encodeJpg(original)),
        ('image/png', image.encodePng(original)),
        ('image/webp', image.encodeWebP(original)),
      ]) {
        final normalized = await normalizeAvatar(bytes, mediaType);
        expect(normalized, isNotNull, reason: mediaType);
        final result = image.decodeJpg(normalized!);
        expect(result?.width, 25);
        expect(result?.height, 42);
      }
    },
  );

  test(
    'a missing avatar bucket is a service error, not an empty photo',
    () async {
      final app = appWith((request) async {
        if (request.url.path == '/auth/v1/user') return _json(200, _user());
        return _json(404, {
          'statusCode': '404',
          'code': 'NoSuchBucket',
          'message': 'Bucket not found',
        });
      });
      await _expectError(await _sendPhoto(app, 'GET'), 503, 'AUTH_UNAVAILABLE');
    },
  );

  test(
    'avatar rejects missing authorization, fake image bytes, and over-limit uploads',
    () async {
      var verified = 0;
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/user');
        verified++;
        return _json(200, _user());
      });
      await _expectError(
        await _sendPhoto(app, 'GET', bearer: null),
        401,
        'INVALID_SESSION',
      );
      expect(verified, 0);
      final fake = await _sendPhoto(
        app,
        'PUT',
        body: Uint8List.fromList([1, 3, 5]),
      );
      await _expectError(fake, 422, 'INVALID_PROFILE_PHOTO');
      final big = await _sendPhoto(
        app,
        'PUT',
        body: Uint8List(2 * 1024 * 1024 + 1),
      );
      await _expectError(big, 413, 'REQUEST_BODY_TOO_LARGE');
      expect(verified, 2);
    },
  );

  test('animated photos are declined', () async {
    final frames = image.Image(width: 20, height: 20);
    frames.addFrame(image.Image(width: 20, height: 20));
    final normalized = await normalizeAvatar(
      image.encodeWebP(frames),
      'image/webp',
    );
    expect(normalized, isNull);
  });

  test(
    'parallel Google exchanges keep each verifier scoped to its request',
    () async {
      final first = List.filled(43, 'a').join();
      final second = List.filled(43, 'b').join();
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/token');
        expect(request.url.queryParameters, {'grant_type': 'pkce'});
        expect(request.headers['apikey'], 'sb_publishable_test');
        final data = jsonDecode(request.body) as Map<String, Object?>;
        final code = data['auth_code'];
        expect(data['code_verifier'], code == 'code-first' ? first : second);
        return _json(200, {
          ..._session(metadata: {'full_name': 'Pengguna Google'}),
          'provider_token': 'provider-token-not-for-client',
          'user': {
            ..._user(metadata: {'full_name': 'Pengguna Google'}),
            'identities': [
              {
                'id': _userId,
                'user_id': _userId,
                'provider': 'google',
                'created_at': '2026-01-01T00:00:00Z',
                'identity_data': {
                  'email': _email,
                  'full_name': 'Pengguna Google',
                },
              },
            ],
          },
        });
      });
      final responses = await Future.wait([
        _send(
          app,
          'POST',
          '/google/exchange',
          body: {'code': 'code-first', 'code_verifier': first},
        ),
        _send(
          app,
          'POST',
          '/google/exchange',
          body: {'code': 'code-second', 'code_verifier': second},
        ),
      ]);
      for (final response in responses) {
        expect(response.headers['cache-control'], 'no-store');
        final data = await _data(response, status: 200);
        expect(data['access_token'], _accessToken);
        expect(
          data['account'],
          containsPair('suggested_name', 'Pengguna Google'),
        );
        expect(data.containsKey('provider_token'), false);
      }
    },
  );

  test('Google exchange rejects codes without a Google identity', () async {
    final app = appWith((_) async => _json(200, _session()));
    await _expectError(
      await _send(
        app,
        'POST',
        '/google/exchange',
        body: {
          'code': 'code-without-google',
          'code_verifier': List.filled(43, 'a').join(),
        },
      ),
      400,
      'INVALID_CODE',
    );
  });

  test(
    'both Google grants accept linked identities on the verified principal',
    () async {
      for (final codeExchange in [true, false]) {
        final upstreamPaths = <String>[];
        final app = appWith((request) async {
          upstreamPaths.add(request.url.path);
          expect(request.url.path, '/auth/v1/token');
          return _json(200, {
            ..._session(),
            'user': {
              ..._user(
                metadata: {'display_name': 'Nama profil lama'},
                identities: [_identity('email'), _identity('google')],
              ),
              'app_metadata': {'kantin_role': 'owner'},
            },
          });
        });
        final response = await _send(
          app,
          'POST',
          codeExchange ? '/google/exchange' : '/google',
          body: {
            if (codeExchange) ...{
              'code': 'fixture-code',
              'code_verifier': 'a' * 43,
            } else ...{
              'id_token': 'test-id',
              'google_access_token': 'test-access',
            },
            'email': 'other@example.test',
            'role': 'admin',
          },
        );
        final data = await _data(response, status: 200);
        expect(data['access_token'], _accessToken);
        expect(data['account'], containsPair('id', _userId));
        expect(data['account'], containsPair('email', _email));
        expect(data['account'], containsPair('role', 'owner'));
        expect(
          data['account'],
          containsPair('display_name', 'Nama profil lama'),
        );
        expect(data['account'], containsPair('profile_complete', true));
        expect(data['account'], containsPair('can_manage_credentials', true));
        expect(upstreamPaths, ['/auth/v1/token']);
      }
    },
  );

  test('linked Google exchange still rejects unsafe sessions', () async {
    for (final (confirmed, status, token, error, httpStatus) in [
      (
        true,
        'active',
        _jwt(overridden: {'sub': _sessionId}),
        'INVALID_SESSION',
        401,
      ),
      (true, 'inactive', _accessToken, 'ACCOUNT_INACTIVE', 403),
      (false, 'active', _accessToken, 'EMAIL_NOT_VERIFIED', 403),
    ]) {
      final app = appWith((request) async {
        expect(request.url.path, '/auth/v1/token');
        return _json(200, {
          ..._session(),
          'access_token': token,
          'user': _user(
            confirmed: confirmed,
            identities: [_identity('email'), _identity('google')],
          ),
        });
      }, sessionStatus: status);
      await _expectError(
        await _send(
          app,
          'POST',
          '/google/exchange',
          body: {'code': 'fixture-code', 'code_verifier': 'a' * 43},
        ),
        httpStatus,
        error,
      );
    }
  });

  test(
    'Google exchange validates the verifier before calling Supabase',
    () async {
      final app = appWith(
        (_) async => fail('Invalid verifier reached Supabase'),
      );
      await _expectError(
        await _send(
          app,
          'POST',
          '/google/exchange',
          body: {'code': 'some-code', 'code_verifier': 'too-short'},
        ),
        400,
        'INVALID_INPUT',
      );
    },
  );

  test(
    'web login keeps the refresh credential only in a host-bound cookie',
    () async {
      final app = appWith((request) async {
        expect(request.url.queryParameters['grant_type'], 'password');
        return _json(200, _session());
      });
      final response = await _web(
        app,
        '/login',
        body: {'email': _email, 'password': _password},
      );
      final cookie = response.headers['set-cookie']!;
      expect(cookie, startsWith('__Host-kc_refresh=rotated-refresh;'));
      for (final attribute in ['path=/', 'secure', 'httponly']) {
        expect(cookie.toLowerCase(), contains(attribute));
      }
      expect(cookie.toLowerCase(), contains('samesite=strict'));
      expect(cookie.toLowerCase(), isNot(contains('domain=')));
      expect(response.headers['cache-control'], 'no-store');
      final data = await _data(response, status: 200);
      expect(data['access_token'], _accessToken);
      expect(data.containsKey('refresh_token'), false);
    },
  );

  test(
    'browser cookie routes reject missing, cross-origin, and disabled origins',
    () async {
      final app = appWith((_) async => fail('Denied request reached Supabase'));
      for (final (origin, site) in [
        (null, 'same-origin'),
        ('https://other.example.test', 'same-origin'),
        (_webOrigin, 'same-site'),
      ]) {
        final response = await _web(
          app,
          '/refresh',
          origin: origin,
          site: site,
          cookie: 'old',
        );
        expect(response.headers.containsKey('set-cookie'), false);
        await _expectError(response, 403, 'WEB_ORIGIN_DENIED');
      }
      final disabled = appWith(
        (_) async => fail('Disabled web Auth reached Supabase'),
        origin: null,
      );
      await _expectError(
        await _web(disabled, '/refresh'),
        503,
        'WEB_AUTH_DISABLED',
      );
    },
  );

  test(
    'web refresh rotates cookies and only clears them after a confirmed rejection',
    () async {
      final app = appWith((request) async {
        expect(request.url.queryParameters['grant_type'], 'refresh_token');
        final body = jsonDecode(request.body) as Map<String, Object?>;
        return switch (body['refresh_token']) {
          'old' => _json(200, _session()),
          'down' => _providerError(503, 'unexpected_failure'),
          'expired' => _providerError(400, 'refresh_token_not_found'),
          _ => throw StateError('Unexpected refresh token'),
        };
      });
      final rotated = await _web(
        app,
        '/refresh',
        cookie: 'old',
        body: {'refresh_token': 'ignored'},
      );
      expect(
        rotated.headers['set-cookie'],
        startsWith('__Host-kc_refresh=rotated-refresh;'),
      );
      expect(
        (await _data(rotated, status: 200)).containsKey('refresh_token'),
        false,
      );

      final transient = await _web(app, '/refresh', cookie: 'down');
      expect(transient.headers['set-cookie'], isNull);
      await _expectError(transient, 503, 'AUTH_UNAVAILABLE');

      for (final absent in [null, 'expired']) {
        final response = await _web(app, '/refresh', cookie: absent);
        expect(response.statusCode, 200);
        expect(
          response.headers['set-cookie']?.toLowerCase(),
          contains('max-age=0'),
        );
        expect(jsonDecode(await response.readAsString()), {
          'success': true,
          'data': null,
        });
      }
    },
  );

  test(
    'web logout only revokes the account held in the browser cookie',
    () async {
      var revocations = 0;
      final app = appWith((request) async {
        if (request.url.path.endsWith('/token')) {
          expect(jsonDecode(request.body), {'refresh_token': 'old'});
          return _json(200, _session());
        }
        expect(request.url.path, '/auth/v1/logout');
        expect(request.headers['authorization'], 'Bearer $_accessToken');
        revocations++;
        return http.Response('', 204);
      });
      final mismatched = await _web(
        app,
        '/logout',
        cookie: 'old',
        body: {'account_id': 'stale-tab'},
      );
      expect(mismatched.statusCode, 200);
      expect(
        mismatched.headers['set-cookie'],
        startsWith('__Host-kc_refresh=rotated-refresh;'),
      );
      expect(revocations, 0);
      final confirmed = await _web(
        app,
        '/logout',
        cookie: 'old',
        body: {'account_id': _userId},
      );
      expect(confirmed.statusCode, 200);
      expect(
        confirmed.headers['set-cookie']?.toLowerCase(),
        contains('max-age=0'),
      );
      expect(revocations, 1);
    },
  );

  test('invalid form and missing bearer never reach the provider', () async {
    final app = appWith((_) async => fail('Invalid request reached Supabase'));
    await _expectError(
      await _send(app, 'POST', '/login', body: 'not JSON'),
      400,
      'INVALID_INPUT',
    );
    await _expectError(
      await _send(
        app,
        'POST',
        '/register',
        body: {'email': _email, 'password': 'too-short'},
      ),
      400,
      'INVALID_INPUT',
    );
    await _expectError(await _send(app, 'GET', '/me'), 401, 'INVALID_SESSION');
  });
}

Future<Response> _web(
  Handler app,
  String path, {
  String? origin = _webOrigin,
  String? site = 'same-origin',
  String? cookie,
  Map<String, String> body = const {},
}) async => app(
  Request(
    'POST',
    Uri.parse('$_webOrigin/v1/auth/web$path'),
    headers: {
      'host': 'app.example.test',
      ..._headers,
      'origin': ?origin,
      'sec-fetch-site': ?site,
      if (cookie != null) 'cookie': 'other=value; __Host-kc_refresh=$cookie',
    },
    body: jsonEncode(body),
  ),
);

Future<Response> _sendPhoto(
  Handler app,
  String method, {
  Uint8List? body,
  String? bearer = _accessToken,
}) async => app(
  Request(
    method,
    Uri.parse('https://api.example.test/v1/auth/profile/photo'),
    headers: {
      'host': 'api.example.test',
      if (body != null) 'content-type': 'image/png',
      if (bearer != null) 'authorization': 'Bearer $bearer',
    },
    body: body,
  ),
);

Future<Response> _send(
  Handler app,
  String method,
  String path, {
  Object? body,
  String? bearer,
}) async {
  final headers = {
    'host': 'api.example.test',
    if (body != null) ..._headers,
    if (bearer != null) 'authorization': 'Bearer $bearer',
  };
  return app(
    Request(
      method,
      Uri.parse('https://api.example.test/v1/auth$path'),
      headers: headers,
      body: body is String ? body : (body == null ? null : jsonEncode(body)),
    ),
  );
}

Future<Response> _sendCatalog(
  Handler app,
  String path, {
  String? bearer = _accessToken,
}) async => app(
  Request(
    'GET',
    Uri.parse('https://api.example.test/v1/catalog$path'),
    headers: {
      'host': 'api.example.test',
      if (bearer != null) 'authorization': 'Bearer $bearer',
    },
  ),
);

Future<Map<String, Object?>> _data(
  Response response, {
  required int status,
}) async {
  final body = await response.readAsString();
  expect(response.statusCode, status, reason: body);
  final json = jsonDecode(body) as Map<String, Object?>;
  expect(json['success'], true);
  return json['data'] as Map<String, Object?>;
}

Future<void> _expectError(Response response, int status, String code) async {
  final body = await response.readAsString();
  expect(response.statusCode, status, reason: body);
  expect(response.headers['cache-control'], 'no-store');
  final json = jsonDecode(body) as Map<String, Object?>;
  expect(json['success'], false);
  expect(json['error'], containsPair('code', code));
  expect(body, isNot(contains('provider-internal-detail')));
}

http.Response _json(int status, Map<String, Object?> body) =>
    http.Response(jsonEncode(body), status, headers: _headers);

http.Response _providerError(int status, String code) => _json(status, {
  'code': code,
  'error_code': code,
  'msg': 'provider-internal-detail',
});

// Synthetic provider output. The mock, rather than this fixture, decides
// whether the provider accepts the signature.
const _sessionId = 'ab3c1940-e57d-41e3-a17a-3e5ec14448d3';
const _accessToken =
    'eyJhbGciOiJFUzI1NiJ9.eyJleHAiOjIwMDAwMDAwMDAsImlzcyI6Imh0dHBzOi8vZXhhbXBsZXByb2plY3RyZWYwMDEuc3VwYWJhc2UuY28vYXV0aC92MSIsImF1ZCI6ImF1dGhlbnRpY2F0ZWQiLCJyb2xlIjoiYXV0aGVudGljYXRlZCIsInN1YiI6IjBiZTc4NWNhLTVkMDktNGFkMC05ZmEwLWE2MTgwZGZmMDFjMSIsInNlc3Npb25faWQiOiJhYjNjMTk0MC1lNTdkLTQxZTMtYTE3YS0zZTVlYzE0NDQ4ZDMifQ.fixture';

String _jwt({Map<String, Object?> overridden = const {}}) {
  String encode(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encode({'alg': 'ES256'});
  final body = encode({
    'exp': 2000000000,
    'iss': validEnvironment()['AUTH_JWT_ISSUER'],
    'aud': 'authenticated',
    'role': 'authenticated',
    'sub': _userId,
    'session_id': _sessionId,
    ...overridden,
  });
  return '$header.$body.fixture';
}

Map<String, Object?> _session({
  bool confirmed = true,
  Map<String, Object?> metadata = const {},
}) => {
  'access_token': _accessToken,
  'token_type': 'bearer',
  'expires_in': 3600,
  'expires_at': 2000000000,
  'refresh_token': 'rotated-refresh',
  'user': _user(confirmed: confirmed, metadata: metadata),
};

Map<String, Object?> _user({
  bool confirmed = true,
  Map<String, Object?> metadata = const {},
  List<Map<String, Object?>> identities = const [],
}) => {
  'id': _userId,
  'aud': 'authenticated',
  'email': _email,
  'created_at': '2026-01-01T00:00:00Z',
  if (confirmed) 'email_confirmed_at': '2026-01-01T00:00:00Z',
  'app_metadata': <String, Object?>{},
  'user_metadata': metadata,
  'identities': identities,
};

Map<String, Object?> _identity(
  String provider, [
  Map<String, Object?> data = const {},
]) => {
  'id': _userId,
  'user_id': _userId,
  'provider': provider,
  'identity_data': data,
};
