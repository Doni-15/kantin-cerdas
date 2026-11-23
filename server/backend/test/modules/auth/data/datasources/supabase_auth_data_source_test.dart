import 'dart:convert';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/supabase_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  late SupabaseAuthDataSource dataSource;
  late SupabaseClientFactory clientFactory;

  setUp(() {
    final config = SupabaseConfig.fromEnv(
      EnvConfig.fromMap({
        'SUPABASE_PROJECT_REF': 'exampleprojectref001',
        'SUPABASE_URL': 'https://exampleprojectref001.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        'SUPABASE_SECRET_KEY': 'sb_secret_test',
      }),
    );

    clientFactory = SupabaseClientFactory(config: config);
    dataSource = SupabaseAuthDataSource(clientFactory: clientFactory);
  });

  group('SupabaseAuthDataSource validation', () {
    test('rejects missing email and phone during sign up', () {
      expect(
        () => dataSource.signUp(password: 'password123'),
        throwsArgumentError,
      );
    });

    test('rejects both email and phone during sign up', () {
      expect(
        () => dataSource.signUp(
          email: 'user@example.com',
          phone: '+628123456789',
          password: 'password123',
        ),
        throwsArgumentError,
      );
    });

    test('rejects missing email and phone during sign in', () {
      expect(
        () => dataSource.signInWithPassword(password: 'password123'),
        throwsArgumentError,
      );
    });

    test('rejects empty refresh token', () {
      expect(
        () => dataSource.refreshSession(refreshToken: '  '),
        throwsArgumentError,
      );
    });

    test('rejects empty access token when getting user', () {
      expect(() => dataSource.getUser(accessToken: '  '), throwsArgumentError);
    });

    test('rejects empty access token during sign out', () {
      expect(() => dataSource.signOut(accessToken: '  '), throwsArgumentError);
    });
  });

  group('SupabaseAuthDataSource requests', () {
    test('sends sign-up data through the injected HTTP client', () async {
      final requests = <http.Request>[];
      final requestDataSource = SupabaseAuthDataSource(
        clientFactory: clientFactory,
        httpClient: MockClient((request) async {
          requests.add(request);

          return http.Response(
            jsonEncode({
              'id': 'f2afb145-0f6c-4d83-8d6a-69d5521e2a1d',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'user@example.com',
              'phone': '',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'created_at': '2026-01-01T00:00:00.000Z',
              'updated_at': '2026-01-01T00:00:00.000Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await requestDataSource.signUp(
        email: 'user@example.com',
        password: 'password123',
        data: {'display_name': 'Test User'},
      );

      expect(response.user?.id, 'f2afb145-0f6c-4d83-8d6a-69d5521e2a1d');
      expect(requests, hasLength(1));

      final request = requests.single;
      final body = jsonDecode(request.body) as Map<String, dynamic>;

      expect(request.method, 'POST');
      expect(request.url.path, '/auth/v1/signup');
      expect(request.headers['apikey'], 'sb_publishable_test');
      expect(body['email'], 'user@example.com');
      expect(body['password'], 'password123');
      expect(body['data'], {'display_name': 'Test User'});
    });

    test(
      'forwards emailRedirectTo to signUp and resend via official query parameter without altering request body',
      () async {
        const redirect = 'id.kantincerdas.oauth://auth/verify-email';
        final requests = <http.Request>[];
        final requestDataSource = SupabaseAuthDataSource(
          clientFactory: clientFactory,
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/auth/v1/signup') {
              return http.Response(
                jsonEncode({
                  'id': 'f2afb145-0f6c-4d83-8d6a-69d5521e2a1d',
                  'aud': 'authenticated',
                  'role': 'authenticated',
                  'email': 'user@example.com',
                  'phone': '',
                  'app_metadata': <String, dynamic>{},
                  'user_metadata': <String, dynamic>{},
                  'created_at': '2026-01-01T00:00:00.000Z',
                  'updated_at': '2026-01-01T00:00:00.000Z',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response(
              jsonEncode(<String, dynamic>{}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        await requestDataSource.signUp(
          email: 'user@example.com',
          password: 'password123',
          emailRedirectTo: redirect,
          data: {'registration_name': 'Test User'},
        );
        await requestDataSource.resendRegistration(
          'user@example.com',
          emailRedirectTo: redirect,
        );
        await requestDataSource.resendRegistration('user@example.com');

        expect(requests, hasLength(3));
        expect(requests[0].url.path, '/auth/v1/signup');
        expect(requests[0].url.queryParameters, {'redirect_to': redirect});
        expect(jsonDecode(requests[0].body), isNot(contains('redirect_to')));
        expect(requests[1].url.path, '/auth/v1/resend');
        expect(requests[1].url.queryParameters, {'redirect_to': redirect});
        final resendBody = jsonDecode(requests[1].body) as Map<String, dynamic>;
        expect(resendBody['email'], 'user@example.com');
        expect(resendBody['type'], 'signup');
        expect(resendBody, isNot(contains('redirect_to')));
        expect(requests[2].url.path, '/auth/v1/resend');
        expect(requests[2].url.queryParameters, isEmpty);
      },
    );
  });
}
