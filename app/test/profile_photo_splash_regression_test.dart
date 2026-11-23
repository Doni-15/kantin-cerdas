import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/application/providers/avatar_picker_provider.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/data/avatar_picker.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/account_view.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/splash_screen.dart';
import 'package:kantin_cerdas/main.dart';

const _splashMinimum = Duration(milliseconds: 3000);
const _stallIdA = '23c4e013-e85c-4b4f-9507-6f9be407b40f';
const _stallIdB = 'e03f41d1-fe80-4c3c-8cf0-44013f4b4d00';

void main() {
  testWidgets(
    'initial startup displays session and catalog splash phases before opening home',
    (tester) async {
      final store = MemorySessionStore();
      await store.write(
        SessionTokens.fromJson(_sessionJson(accountId: 'acc-1')),
      );
      final meCompleter = Completer<http.Response>();
      final catalogCompleter = Completer<http.Response>();

      await _launchApp(
        tester,
        store: store,
        onAuth: (_) => meCompleter.future,
        onCatalog: (_) => catalogCompleter.future,
        settle: false,
      );

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Menyiapkan sesi…'), findsOneWidget);

      meCompleter.complete(_ok(_accountJson(id: 'acc-1', name: 'Doni')));
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Memuat daftar stan…'), findsOneWidget);

      catalogCompleter.complete(_stallPage(_stallIdA, 'Dapur Nusantara'));
      await tester.pump(_splashMinimum);
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
      expect(find.text('Dapur Nusantara'), findsOneWidget);
    },
  );

  testWidgets(
    'returning from native photo picker with AppLifecycleState.resumed '
    'revalidates session without showing catalog splash and updates photo',
    (tester) async {
      final store = MemorySessionStore();
      await store.write(
        SessionTokens.fromJson(
          _sessionJson(accountId: 'acc-1', accessToken: 'token-initial'),
        ),
      );
      final initialPhoto = _validJpegWithTag(1);
      final updatedPhoto = _validJpegWithTag(2);
      var currentPhoto = initialPhoto;
      var meCalls = 0;
      var catalogCalls = 0;
      var cartCalls = 0;
      var photoGetCalls = 0;
      var photoPutCalls = 0;
      String? photoUploadBearer;
      final pickerCompleter = Completer<PickedAvatar?>();

      await _launchApp(
        tester,
        store: store,
        pickAvatar: () => pickerCompleter.future,
        onAuth: (request) async {
          if (request.url.path == '/v1/customer/cart') {
            cartCalls++;
            return _emptyCart();
          }
          if (request.url.path == '/v1/auth/me') {
            meCalls++;
            if (meCalls == 1) {
              return _ok(_accountJson(id: 'acc-1', name: 'Doni'));
            }
            // Simulate refresh during resume returning a brand-new token/account.
            return _error(401, 'INVALID_SESSION');
          }
          if (request.url.path == '/v1/auth/refresh') {
            return _ok({
              ..._sessionJson(
                accountId: 'acc-1',
                accessToken: 'token-refreshed',
              ),
              'account': _accountJson(id: 'acc-1', name: 'Doni'),
            });
          }
          if (request.url.path == '/v1/auth/profile/photo') {
            if (request.method == 'GET') {
              photoGetCalls++;
              return http.Response.bytes(
                currentPhoto,
                200,
                headers: {'content-type': 'image/jpeg'},
              );
            }
            if (request.method == 'PUT') {
              photoPutCalls++;
              photoUploadBearer = request.headers['authorization'];
              currentPhoto = updatedPhoto;
              return http.Response.bytes(
                updatedPhoto,
                200,
                headers: {'content-type': 'image/jpeg'},
              );
            }
          }
          throw StateError(
            'Unexpected auth request: ${request.method} ${request.url}',
          );
        },
        onCatalog: (request) async {
          catalogCalls++;
          return _stallPage(_stallIdA, 'Dapur Nusantara');
        },
      );

      expect(catalogCalls, 1);
      expect(cartCalls, 1);

      // Navigate to Profil -> Edit Profil (AuthAccountScreen, triggers 1 GET).
      await _tap(tester, find.text('Profil'));
      await _tap(tester, find.text('Edit Profil'));
      expect(find.byType(AuthAccountScreen), findsOneWidget);
      expect(find.text('Ganti foto profil'), findsOneWidget);
      expect(photoGetCalls, 1);
      _expectAvatarBytes(tester, initialPhoto);

      // Tap "Ganti foto profil" to open native picker.
      await tester.tap(find.text('Ganti foto profil'));
      await tester.pump();

      // Native picker activity transitions inactive -> hidden -> paused -> hidden -> inactive -> resumed.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Catalog splash must NEVER reappear and neither catalog/cart nor photo re-fetches on resume.
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Memuat daftar stan…'), findsNothing);
      expect(find.byType(AuthAccountScreen), findsOneWidget);
      expect(catalogCalls, 1);
      expect(cartCalls, 1);
      expect(photoGetCalls, 1);

      // Complete picking the photo.
      pickerCompleter.complete(
        PickedAvatar(
          name: 'baru.jpg',
          bytes: updatedPhoto,
          mediaType: 'image/jpeg',
        ),
      );
      await tester.pumpAndSettle();

      // Confirm photo replacement dialog is shown on top of Profile screen.
      expect(find.text('Ganti foto profil?'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      await _tap(tester, find.text('Ganti foto'));

      // User remains on Profile screen; photo is updated with refreshed token
      // and exactly 1 PUT + 1 post-PUT GET occurred (no duplicate resume GET).
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Memuat daftar stan…'), findsNothing);
      expect(find.byType(AuthAccountScreen), findsOneWidget);
      expect(photoUploadBearer, 'Bearer token-refreshed');
      expect(catalogCalls, 1);
      expect(cartCalls, 1);
      expect(photoPutCalls, 1);
      expect(photoGetCalls, 2);
      _expectAvatarBytes(tester, updatedPhoto);

      // Back button returns cleanly to CustomerProfilePage, and Beranda stays preserved.
      await _tap(tester, find.byType(BackButton));
      expect(find.byType(AuthAccountScreen), findsNothing);
      await _tap(tester, find.text('Beranda'));
      expect(find.text('Dapur Nusantara'), findsOneWidget);
      expect(catalogCalls, 1);
      expect(cartCalls, 1);
    },
  );

  testWidgets(
    'new AuthSession instance for same account does not trigger catalog startup '
    'while keeping refreshed token for subsequent catalog requests',
    (tester) async {
      final store = MemorySessionStore();
      await store.write(
        SessionTokens.fromJson(
          _sessionJson(accountId: 'acc-1', accessToken: 'token-1'),
        ),
      );
      var meCalls = 0;
      var catalogCalls = 0;
      final catalogAuthHeaders = <String?>[];

      await _launchApp(
        tester,
        store: store,
        onAuth: (request) async {
          if (request.url.path == '/v1/auth/me') {
            meCalls++;
            if (meCalls == 1) {
              return _ok(_accountJson(id: 'acc-1', name: 'Doni'));
            }
            return _error(401, 'INVALID_SESSION');
          }
          if (request.url.path == '/v1/auth/refresh') {
            return _ok({
              ..._sessionJson(accountId: 'acc-1', accessToken: 'token-2'),
              'account': _accountJson(id: 'acc-1', name: 'Doni'),
            });
          }
          throw StateError('Unexpected: ${request.url}');
        },
        onCatalog: (request) async {
          catalogCalls++;
          catalogAuthHeaders.add(request.headers['authorization']);
          return _stallPage(_stallIdA, 'Dapur Nusantara');
        },
      );

      expect(catalogCalls, 1);
      expect(catalogAuthHeaders, ['Bearer token-1']);

      // Trigger background session refresh via resume.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // No catalog splash and no extra startup catalog call.
      expect(find.byType(SplashScreen), findsNothing);
      expect(catalogCalls, 1);

      // Open Cari tab and verify global search uses refreshed session token.
      await _tap(tester, find.text('Cari'));
      await tester.enterText(find.byType(TextField), 'Nasi');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(catalogCalls, 3);
      expect(catalogAuthHeaders, [
        'Bearer token-1',
        'Bearer token-2',
        'Bearer token-2',
      ]);
    },
  );

  testWidgets(
    'logout and login as a different account clears previous catalog and photo cache',
    (tester) async {
      final store = MemorySessionStore();
      await store.write(
        SessionTokens.fromJson(
          _sessionJson(accountId: 'acc-1', accessToken: 'token-a'),
        ),
      );
      final photoA = _validJpegWithTag(10);
      final photoB = _validJpegWithTag(11);

      await _launchApp(
        tester,
        store: store,
        onAuth: (request) async {
          final auth = request.headers['authorization'];
          if (request.url.path == '/v1/auth/logout') return _ok(null);
          if (request.url.path == '/v1/auth/login') {
            return _ok({
              ..._sessionJson(accountId: 'acc-2', accessToken: 'token-b'),
              'account': _accountJson(id: 'acc-2', name: 'Sari'),
            });
          }
          if (request.url.path == '/v1/auth/me') {
            return _ok(_accountJson(id: 'acc-1', name: 'Doni'));
          }
          if (request.url.path == '/v1/auth/profile/photo') {
            return http.Response.bytes(
              auth == 'Bearer token-a' ? photoA : photoB,
              200,
              headers: {'content-type': 'image/jpeg'},
            );
          }
          throw StateError('Unexpected: ${request.url}');
        },
        onCatalog: (request) async {
          final auth = request.headers['authorization'];
          return auth == 'Bearer token-a'
              ? _stallPage(_stallIdA, 'Stan Akun A')
              : _stallPage(_stallIdB, 'Stan Akun B');
        },
      );

      expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
      expect(find.text('Stan Akun A'), findsOneWidget);

      await _tap(tester, find.text('Profil'));
      await _tap(tester, find.text('Edit Profil'));
      _expectAvatarBytes(tester, photoA);
      await _tap(tester, find.text('Keluar'));

      expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'sari@example.test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        'kata sandi panjang 15',
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
      expect(find.text('Stan Akun B'), findsOneWidget);
      expect(find.text('Stan Akun A'), findsNothing);

      await _tap(tester, find.text('Profil'));
      await _tap(tester, find.text('Edit Profil'));
      _expectAvatarBytes(tester, photoB);
    },
  );

  testWidgets(
    'security errors on resume still transition to recovery or login safely',
    (tester) async {
      final store = MemorySessionStore();
      await store.write(
        SessionTokens.fromJson(
          _sessionJson(accountId: 'acc-1', accessToken: 'token-a'),
        ),
      );
      var meCalls = 0;

      await _launchApp(
        tester,
        store: store,
        onAuth: (request) async {
          if (request.url.path == '/v1/auth/me') {
            meCalls++;
            if (meCalls == 1) {
              return _ok(_accountJson(id: 'acc-1', name: 'Doni'));
            }
            return _error(403, 'ACCOUNT_INACTIVE');
          }
          if (request.url.path == '/v1/auth/profile/photo') {
            return http.Response('', 204);
          }
          throw StateError('Unexpected: ${request.url}');
        },
        onCatalog: (_) async => _stallPage(_stallIdA, 'Dapur Nusantara'),
      );

      await _tap(tester, find.text('Profil'));
      await _tap(tester, find.text('Edit Profil'));
      expect(find.byType(AuthAccountScreen), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Sesi belum pulih'), findsOneWidget);
      expect(find.text('Akun ini dinonaktifkan.'), findsOneWidget);
      expect(find.byType(AuthAccountScreen), findsNothing);
    },
  );

  test('accountPhotoProvider reloads when photo is replaced without circular '
      'dependency', () async {
    final store = MemorySessionStore();
    await store.write(SessionTokens.fromJson(_sessionJson(accountId: 'acc-1')));
    var photoVersion = 1;
    final client = MockClient((request) async {
      if (request.url.path == '/v1/auth/me') {
        return _ok(_accountJson(id: 'acc-1', name: 'Doni'));
      }
      if (request.url.path == '/v1/auth/profile/photo') {
        return http.Response.bytes(
          Uint8List.fromList([0xff, 0xd8, 0xff, photoVersion]),
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      }
      throw StateError('Unexpected: ${request.url}');
    });
    addTearDown(client.close);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(
            client: client,
            store: store,
            baseUrl: 'https://api.example.test',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final sub = container.listen(accountPhotoProvider('acc-1'), (_, _) {});
    addTearDown(sub.close);

    expect(
      await container.read(accountPhotoProvider('acc-1').future),
      Uint8List.fromList([0xff, 0xd8, 0xff, 1]),
    );
    photoVersion = 2;
    container.invalidate(accountPhotoProvider('acc-1'));
    expect(
      await container.read(accountPhotoProvider('acc-1').future),
      Uint8List.fromList([0xff, 0xd8, 0xff, 2]),
    );
  });

  testWidgets(
    'stale in-flight photo GET started before PUT cannot overwrite new photo '
    'after upload invalidation and resume',
    (tester) async {
      final store = MemorySessionStore();
      await store.write(
        SessionTokens.fromJson(
          _sessionJson(accountId: 'acc-1', accessToken: 'token-1'),
        ),
      );
      final stalePhoto = _validJpegWithTag(3);
      final freshPhoto = _validJpegWithTag(4);
      final staleGetCompleter = Completer<http.Response>();
      var getCount = 0;
      var putCount = 0;
      var meCount = 0;

      await _launchApp(
        tester,
        store: store,
        pickAvatar: () async => PickedAvatar(
          name: 'fresh.jpg',
          bytes: freshPhoto,
          mediaType: 'image/jpeg',
        ),
        onAuth: (request) async {
          if (request.url.path == '/v1/auth/me') {
            meCount++;
            return _ok(_accountJson(id: 'acc-1', name: 'Doni'));
          }
          if (request.url.path == '/v1/auth/profile/photo') {
            if (request.method == 'GET') {
              getCount++;
              if (getCount == 1) {
                return staleGetCompleter.future;
              }
              return http.Response.bytes(
                freshPhoto,
                200,
                headers: {'content-type': 'image/jpeg'},
              );
            }
            if (request.method == 'PUT') {
              putCount++;
              return http.Response.bytes(
                freshPhoto,
                200,
                headers: {'content-type': 'image/jpeg'},
              );
            }
          }
          throw StateError('Unexpected: ${request.method} ${request.url}');
        },
        onCatalog: (_) async => _stallPage(_stallIdA, 'Dapur Nusantara'),
      );

      // Open Profile while initial GET (#1) is still slow and in flight.
      await _tap(tester, find.text('Profil'));
      await _tap(tester, find.text('Edit Profil'));
      await tester.pump();
      expect(find.byType(AuthAccountScreen), findsOneWidget);
      expect(getCount, 1);

      // Tap replace photo (still labeled 'Tambahkan foto profil' while initial
      // GET #1 is in flight), trigger resume lifecycle, and confirm upload.
      await tester.tap(find.text('Tambahkan foto profil'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Ganti foto profil?'), findsOneWidget);
      await _tap(tester, find.text('Ganti foto'));

      // PUT completed and post-PUT GET (#2) updated CircleAvatar with freshPhoto.
      expect(meCount, 2);
      expect(putCount, 1);
      expect(getCount, 2);
      _expectAvatarBytes(tester, freshPhoto);

      // Now the slow pre-PUT GET (#1) finally returns stalePhoto.
      // It must NOT overwrite freshPhoto in CircleAvatar.
      staleGetCompleter.complete(
        http.Response.bytes(
          stalePhoto,
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      );
      await tester.pumpAndSettle();

      expect(getCount, 2);
      _expectAvatarBytes(tester, freshPhoto);
      expect(find.byType(SplashScreen), findsNothing);
    },
  );
}

void _expectAvatarBytes(WidgetTester tester, Uint8List expected) {
  final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
  final image = avatar.foregroundImage as MemoryImage?;
  expect(image?.bytes, expected);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _launchApp(
  WidgetTester tester, {
  required SessionStore store,
  required Future<http.Response> Function(http.Request) onAuth,
  required Future<http.Response> Function(http.Request) onCatalog,
  AvatarPicker? pickAvatar,
  bool settle = true,
}) async {
  final client = MockClient((request) {
    if (request.url.path.startsWith('/v1/catalog/')) {
      return onCatalog(request);
    }
    if (request.url.path == '/v1/customer/cart' && request.method == 'GET') {
      return onAuth(request).catchError((Object error) {
        if (error is StateError && error.message.startsWith('Unexpected')) {
          return _emptyCart();
        }
        throw error;
      });
    }
    if (request.url.path == '/v1/customer/owner-application' &&
        request.method == 'GET') {
      return Future.value(
        _ok({
          'latest_application': null,
          'active_order_indicator': {
            'has_active_orders': false,
            'active_order_count': 0,
          },
        }),
      );
    }
    return onAuth(request);
  });
  addTearDown(client.close);
  final repository = AuthRepository(
    client: client,
    store: store,
    baseUrl: 'https://api.example.test',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        if (pickAvatar != null)
          avatarPickerProvider.overrideWithValue(pickAvatar),
      ],
      child: const KantinCerdasApp(),
    ),
  );
  if (settle) {
    await tester.pump(_splashMinimum);
    await tester.pumpAndSettle();
  }
}

http.Response _ok(Object? data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);

http.Response _emptyCart() => _ok({
  'stall': null,
  'items': const [],
  'general_note': '',
  'draft_version': 0,
  'subtotal': 0,
  'seen_subtotal': 0,
  'item_count': 0,
  'can_checkout': false,
  'blockers': const [],
});

http.Response _error(int status, String code) => http.Response(
  jsonEncode({
    'success': false,
    'error': {'code': code, 'message': 'upstream detail'},
  }),
  status,
);

http.Response _stallPage(String id, String name) => _ok({
  'items': [
    {
      'id': id,
      'name': name,
      'description': 'Menu makan siang.',
      'block': 'A',
      'wait_minutes': 8,
      'is_open': true,
    },
  ],
  'next_cursor': null,
});

Map<String, Object?> _sessionJson({
  required String accountId,
  String accessToken = 'test-token',
}) => {
  'access_token': accessToken,
  'refresh_token': 'test-refresh',
  'expires_at': '2100-01-01T00:00:00Z',
  'account': _accountJson(id: accountId, name: 'Doni'),
};

Map<String, Object?> _accountJson({required String id, required String name}) =>
    {
      'id': id,
      'email': '$id@example.test',
      'role': 'customer',
      'display_name': name,
      'suggested_name': null,
      'has_photo': true,
      'profile_complete': true,
      'can_manage_credentials': true,
    };

Uint8List _validJpegWithTag(int tag) {
  final base = base64Decode(_fixtureJpeg);
  return Uint8List.fromList([
    base[0],
    base[1],
    0xff,
    0xfe,
    0x00,
    0x03,
    tag,
    ...base.sublist(2),
  ]);
}

const _fixtureJpeg =
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAACAAIDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD//2Q==';
