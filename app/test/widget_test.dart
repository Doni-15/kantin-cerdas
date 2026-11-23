import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/auth_email_links_provider.dart';
import 'package:kantin_cerdas/features/auth/application/providers/avatar_picker_provider.dart';
import 'package:kantin_cerdas/features/auth/application/providers/google_oauth_provider.dart';
import 'package:kantin_cerdas/features/auth/data/auth_email_link.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/data/avatar_picker.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth_protocol.dart';
import 'package:kantin_cerdas/main.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/widgets/kc_brand.dart';

const _email = 'doni@example.test';
const _password = 'contoh frasa sandi';
const _emailKey = ValueKey('auth-email');
const _passwordKey = ValueKey('auth-password');
// Minimum time the splash stays visible, counted from its first frame.
const _splashMinimum = Duration(milliseconds: 3000);

void main() {
  test(
    'email links accept only the configured HTTPS host and one typed token',
    () {
      const host = 'auth.example.test';
      final token = 'a' * 64;
      AuthEmailLink? parse(String uri) =>
          AuthEmailLink.parse(Uri.parse(uri), allowedHost: host);
      final link = parse('https://$host/auth/reset-password?token_hash=$token');
      expect(link?.action, AuthEmailAction.recovery);
      expect(link?.tokenHash, token);
      expect(
        parse('https://$host/auth/reset-password?token_hash=%FF'),
        isA<AuthEmailLink>()
            .having((link) => link.action, 'action', AuthEmailAction.recovery)
            .having((link) => link.tokenHash, 'tokenHash', isNull),
      );
      expect(
        parse('id.kantincerdas.oauth://auth/reset-password?token_hash=$token'),
        isNull,
      );
      expect(
        parse(
          'https://other.example.test/auth/reset-password?token_hash=$token',
        ),
        isNull,
      );
      expect(
        parse(
          'https://$host/auth/reset-password?token_hash=$token&token_hash=$token',
        )?.tokenHash,
        isNull,
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('locked login hierarchy fits $brightness', (tester) async {
      _viewport(tester, const Size(390, 700));
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _launch(
        tester,
        (_) async => fail('Login opens without an API call'),
      );
      final elements = [
        find.byType(KcAppLogo),
        find.text('Selamat datang kembali'),
        find.text('Masuk ke akunmu'),
        find.byKey(_emailKey),
        find.byKey(_passwordKey),
        find.text('Lupa password?'),
        find.widgetWithText(FilledButton, 'Masuk'),
        find.text('atau'),
        find.text('Lanjutkan dengan Google'),
        find.text('Daftar'),
      ];
      for (var index = 1; index < elements.length; index++) {
        expect(
          tester.getTopLeft(elements[index]).dy,
          greaterThan(tester.getTopLeft(elements[index - 1]).dy),
        );
      }
      expect(Theme.of(tester.element(elements[1])).brightness, brightness);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'recovery link submits only after matching passwords and handles reuse',
    (tester) async {
      final stream = StreamController<AuthEmailLink>();
      addTearDown(stream.close);
      var requests = 0;
      var checks = 0;
      final hash = 'a' * 64;
      await _launch(tester, (request) async {
        if (request.url.path == '/v1/auth/password-reset/check') {
          expect(jsonDecode(request.body), {'token_hash': hash});
          return ++checks == 1 ? _success(null) : _error(400, 'INVALID_CODE');
        }
        requests++;
        expect(request.url.path, '/v1/auth/password-reset/confirm');
        expect(jsonDecode(request.body), {
          'token_hash': hash,
          'password': _password,
        });
        return _error(400, 'INVALID_CODE');
      }, emailLinks: stream.stream);
      stream.add(AuthEmailLink(AuthEmailAction.recovery, hash));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth-link-password')),
        _password,
      );
      await tester.enterText(_field('Konfirmasi password'), 'mismatch');
      stream.add(AuthEmailLink(AuthEmailAction.recovery, hash));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Simpan password baru'));
      expect(requests, 0);
      await tester.enterText(_field('Konfirmasi password'), _password);
      await _tap(tester, find.text('Simpan password baru'));
      expect(requests, 1);
      expect(find.textContaining('sudah digunakan'), findsOneWidget);
      await _tap(tester, find.text('Minta tautan baru'));
      expect(find.text('Kirim tautan reset'), findsOneWidget);
      stream.add(AuthEmailLink(AuthEmailAction.recovery, hash));
      await tester.pumpAndSettle();
      expect(checks, 2);
      expect(find.textContaining('sudah digunakan'), findsOneWidget);
    },
  );

  testWidgets('an expired recovery link never opens the password form', (
    tester,
  ) async {
    final stream = StreamController<AuthEmailLink>();
    addTearDown(stream.close);
    await _launch(tester, (request) async {
      expect(request.url.path, '/v1/auth/password-reset/check');
      return _error(400, 'INVALID_CODE');
    }, emailLinks: stream.stream);
    stream.add(AuthEmailLink(AuthEmailAction.recovery, 'x' * 64));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-link-password')), findsNothing);
    expect(find.text('Minta tautan baru'), findsOneWidget);
  });

  testWidgets(
    'owner account opens the real Owner shell and can switch to Customer and back',
    (tester) async {
      _viewport(tester, const Size(400, 800));
      await _launchOwner(tester);
      expect(find.text('Beranda'), findsWidgets);
      expect(find.text('Siapkan kantinmu'), findsOneWidget);
      await _tap(tester, find.byTooltip('Akun'));
      expect(find.text('Akun Owner'), findsOneWidget);
      await _tap(tester, find.text('Beralih ke Customer'));
      expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
      await _tap(tester, find.text('Profil'));
      await _tap(tester, find.text('Masuk Area Owner'));
      expect(find.text('Siapkan kantinmu'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(740, 360),
    const Size(1440, 900),
  ]) {
    testWidgets('login fits $size with large text', (tester) async {
      _viewport(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _launch(
        tester,
        (_) async => fail('A new install must open without network'),
      );
      expect(find.byKey(_emailKey), findsOneWidget);
      await tester.ensureVisible(find.text('Daftar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'completes two-step registration only after the required photo is uploaded',
    (tester) async {
      _viewport(tester, const Size(360, 650));
      final calls = <String>[];
      await _launch(
        tester,
        (request) async {
          final path = request.url.path;
          if (path == '/v1/auth/profile/photo' && request.method == 'GET') {
            return http.Response('', 204);
          }
          calls.add(path);
          if (path == '/v1/auth/profile/photo' && request.method == 'PUT') {
            expect(request.headers['content-type'], 'image/jpeg');
            return http.Response.bytes(
              base64Decode(_fixtureJpeg),
              200,
              headers: {'content-type': 'image/jpeg'},
            );
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return switch (path) {
            '/v1/auth/register' => _check(
              body,
              {'email': _email, 'password': _password, 'display_name': 'Doni'},
              {'next': 'verify_email'},
              202,
            ),
            '/v1/auth/login' => _check(body, {
              'email': _email,
              'password': _password,
            }, _session()),
            '/v1/auth/profile' => _check(body, {
              'display_name': 'Doni',
            }, _account('Doni')),
            _ => throw StateError('Unexpected path: $path'),
          };
        },
        pickAvatar: () async => PickedAvatar(
          name: 'foto.jpg',
          bytes: base64Decode(_fixtureJpeg),
          mediaType: 'image/jpeg',
        ),
      );
      await _tap(tester, find.text('Daftar'));
      await tester.enterText(
        find.byKey(const ValueKey('auth-registration-name')),
        'Doni',
      );
      await tester.enterText(find.byKey(_emailKey), _email);
      await tester.enterText(find.byKey(_passwordKey), _password);
      await _tap(tester, find.widgetWithText(FilledButton, 'Lanjutkan'));

      expect(find.text(_email), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-code')), findsNothing);
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Saya sudah verifikasi'),
      );

      expect(find.text('Lengkapi profil'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Selesaikan Pendaftaran'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const ValueKey('auth-name')), ' Doni ');
      await _tap(tester, find.text('Pilih foto profil'));
      expect(find.text('foto.jpg'), findsOneWidget);
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Selesaikan Pendaftaran'),
      );
      expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
      expect(calls, [
        '/v1/auth/register',
        '/v1/auth/login',
        '/v1/auth/profile/photo',
        '/v1/auth/profile',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restores a session after a temporary outage and clears it on logout',
    (tester) async {
      final store = MemorySessionStore();
      await store.write(SessionTokens.fromJson(_session()));
      var meAttempts = 0;
      await _launch(tester, (request) async {
        expect(request.headers['authorization'], 'Bearer test-token');
        if (request.url.path == '/v1/auth/logout') return _success(null);
        if (request.url.path == '/v1/auth/profile/photo') {
          return http.Response('', 204);
        }
        expect(request.url.path, '/v1/auth/me');
        if (++meAttempts == 1) return http.Response('', 503);
        return _success(_account('Doni'));
      }, store: store);
      expect(find.text('Sesi belum pulih'), findsOneWidget);
      expect(await store.read(), isNotNull);
      await _tap(tester, find.text('Coba lagi'));
      expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
      await _tap(tester, find.text('Profil'));
      await _tap(tester, find.text('Edit Profil'));
      await _tap(tester, find.text('Keluar'));
      expect(find.byKey(_emailKey), findsOneWidget);
      expect(await store.read(), isNull);
    },
  );

  testWidgets('Google registration fills only the missing profile step', (
    tester,
  ) async {
    final store = MemorySessionStore();
    final google = GoogleOAuthFlow(
      supabaseUrl: 'https://abcdefghijklmnopqrst.supabase.co',
      browser:
          ({required authorize, required state, required cancelled}) async {
            final redirect = Uri.parse(
              authorize(
                Uri.parse('id.kantincerdas.oauth://auth/google'),
              ).queryParameters['redirect_to']!,
            );
            return redirect.replace(
              queryParameters: {
                ...redirect.queryParameters,
                'code': 'one-time-test-code',
              },
            );
          },
    );
    await _launch(
      tester,
      (request) async {
        expect(request.url.path, '/v1/auth/google/exchange');
        final data = jsonDecode(request.body) as Map<String, Object?>;
        expect(data['code'], 'one-time-test-code');
        expect(data['code_verifier'], hasLength(43));
        return _success({
          ..._session(),
          'account': {..._account(null), 'suggested_name': 'Doni Google'},
        });
      },
      store: store,
      google: google,
    );
    await _tap(tester, find.text('Daftar'));
    await _tap(tester, find.text('Lanjutkan dengan Google'));
    expect(find.text('Lengkapi profil'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-name')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Selesaikan Pendaftaran'),
          )
          .onPressed,
      isNull,
    );
    expect((await store.read())?.refreshToken, 'test-refresh');
  });

  testWidgets(
    'Google login dynamically resolves SUPABASE_URL from Shelf /google/config when omitted at compile time and distinguishes client/server/config errors',
    (tester) async {
      final store = MemorySessionStore();
      var serverGoogleEnabled = false;
      var serverSupabaseUrl = 'https://abcdefghijklmnopqrst.supabase.co';
      final dynamicGoogle = GoogleOAuthFlow(
        supabaseUrl: '',
        verifyBackendProject: true,
        browser:
            ({required authorize, required state, required cancelled}) async {
              final authUri = authorize(
                Uri.parse('id.kantincerdas.oauth://auth/google'),
              );
              expect(authUri.origin, serverSupabaseUrl);
              final redirect = Uri.parse(
                authUri.queryParameters['redirect_to']!,
              );
              return redirect.replace(
                queryParameters: {
                  ...redirect.queryParameters,
                  'code': 'dynamic-test-code',
                },
              );
            },
      );

      await _launch(
        tester,
        (request) async {
          if (request.url.path == '/v1/auth/google/config') {
            if (!serverGoogleEnabled) {
              return _error(503, 'GOOGLE_DISABLED');
            }
            return _success({
              'google_enabled': true,
              'supabase_url': serverSupabaseUrl,
            });
          }
          expect(request.url.path, '/v1/auth/google/exchange');
          final data = jsonDecode(request.body) as Map<String, Object?>;
          expect(data['code'], 'dynamic-test-code');
          expect(data['code_verifier'], hasLength(43));
          return _success({
            ..._session(),
            'account': {..._account(null), 'suggested_name': 'Doni Dynamic'},
          });
        },
        store: store,
        google: dynamicGoogle,
      );

      // 1. Server returns 503 GOOGLE_DISABLED -> shows backend disabled message.
      await _tap(tester, find.text('Lanjutkan dengan Google'));
      expect(find.text('Login Google belum tersedia.'), findsOneWidget);

      // 2. Server enables Google -> dynamically discovers SUPABASE_URL and completes login.
      serverGoogleEnabled = true;
      await _tap(tester, find.text('Lanjutkan dengan Google'));
      expect(find.text('Lengkapi profil'), findsOneWidget);
      expect((await store.read())?.refreshToken, 'test-refresh');
    },
  );

  testWidgets('shows splash while the first session read is pending', (
    tester,
  ) async {
    final store = _DelayedStore();
    await _launch(
      tester,
      (_) async => fail('No request without a saved session'),
      store: store,
      settle: false,
    );
    final artwork = find.byKey(const ValueKey('launch-logo'));
    final logoScale = find.ancestor(
      of: artwork,
      matching: find.byType(ScaleTransition),
    );
    final initialScale = tester.widget<ScaleTransition>(logoScale).scale.value;
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<ScaleTransition>(logoScale).scale.value,
      greaterThan(initialScale),
    );
    expect(artwork, findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Menyiapkan sesi…'), findsOneWidget);
    expect(find.byKey(_emailKey), findsNothing);
    await tester.pump(_splashMinimum - const Duration(milliseconds: 300));
    expect(artwork, findsOneWidget);
    expect(find.byKey(_emailKey), findsNothing);
    store.pending.complete(null);
    await tester.pump();
    expect(find.byKey(_emailKey), findsOneWidget);
    expect(artwork, findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(_emailKey), findsOneWidget);
    expect(find.byKey(const ValueKey('launch-logo')), findsNothing);
  });

  testWidgets('cancelling Google photo replacement keeps its default', (
    tester,
  ) async {
    final store = MemorySessionStore();
    await store.write(SessionTokens.fromJson(_session()));
    await _launch(
      tester,
      (request) async {
        expect(request.url.path, '/v1/auth/me');
        return _success({
          ..._account(null),
          'suggested_name': 'Pengguna Google',
          'google_photo': 'https://lh3.googleusercontent.com/fixture',
        });
      },
      store: store,
      pickAvatar: () async => PickedAvatar(
        name: 'pengganti.jpg',
        bytes: base64Decode(_fixtureJpeg),
        mediaType: 'image/jpeg',
      ),
    );
    await _tap(tester, find.text('Pilih foto profil'));
    expect(find.text('Ganti foto Google?'), findsOneWidget);
    await _tap(tester, find.text('Batal'));
    expect(find.text('pengganti.jpg'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Selesaikan Pendaftaran'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('fast startup displays the splash for at least 3000 ms', (
    tester,
  ) async {
    await _launch(
      tester,
      (_) async => fail('Startup without a saved session uses local storage'),
      settle: false,
    );
    final artwork = find.byKey(const ValueKey('launch-logo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2999));
    expect(artwork, findsOneWidget);
    expect(find.text('Siap dibuka'), findsOneWidget);
    expect(find.byKey(_emailKey), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(_emailKey), findsOneWidget);
    expect(artwork, findsOneWidget);
    await tester.pumpAndSettle();
    expect(artwork, findsNothing);
  });

  for (final slow in [false, true]) {
    testWidgets('startup passes the same first catalog page when slow=$slow', (
      tester,
    ) async {
      final store = MemorySessionStore();
      await store.write(SessionTokens.fromJson(_session()));
      final response = Completer<http.Response>();
      var requests = 0;
      await _launch(
        tester,
        (request) async {
          expect(request.url.path, '/v1/auth/me');
          return _success(_account('Doni'));
        },
        store: store,
        catalog: (request) {
          expect(request.url.path, '/v1/catalog/stalls');
          expect(request.url.queryParameters, isEmpty);
          requests++;
          return response.future;
        },
        settle: false,
      );
      await tester.pump();
      expect(find.text('Memuat daftar stan…'), findsOneWidget);
      expect(find.text('Mau makan apa hari ini?'), findsNothing);
      expect(requests, 1);

      if (slow) {
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pump();
        expect(find.text('Mau makan apa hari ini?'), findsNothing);
        await tester.pump(_splashMinimum - const Duration(milliseconds: 1600));
        expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
        expect(find.text('Dapur Nusantara'), findsNothing);
        expect(requests, 1);
      }

      response.complete(_page(_stall, cursor: _stallId));
      await tester.pump();
      if (!slow) {
        expect(find.text('Mau makan apa hari ini?'), findsNothing);
        await tester.pump(_splashMinimum);
      }
      expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
      expect(find.text('Dapur Nusantara'), findsOneWidget);
      expect(find.text('Muat lagi'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('launch-logo')), findsNothing);
      expect(requests, 1);
    });
  }

  testWidgets('failed startup page hands its error to catalog retry', (
    tester,
  ) async {
    final store = MemorySessionStore();
    await store.write(SessionTokens.fromJson(_session()));
    var requests = 0;
    await _launch(
      tester,
      (_) async => _success(_account('Doni')),
      store: store,
      catalog: (_) async =>
          ++requests == 1 ? http.Response('', 503) : _page(_stall),
    );
    expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
    expect(requests, 1);
    await _tap(tester, find.text('Coba Lagi'));
    expect(find.text('Dapur Nusantara'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets('brand splash fits a short viewport with reduced motion', (
    tester,
  ) async {
    _viewport(tester, const Size(740, 320));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = _DelayedStore();
    await _launch(
      tester,
      (_) async => fail('No request without a saved session'),
      store: store,
      settle: false,
    );
    await tester.pump();
    final artwork = find.byKey(const ValueKey('launch-logo'));
    final logoBounds = tester.getRect(artwork);
    expect(logoBounds.size.width, closeTo(115.2, 0.1));
    expect(logoBounds.size.width, logoBounds.size.height);
    expect(logoBounds.top, greaterThan(0));
    expect(logoBounds.bottom, lessThan(320));
    _expectSplashColors(tester, KcColors.dark);
    expect(find.text('Menyiapkan sesi…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    _expectSplashColors(tester, KcColors.light);

    store.pending.complete(null);
    await tester.pump(_splashMinimum);
    await tester.pumpAndSettle();
    expect(find.byKey(_emailKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an account can replace a profile photo and cannot remove it', (
    tester,
  ) async {
    final store = MemorySessionStore();
    await store.write(SessionTokens.fromJson(_session()));
    var hasPhoto = false;
    final photo = base64Decode(_fixtureJpeg);
    final calls = <String>[];
    await _launch(
      tester,
      (request) async {
        expect(request.headers['authorization'], 'Bearer test-token');
        if (request.url.path == '/v1/auth/me') {
          return _success(_account('Doni'));
        }
        expect(request.url.path, '/v1/auth/profile/photo');
        calls.add(request.method);
        if (request.method == 'PUT') {
          expect(request.headers['content-type'], 'image/jpeg');
          expect(request.bodyBytes, photo);
          hasPhoto = true;
        }
        return hasPhoto
            ? http.Response.bytes(
                photo,
                200,
                headers: {'content-type': 'image/jpeg'},
              )
            : http.Response('', 204);
      },
      store: store,
      pickAvatar: () async =>
          PickedAvatar(name: 'foto.jpg', bytes: photo, mediaType: 'image/jpeg'),
    );
    await _tap(tester, find.text('Profil'));
    await _tap(tester, find.text('Edit Profil'));
    await _tap(tester, find.text('Tambahkan foto profil'));
    expect(find.text('Ganti foto profil?'), findsOneWidget);
    await _tap(tester, find.text('Batal'));
    expect(calls, ['GET']);
    await _tap(tester, find.text('Tambahkan foto profil'));
    await _tap(tester, find.text('Ganti foto'));
    expect(find.text('Ganti foto profil'), findsOneWidget);
    expect(find.text('Hapus foto profil'), findsNothing);
    expect(calls, ['GET', 'PUT', 'GET']);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(740, 360),
    const Size(1440, 900),
  ]) {
    testWidgets('catalog search and detail fit $size with large text', (
      tester,
    ) async {
      _viewport(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemorySessionStore();
      await store.write(SessionTokens.fromJson(_session()));
      final calls = <Uri>[];
      await _launch(
        tester,
        (_) async => _success(_account('Doni')),
        store: store,
        catalog: (request) async {
          expect(request.headers['authorization'], 'Bearer test-token');
          final uri = request.url;
          calls.add(uri);
          return switch (uri.path) {
            '/v1/catalog/stalls' => _page(_stall),
            '/v1/catalog/stalls/$_stallId' => _success(_stall),
            '/v1/catalog/menu' => _page(_menu),
            _ => fail('Unexpected catalog request $uri'),
          };
        },
      );
      await _tap(tester, find.text('Cari'));
      await tester.enterText(find.byType(TextField), 'Nasi & ayam');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(calls.last.queryParameters, {'q': 'Nasi & ayam'});
      await tester.scrollUntilVisible(
        find.text('Nasi ayam'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await _tap(tester, find.text('Nasi ayam'));
      expect(find.text('Nasi ayam'), findsWidgets);
      await tester.scrollUntilVisible(
        find.textContaining('Kantin sedang tutup'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('Kantin sedang tutup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('catalog retries a failed page without losing search results', (
    tester,
  ) async {
    final store = MemorySessionStore();
    await store.write(SessionTokens.fromJson(_session()));
    final oldSearch = Completer<http.Response>();
    var pageAttempts = 0;
    await _launch(
      tester,
      (_) async => _success(_account('Doni')),
      store: store,
      catalog: (request) async {
        final query = request.url.queryParameters;
        final isMenu = request.url.path == '/v1/catalog/menu';
        if (query['q'] == 'lama') return oldSearch.future;
        if (query['cursor'] != null) {
          expect(query['cursor'], _stallId);
          if (++pageAttempts == 1) return http.Response('', 503);
          return _page({..._stall, 'id': _menuId, 'name': 'Stan tambahan'});
        }
        if (query['q'] == 'baru') {
          return isMenu
              ? _page({..._menu, 'name': 'Menu baru'})
              : _page({..._stall, 'name': 'Hasil baru'});
        }
        return isMenu ? _page(null) : _page(_stall, cursor: _stallId);
      },
    );
    await _tap(tester, find.text('Cari'));
    await tester.enterText(find.byType(TextField), 'lama');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'baru');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    oldSearch.complete(_page({..._menu, 'name': 'Hasil lama'}));
    await tester.pumpAndSettle();
    expect(find.text('Hasil lama'), findsNothing);
    expect(find.text('Hasil baru'), findsWidgets);

    await _tap(tester, find.text('Beranda'));
    await tester.scrollUntilVisible(
      find.text('Muat lagi'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await _tap(tester, find.text('Muat lagi'));
    expect(find.text('Dapur Nusantara'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Coba Lagi'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await _tap(tester, find.text('Coba Lagi'));
    expect(find.text('Stan tambahan'), findsOneWidget);
    expect(find.text('Dapur Nusantara'), findsOneWidget);
    expect(find.text('Muat lagi'), findsNothing);
  });

  testWidgets('failed login keeps the form and shows a safe error', (
    tester,
  ) async {
    await _launch(tester, (request) async {
      expect(request.url.path, '/v1/auth/login');
      return _error(401, 'INVALID_CREDENTIALS');
    });
    await tester.enterText(find.byKey(_emailKey), _email);
    await tester.enterText(find.byKey(_passwordKey), 'wrong-password');
    await _tap(tester, find.widgetWithText(FilledButton, 'Masuk'));
    final error = find.text('Email atau kata sandi tidak cocok.');
    expect(error, findsOneWidget);
    expect(
      tester.getTopLeft(error).dy,
      greaterThan(tester.getTopLeft(find.text('Lupa password?')).dy),
    );
    expect(find.text('upstream detail'), findsNothing);
    expect(find.byKey(_emailKey), findsOneWidget);
  });

  for (final (label, status, code, message) in [
    (
      'unusable email address',
      422,
      'SIGNUP_EMAIL_INVALID',
      'Alamat email ini tidak dapat digunakan untuk mendaftar.',
    ),
    (
      'email delivery restriction',
      422,
      'SIGNUP_EMAIL_DELIVERY_RESTRICTED',
      'Tautan verifikasi tidak dapat dikirim ke alamat email ini.',
    ),
    ('input', 400, 'INVALID_INPUT', 'Periksa kembali data'),
    ('service', 503, 'AUTH_UNAVAILABLE', 'Layanan sedang tidak tersedia.'),
    ('timeout', 504, 'AUTH_UNAVAILABLE', 'Layanan terlalu lama merespons.'),
    (
      'network',
      null,
      null,
      'Tidak dapat terhubung ke layanan. Periksa koneksi',
    ),
  ]) {
    testWidgets('signup explains this error: $label', (tester) async {
      await _launch(tester, (request) async {
        expect(request.url.path, '/v1/auth/register');
        if (status == null) throw http.ClientException('upstream detail');
        return _error(status, code!);
      });
      await _tap(tester, find.text('Daftar'));
      await tester.enterText(
        find.byKey(const ValueKey('auth-registration-name')),
        'Doni',
      );
      await tester.enterText(find.byKey(_emailKey), _email);
      await tester.enterText(find.byKey(_passwordKey), _password);
      await _tap(tester, find.widgetWithText(FilledButton, 'Lanjutkan'));
      expect(find.textContaining(message), findsOneWidget);
      expect(find.textContaining('Email tidak terdaftar'), findsNothing);
      expect(find.text('upstream detail'), findsNothing);
      expect(find.text('Cek email kamu'), findsNothing);
    });
  }

  testWidgets('signup with a link can continue through the normal login', (
    tester,
  ) async {
    final calls = <String>[];
    await _launch(tester, (request) async {
      final path = request.url.path;
      calls.add(path);
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body, {
        'email': _email,
        'password': _password,
        if (path.endsWith('/register')) 'display_name': 'Doni',
      });
      return switch (path) {
        '/v1/auth/register' => _success({'next': 'verify_email'}, 202),
        '/v1/auth/login' => _success(_session()),
        _ => fail('Unexpected path $path'),
      };
    });
    await _tap(tester, find.text('Daftar'));
    await tester.enterText(
      find.byKey(const ValueKey('auth-registration-name')),
      'Doni',
    );
    await tester.enterText(find.byKey(_emailKey), _email);
    await tester.enterText(find.byKey(_passwordKey), _password);
    await _tap(tester, find.widgetWithText(FilledButton, 'Lanjutkan'));
    expect(
      find.textContaining('Jika alamat email dapat didaftarkan'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Kembali ke Masuk'));
    expect(
      tester.widget<TextFormField>(find.byKey(_emailKey)).controller?.text,
      _email,
    );
    expect(
      tester.widget<TextFormField>(find.byKey(_passwordKey)).controller?.text,
      isEmpty,
    );
    await tester.enterText(find.byKey(_passwordKey), _password);
    await _tap(tester, find.widgetWithText(FilledButton, 'Masuk'));
    expect(find.text('Lengkapi profil'), findsOneWidget);
    expect(calls, ['/v1/auth/register', '/v1/auth/login']);
  });

  test(
    'rejected access token uses one refresh and persists the rotated token pair',
    () async {
      final store = MemorySessionStore();
      await store.write(SessionTokens.fromJson(_session()));
      final requests = <String>[];
      final client = MockClient((request) async {
        requests.add(request.url.path);
        if (request.url.path.endsWith('/me')) {
          return _error(401, 'INVALID_SESSION');
        }
        expect(jsonDecode(request.body), {'refresh_token': 'test-refresh'});
        return _success({
          ..._session(displayName: 'Doni'),
          'refresh_token': 'test-rotated',
        });
      });
      addTearDown(client.close);
      final repository = AuthRepository(
        client: client,
        store: store,
        baseUrl: 'https://api.example.test',
      );
      expect((await repository.restore())?.account.displayName, 'Doni');
      expect((await store.read())?.refreshToken, 'test-rotated');
      expect(requests, ['/v1/auth/me', '/v1/auth/refresh']);
    },
  );
  test(
    'retrying profile after an outage reuses the already rotated session',
    () async {
      final store = MemorySessionStore();
      final old = SessionTokens.fromJson({
        ..._session(),
        'expires_at': '2000-01-01T00:00:00Z',
      });
      await store.write(old);
      var refreshCount = 0;
      var profileCount = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/refresh')) {
          refreshCount++;
          expect(jsonDecode(request.body), {'refresh_token': 'test-refresh'});
          return _success({
            ..._session(),
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
        }
        expect(request.url.path, '/v1/auth/profile');
        expect(request.headers['authorization'], 'Bearer new-access');
        if (++profileCount == 1) return http.Response('', 503);
        return _success(_account('Doni'));
      });
      addTearDown(client.close);
      final repository = AuthRepository(
        client: client,
        store: store,
        baseUrl: 'https://api.example.test',
      );
      final initial = AuthSession(old, AuthAccount.fromJson(_account(null)));
      await expectLater(
        repository.completeProfile(initial, 'Doni'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'AUTH_UNAVAILABLE',
          ),
        ),
      );
      final result = await repository.completeProfile(initial, 'Doni');
      expect(result.account.displayName, 'Doni');
      expect(result.tokens.refreshToken, 'new-refresh');
      expect(refreshCount, 1);
      expect(profileCount, 2);
    },
  );
  test('concurrent authenticated requests share one refresh', () async {
    final store = MemorySessionStore();
    final tokens = SessionTokens.fromJson({
      ..._session(),
      'expires_at': '2000-01-01T00:00:00Z',
    });
    await store.write(tokens);
    final refreshStarted = Completer<void>();
    final refreshResponse = Completer<http.Response>();
    final photoRequests = <String?>[];
    var refreshCount = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/v1/auth/refresh') {
        if (++refreshCount == 1) refreshStarted.complete();
        return refreshResponse.future;
      }
      expect(request.url.path, '/v1/auth/profile/photo');
      photoRequests.add(request.headers['authorization']);
      return http.Response('', 204);
    });
    addTearDown(client.close);
    final repository = AuthRepository(
      client: client,
      store: store,
      baseUrl: 'https://api.example.test',
    );
    final session = AuthSession(tokens, AuthAccount.fromJson(_account('Doni')));

    final first = repository.loadAvatar(session);
    await refreshStarted.future;
    final second = repository.loadAvatar(session);
    await Future<void>.delayed(Duration.zero);
    expect(photoRequests, isEmpty);
    refreshResponse.complete(
      _success({
        ..._session(displayName: 'Doni'),
        'access_token': 'rotated-access',
        'refresh_token': 'rotated-refresh',
      }),
    );

    expect(await Future.wait([first, second]), [null, null]);
    expect(refreshCount, 1);
    expect(photoRequests, ['Bearer rotated-access', 'Bearer rotated-access']);
    expect((await store.read())?.refreshToken, 'rotated-refresh');
  });

  test('a late avatar refresh cannot restore tokens after logout', () async {
    final store = MemorySessionStore();
    final expired = SessionTokens.fromJson({
      ..._session(),
      'expires_at': '2000-01-01T00:00:00Z',
    });
    await store.write(expired);
    final started = Completer<void>();
    final pending = Completer<http.Response>();
    final client = MockClient((request) {
      expect(request.url.path, '/v1/auth/refresh');
      started.complete();
      return pending.future;
    });
    addTearDown(client.close);
    final repo = AuthRepository(
      client: client,
      store: store,
      baseUrl: 'https://api.example.test',
    );
    final request = repo.loadAvatar(
      AuthSession(expired, AuthAccount.fromJson(_account('Doni'))),
    );
    final rejected = expectLater(request, throwsA(isA<AuthException>()));
    await started.future;
    await repo.clearSession();
    pending.complete(_success(_session(displayName: 'Doni')));
    await rejected;
    expect(await store.read(), isNull);
  });

  test(
    'Android email confirmation callback parses without token_hash, keeps Google OAuth and HTTPS separate, and never leaks tokens',
    () {
      const host = 'auth.example.test';
      final token = 'b' * 64;
      AuthEmailLink? parse(String uri, {String allowedHost = host}) =>
          AuthEmailLink.parse(Uri.parse(uri), allowedHost: allowedHost);

      for (final validCallback in [
        'id.kantincerdas.oauth://auth/verify-email',
        'id.kantincerdas.oauth://auth/verify-email?type=signup',
        'id.kantincerdas.oauth://auth/verify-email?code=one-time-pkce-code',
        'id.kantincerdas.oauth://auth/verify-email#access_token=leaked-access-jwt&refresh_token=leaked-refresh-jwt&provider_token=leaked-provider-jwt&token_type=bearer&type=signup',
      ]) {
        for (final configuredHost in ['', 'auth.kantincerdas.invalid', host]) {
          final parsed = parse(validCallback, allowedHost: configuredHost);
          expect(parsed, isNotNull, reason: validCallback);
          expect(parsed?.action, AuthEmailAction.signup);
          expect(parsed?.tokenHash, isNull);
          expect(parsed?.isCallback, isTrue);
          expect(parsed?.isInvalid, isFalse);
          expect(parsed.toString(), isNot(contains('leaked-access-jwt')));
          expect(parsed.toString(), isNot(contains('leaked-refresh-jwt')));
          expect(parsed.toString(), isNot(contains('leaked-provider-jwt')));
        }
      }

      // Google OAuth callback remains strictly separate in both directions.
      expect(
        parse(
          'id.kantincerdas.oauth://auth/google?kc_state=state-1&code=google-code',
        ),
        isNull,
      );
      expect(
        matchesGoogleRedirect(
          Uri.parse(mobileGoogleRedirect),
          Uri.parse(
            'id.kantincerdas.oauth://auth/verify-email?kc_state=state-1&code=google-code',
          ),
          'state-1',
        ),
        isFalse,
      );

      // Unrelated custom-scheme paths, hosts, ports, and userInfo are rejected.
      for (final unrelated in [
        'id.kantincerdas.oauth://auth/reset-password?token_hash=$token',
        'id.kantincerdas.oauth://auth/change-email?token_hash=$token',
        'id.kantincerdas.oauth://other/verify-email',
        'id.kantincerdas.oauth://auth:8080/verify-email',
        'id.kantincerdas.oauth://user@auth/verify-email',
      ]) {
        expect(parse(unrelated), isNull, reason: unrelated);
      }

      // Legacy HTTPS App Links remain valid and distinct from post-confirmation callbacks.
      for (final (path, expectedAction) in [
        ('/auth/verify-email', AuthEmailAction.signup),
        ('/auth/reset-password', AuthEmailAction.recovery),
        ('/auth/change-email', AuthEmailAction.emailChange),
      ]) {
        final httpsValid = parse('https://$host$path?token_hash=$token');
        expect(httpsValid?.action, expectedAction);
        expect(httpsValid?.tokenHash, token);
        expect(httpsValid?.isCallback, isFalse);
        expect(httpsValid?.isInvalid, isFalse);

        final httpsMissingToken = parse('https://$host$path');
        expect(httpsMissingToken?.action, expectedAction);
        expect(httpsMissingToken?.tokenHash, isNull);
        expect(httpsMissingToken?.isCallback, isFalse);
        expect(httpsMissingToken?.isInvalid, isTrue);
      }

      // Failed, expired, or malformed Android callbacks are flagged as invalid without leaking tokens.
      for (final failedCallback in [
        'id.kantincerdas.oauth://auth/verify-email#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired',
        'id.kantincerdas.oauth://auth/verify-email?error=access_denied&error_code=otp_expired',
        'id.kantincerdas.oauth://auth/verify-email?error_code=otp_expired',
        'id.kantincerdas.oauth://auth/verify-email?error_description=Expired+link',
        'id.kantincerdas.oauth://auth/verify-email?type=recovery',
        'id.kantincerdas.oauth://auth/verify-email?type=signup&type=signup',
        'id.kantincerdas.oauth://auth/verify-email?token_hash=$token',
        'id.kantincerdas.oauth://auth/verify-email?token_hash=%FF',
        'id.kantincerdas.oauth://auth/verify-email#%FF',
        'id.kantincerdas.oauth://auth/verify-email#access_token=%FF',
      ]) {
        final parsed = parse(failedCallback, allowedHost: '');
        expect(parsed, isNotNull, reason: failedCallback);
        expect(parsed?.action, AuthEmailAction.signup);
        expect(parsed?.tokenHash, isNull);
        expect(parsed?.isCallback, isTrue);
        expect(parsed?.isInvalid, isTrue, reason: failedCallback);
      }
    },
  );

  testWidgets(
    'cold start via Android email confirmation deep link does not auto-login or assume verification before normal login',
    (tester) async {
      final store = MemorySessionStore();
      final calls = <String>[];
      var confirmedOnServer = false;
      final coldStartLink = AuthEmailLink.parse(
        Uri.parse(
          'id.kantincerdas.oauth://auth/verify-email#access_token=cold-secret-access&refresh_token=cold-secret-refresh&token_type=bearer&type=signup',
        ),
      )!;
      await _launch(
        tester,
        (request) async {
          calls.add(request.url.path);
          expect(request.url.path, '/v1/auth/login');
          expect(request.body, isNot(contains('cold-secret-access')));
          expect(request.body, isNot(contains('cold-secret-refresh')));
          expect(jsonDecode(request.body), {
            'email': _email,
            'password': _password,
          });
          return confirmedOnServer
              ? _success(_session())
              : _error(403, 'EMAIL_NOT_VERIFIED');
        },
        store: store,
        emailLinks: Stream<AuthEmailLink>.value(coldStartLink),
      );

      expect(calls, isEmpty);
      expect(await store.read(), isNull);
      expect(find.text('Verifikasi Email'), findsOneWidget);
      expect(
        find.text('Masuk ke akunmu untuk memeriksa status verifikasi email.'),
        findsOneWidget,
      );
      expect(find.text('Konfirmasi'), findsNothing);
      expect(find.textContaining('cold-secret-access'), findsNothing);
      expect(find.textContaining('cold-secret-refresh'), findsNothing);

      await _tap(tester, find.text('Kembali ke Masuk'));
      expect(find.text('Selamat datang kembali'), findsOneWidget);
      await tester.enterText(find.byKey(_emailKey), _email);
      await tester.enterText(find.byKey(_passwordKey), _password);
      await _tap(tester, find.widgetWithText(FilledButton, 'Masuk'));

      // Server has not confirmed the email yet: app requires verification rather than assuming the URI verified it.
      expect(find.text('Cek email kamu'), findsOneWidget);
      expect(
        find.text('Periksa email verifikasi untuk akun ini.'),
        findsOneWidget,
      );
      expect(await store.read(), isNull);

      confirmedOnServer = true;
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Saya sudah verifikasi'),
      );
      expect(find.text('Lengkapi profil'), findsOneWidget);
      expect((await store.read())?.accessToken, 'test-token');
      expect(calls, ['/v1/auth/login', '/v1/auth/login']);
    },
  );

  testWidgets(
    'warm start handles expired and confirmed Android email callbacks while preserving normal login flow',
    (tester) async {
      final stream = StreamController<AuthEmailLink>();
      addTearDown(stream.close);
      final store = MemorySessionStore();
      final calls = <String>[];
      await _launch(
        tester,
        (request) async {
          final path = request.url.path;
          calls.add(path);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return switch (path) {
            '/v1/auth/register' => _check(
              body,
              {'email': _email, 'password': _password, 'display_name': 'Doni'},
              {'next': 'verify_email'},
              202,
            ),
            '/v1/auth/login' => _check(body, {
              'email': _email,
              'password': _password,
            }, _session()),
            _ => fail('Unexpected path: $path'),
          };
        },
        store: store,
        emailLinks: stream.stream,
      );

      await _tap(tester, find.text('Daftar'));
      await tester.enterText(
        find.byKey(const ValueKey('auth-registration-name')),
        'Doni',
      );
      await tester.enterText(find.byKey(_emailKey), _email);
      await tester.enterText(find.byKey(_passwordKey), _password);
      await _tap(tester, find.widgetWithText(FilledButton, 'Lanjutkan'));
      expect(find.text('Cek email kamu'), findsOneWidget);

      // Warm start: expired confirmation redirect opens the invalid link state.
      stream.add(
        AuthEmailLink.parse(
          Uri.parse(
            'id.kantincerdas.oauth://auth/verify-email#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired',
          ),
        )!,
      );
      await tester.pumpAndSettle();
      expect(find.text('Verifikasi Email'), findsOneWidget);
      expect(
        find.text('Tautan tidak valid, sudah digunakan, atau kedaluwarsa.'),
        findsOneWidget,
      );
      expect(find.text('Konfirmasi'), findsNothing);
      await _tap(tester, find.text('Kembali ke Masuk'));
      expect(
        tester.widget<TextFormField>(find.byKey(_emailKey)).controller?.text,
        _email,
      );

      // Warm start: confirmed redirect arrives and returns to normal login with the email preserved.
      stream.add(
        AuthEmailLink.parse(
          Uri.parse(
            'id.kantincerdas.oauth://auth/verify-email#access_token=warm-secret-access&refresh_token=warm-secret-refresh&type=signup',
          ),
        )!,
      );
      await tester.pumpAndSettle();
      expect(find.text('Verifikasi Email'), findsOneWidget);
      expect(
        find.text('Masuk ke akunmu untuk memeriksa status verifikasi email.'),
        findsOneWidget,
      );
      expect(find.text('Konfirmasi'), findsNothing);
      expect(find.textContaining('warm-secret-access'), findsNothing);
      expect(find.textContaining('warm-secret-refresh'), findsNothing);
      expect(await store.read(), isNull);

      await _tap(tester, find.text('Kembali ke Masuk'));
      expect(
        tester.widget<TextFormField>(find.byKey(_emailKey)).controller?.text,
        _email,
      );
      expect(
        tester.widget<TextFormField>(find.byKey(_passwordKey)).controller?.text,
        isEmpty,
      );
      await tester.enterText(find.byKey(_passwordKey), _password);
      await _tap(tester, find.widgetWithText(FilledButton, 'Masuk'));
      expect(find.text('Lengkapi profil'), findsOneWidget);
      expect(calls, ['/v1/auth/register', '/v1/auth/login']);
    },
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _launchOwner(WidgetTester tester) async {
  final store = MemorySessionStore();
  final account = {..._account('Doni'), 'role': 'owner'};
  final session = {..._session(displayName: 'Doni'), 'account': account};
  await store.write(SessionTokens.fromJson(session));
  await _launch(tester, (request) async {
    return switch (request.url.path) {
      '/v1/auth/me' => _success(account),
      '/v1/auth/profile/photo' => http.Response('', 204),
      '/v1/owner/dashboard' => _success({
        'stall': null,
        'schedules': const <Object>[],
        'publish_eligibility': {
          'can_publish': false,
          'missing_profile_fields': ['name', 'campus', 'block'],
          'available_menu_count': 0,
        },
        'active_counts': {
          'menunggu_konfirmasi': 0,
          'diproses': 0,
          'siap_diambil': 0,
        },
        'attention_orders': const <Object>[],
      }),
      '/v1/owner/stall' => _success({
        'stall': null,
        'schedules': const <Object>[],
        'publish_eligibility': {
          'can_publish': false,
          'missing_profile_fields': ['name', 'campus', 'block'],
          'available_menu_count': 0,
        },
      }),
      '/v1/owner/orders' => _success({
        'items': const <Object>[],
        'has_more': false,
      }),
      _ => fail('Unexpected request: ${request.url}'),
    };
  }, store: store);
}

void _expectSplashColors(WidgetTester tester, ColorScheme colors) {
  expect(
    tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
    colors.surface,
  );
  final wordmark = tester.widget<Text>(
    find.descendant(of: find.byType(KcBrandName), matching: find.byType(Text)),
  );
  final parts = (wordmark.textSpan! as TextSpan).children!.cast<TextSpan>();
  expect(parts.map((part) => part.text), ['Kantin', 'Cerdas']);
  expect(parts.map((part) => part.style?.color), [
    colors.primary,
    colors.secondary,
  ]);
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _launch(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) respond, {
  SessionStore? store,
  AvatarPicker? pickAvatar,
  GoogleOAuthFlow? google,
  Stream<AuthEmailLink>? emailLinks,
  Future<http.Response> Function(http.Request)? catalog,
  bool settle = true,
}) async {
  final client = MockClient((request) {
    if (request.url.path.startsWith('/v1/catalog/')) {
      return catalog?.call(request) ?? Future.value(_page(null));
    }
    if (request.url.path == '/v1/customer/cart' && request.method == 'GET') {
      return Future.value(
        _success({
          'stall': null,
          'items': const [],
          'general_note': '',
          'draft_version': 0,
          'subtotal': 0,
          'seen_subtotal': 0,
          'item_count': 0,
          'can_checkout': false,
          'blockers': const [],
        }),
      );
    }
    if (request.url.path == '/v1/customer/menus/$_menuId' &&
        request.method == 'GET') {
      return Future.value(_success({'menu': _menu, 'stall': _stall}));
    }
    if (request.url.path == '/v1/customer/stalls/$_stallId' &&
        request.method == 'GET') {
      return Future.value(
        _success({
          'stall': _stall,
          'schedules': const [],
          'categories': const [],
          'menus': [_menu],
        }),
      );
    }
    if (request.url.path == '/v1/customer/owner-application' &&
        request.method == 'GET') {
      return Future.value(
        _success({
          'latest_application': null,
          'active_order_indicator': {
            'has_active_orders': false,
            'active_order_count': 0,
          },
        }),
      );
    }
    if (request.url.path.startsWith('/v1/notifications/')) {
      return Future.value(
        http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'ROUTE_NOT_FOUND', 'message': 'Route not found'},
          }),
          404,
        ),
      );
    }
    return respond(request);
  });
  addTearDown(client.close);
  final repository = AuthRepository(
    client: client,
    store: store ?? MemorySessionStore(),
    baseUrl: 'https://api.example.test',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        if (pickAvatar != null)
          avatarPickerProvider.overrideWithValue(pickAvatar),
        if (google != null) googleOAuthProvider.overrideWithValue(google),
        if (emailLinks != null)
          authEmailLinksProvider.overrideWith((ref) => emailLinks),
      ],
      child: const KantinCerdasApp(),
    ),
  );
  if (settle) {
    await tester.pump(_splashMinimum);
    await tester.pumpAndSettle();
  }
}

http.Response _check(
  Map<String, dynamic> body,
  Map<String, Object> expected,
  Object data, [
  int status = 200,
]) {
  expect(body, expected);
  return _success(data, status);
}

http.Response _success(Object? data, [int status = 200]) =>
    http.Response(jsonEncode({'success': true, 'data': data}), status);

const _stallId = '23c4e013-e85c-4b4f-9507-6f9be407b40f';
const _menuId = 'e03f41d1-fe80-4c3c-8cf0-44013f4b4d00';
const _stall = {
  'id': _stallId,
  'name': 'Dapur Nusantara',
  'description': 'Menu makan siang.',
  'block': 'A',
  'wait_minutes': 8,
  'is_open': false,
};
const _menu = {
  'id': _menuId,
  'name': 'Nasi ayam',
  'description': 'Nasi dan ayam panggang.',
  'block': 'A',
  'wait_minutes': 8,
  'stall_id': _stallId,
  'stall_name': 'Dapur Nusantara',
  'category': 'Makanan',
  'price': 15000,
  'is_available': true,
  'stall_is_open': false,
};

http.Response _page(Object? item, {String? cursor}) => _success({
  'items': [?item],
  'next_cursor': cursor,
});

http.Response _error(int status, String code) => http.Response(
  jsonEncode({
    'success': false,
    'error': {'code': code, 'message': 'upstream detail'},
  }),
  status,
);

Map<String, Object> _session({String? displayName}) => {
  'access_token': 'test-token',
  'refresh_token': 'test-refresh',
  'expires_at': '2100-01-01T00:00:00Z',
  'account': _account(displayName),
};

Map<String, Object?> _account(String? name) => {
  'id': 'test-account',
  'email': _email,
  'role': 'customer',
  'display_name': name,
  'suggested_name': null,
  'has_photo': name != null,
  'profile_complete': name != null,
};

class _DelayedStore extends MemorySessionStore {
  final pending = Completer<SessionTokens?>();

  @override
  Future<SessionTokens?> read() => pending.future;
}

const _fixtureJpeg =
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAACAAIDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD//2Q==';
