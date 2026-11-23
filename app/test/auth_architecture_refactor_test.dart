import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/app/routing/app_destination_resolver.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/application/providers/avatar_picker_provider.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_email_link_service.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_profile_service.dart';
import 'package:kantin_cerdas/features/auth/data/auth_email_link.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/data/avatar_picker.dart';
import 'package:kantin_cerdas/features/auth/presentation/forms/auth_profile_form.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/splash_screen.dart';

void main() {
  group('Email deep-link coordinator invariants', () {
    test('deduplicates identical active email links while screen is open and '
        'accepts replay after screen closes', () {
      final token = 'a' * 64;
      final first = AuthEmailLink(AuthEmailAction.recovery, token);
      final duplicateWhileOpen = AuthEmailLink(AuthEmailAction.recovery, token);
      final differentToken = AuthEmailLink(AuthEmailAction.recovery, 'b' * 64);
      final differentAction = AuthEmailLink(AuthEmailAction.signup, token);
      final invalidLink = AuthEmailLink(AuthEmailAction.recovery, null);

      expect(
        shouldAcceptIncomingEmailLink(activeLink: null, incomingLink: null),
        isFalse,
      );
      expect(
        shouldAcceptIncomingEmailLink(activeLink: null, incomingLink: first),
        isTrue,
      );
      expect(
        shouldAcceptIncomingEmailLink(
          activeLink: first,
          incomingLink: duplicateWhileOpen,
        ),
        isFalse,
      );
      expect(
        shouldAcceptIncomingEmailLink(
          activeLink: first,
          incomingLink: differentToken,
        ),
        isTrue,
      );
      expect(
        shouldAcceptIncomingEmailLink(
          activeLink: first,
          incomingLink: differentAction,
        ),
        isTrue,
      );
      expect(
        shouldAcceptIncomingEmailLink(
          activeLink: first,
          incomingLink: invalidLink,
        ),
        isTrue,
      );
      // Once the link screen closes, activeLink is reset to null so replaying
      // the same link is accepted again.
      expect(
        shouldAcceptIncomingEmailLink(
          activeLink: null,
          incomingLink: duplicateWhileOpen,
        ),
        isTrue,
      );
    });

    test('AuthEmailLinkReturnState increments generation and carries notice '
        'and requestNewLink flag on close', () {
      const initial = AuthEmailLinkReturnState();
      expect(initial.emailNotice, isNull);
      expect(initial.requestNewLink, isFalse);
      expect(initial.returnGeneration, 0);

      final afterFirstClose = initial.closeWith(
        notice: 'Password berhasil diperbarui',
        requestNew: false,
      );
      expect(afterFirstClose.emailNotice, 'Password berhasil diperbarui');
      expect(afterFirstClose.requestNewLink, isFalse);
      expect(afterFirstClose.returnGeneration, 1);

      final afterInvalidRecoveryClose = afterFirstClose.closeWith(
        notice: null,
        requestNew: true,
      );
      expect(afterInvalidRecoveryClose.emailNotice, isNull);
      expect(afterInvalidRecoveryClose.requestNewLink, isTrue);
      expect(afterInvalidRecoveryClose.returnGeneration, 2);
    });
  });

  group('AuthController application use-case orchestration', () {
    test('completeRegistrationProfile uploads picked avatar before completing '
        'profile and updates session state', () async {
      final calls = <String>[];
      final store = MemorySessionStore();
      await store.write(SessionTokens.fromJson(_sessionJson(complete: false)));

      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path == '/v1/auth/me') {
          return _ok(_accountJson(name: null, complete: false));
        }
        if (request.url.path == '/v1/auth/profile/photo' &&
            request.method == 'PUT') {
          expect(request.headers['content-type'], 'image/jpeg');
          return http.Response.bytes(
            Uint8List.fromList([0xff, 0xd8, 0xff]),
            200,
            headers: {'content-type': 'image/jpeg'},
          );
        }
        if (request.url.path == '/v1/auth/profile' && request.method == 'PUT') {
          expect(jsonDecode(request.body), {'display_name': 'Doni'});
          return _ok(_accountJson(name: 'Doni', complete: true));
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
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

      final initial = await container.read(authControllerProvider.future);
      expect(initial?.account.profileComplete, isFalse);

      await container
          .read(authProfileServiceProvider)
          .completeRegistrationProfile(
            accountId: 'test-account',
            displayName: 'Doni',
            photo: PickedAvatar(
              name: 'avatar.jpg',
              bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
              mediaType: 'image/jpeg',
            ),
          );

      final updated = container.read(authControllerProvider).asData?.value;
      expect(updated?.account.displayName, 'Doni');
      expect(updated?.account.profileComplete, isTrue);
      expect(calls, [
        'GET /v1/auth/me',
        'PUT /v1/auth/profile/photo',
        'PUT /v1/auth/profile',
      ]);
    });

    testWidgets(
      'disposing AuthProfileForm while avatar upload is in flight aborts '
      'subsequent completeProfile call',
      (tester) async {
        final calls = <String>[];
        final uploadStarted = Completer<void>();
        final uploadResponse = Completer<http.Response>();
        final store = MemorySessionStore();
        await store.write(
          SessionTokens.fromJson(_sessionJson(complete: false)),
        );

        final client = MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.url.path == '/v1/auth/me') {
            return _ok(_accountJson(name: 'Doni', complete: false));
          }
          if (request.url.path == '/v1/auth/profile/photo' &&
              request.method == 'PUT') {
            uploadStarted.complete();
            return uploadResponse.future;
          }
          if (request.url.path == '/v1/auth/profile' &&
              request.method == 'PUT') {
            return _ok(_accountJson(name: 'Doni', complete: true));
          }
          throw StateError(
            'Unexpected request: ${request.method} ${request.url}',
          );
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
            avatarPickerProvider.overrideWithValue(
              () async => PickedAvatar(
                name: 'foto.jpg',
                bytes: Uint8List.fromList(_validJpegBytes),
                mediaType: 'image/jpeg',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final session = await container.read(authControllerProvider.future);
        expect(session, isNotNull);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: AuthProfileForm(account: session!.account),
            ),
          ),
        );

        await tester.tap(find.text('Pilih foto profil'));
        await tester.pumpAndSettle();
        expect(find.text('foto.jpg'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Selesaikan Pendaftaran'),
        );
        await tester.pump();
        await uploadStarted.future;

        // Dispose AuthProfileForm while avatar upload is still in flight.
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SizedBox.shrink()),
          ),
        );

        uploadResponse.complete(
          http.Response.bytes(
            Uint8List.fromList(_validJpegBytes),
            200,
            headers: {'content-type': 'image/jpeg'},
          ),
        );
        await tester.pumpAndSettle();

        expect(calls, ['GET /v1/auth/me', 'PUT /v1/auth/profile/photo']);
        expect(
          container
              .read(authControllerProvider)
              .asData
              ?.value
              ?.account
              .profileComplete,
          isFalse,
        );
      },
    );

    test(
      'completeRegistrationProfile imports Google avatar when useGooglePhoto '
      'is true and no custom photo is picked',
      () async {
        final calls = <String>[];
        final store = MemorySessionStore();
        await store.write(
          SessionTokens.fromJson(_sessionJson(complete: false)),
        );

        final client = MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          return switch ((request.method, request.url.path)) {
            ('GET', '/v1/auth/me') => _ok(
              _accountJson(
                name: null,
                complete: false,
                googlePhoto: 'https://lh3.googleusercontent.com/a/test',
              ),
            ),
            ('POST', '/v1/auth/profile/photo/google') => http.Response('', 204),
            ('PUT', '/v1/auth/profile') => _ok(
              _accountJson(name: 'Doni Google', complete: true),
            ),
            _ => throw StateError(
              'Unexpected: ${request.method} ${request.url}',
            ),
          };
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
        await container
            .read(authProfileServiceProvider)
            .completeRegistrationProfile(
              accountId: 'test-account',
              displayName: 'Doni Google',
              useGooglePhoto: true,
            );

        expect(calls, [
          'GET /v1/auth/me',
          'POST /v1/auth/profile/photo/google',
          'PUT /v1/auth/profile',
        ]);
        expect(
          container
              .read(authControllerProvider)
              .asData
              ?.value
              ?.account
              .displayName,
          'Doni Google',
        );
      },
    );

    test('updateDisplayName, replaceProfilePhoto, and changeAccountCredentials '
        'enforce active session ownership, invalidate photo cache, and call '
        'repository contracts', () async {
      final calls = <String>[];
      final store = MemorySessionStore();
      await store.write(SessionTokens.fromJson(_sessionJson(complete: true)));

      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        return switch ((request.method, request.url.path)) {
          ('GET', '/v1/auth/me') => _ok(
            _accountJson(name: 'Doni', complete: true),
          ),
          ('PUT', '/v1/auth/profile') => _ok(
            _accountJson(name: 'Doni Baru', complete: true),
          ),
          ('GET', '/v1/auth/profile/photo') => http.Response('', 204),
          ('PUT', '/v1/auth/profile/photo') => http.Response.bytes(
            Uint8List.fromList([0xff, 0xd8, 0xff]),
            200,
            headers: {'content-type': 'image/jpeg'},
          ),
          ('POST', '/v1/auth/account/email') => _ok(null),
          ('POST', '/v1/auth/account/password') => _ok(null),
          _ => throw StateError('Unexpected: ${request.method} ${request.url}'),
        };
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
      final photoSub = container.listen(
        accountPhotoProvider('test-account'),
        (_, _) {},
      );
      addTearDown(photoSub.close);
      await container.read(accountPhotoProvider('test-account').future);
      final profileService = container.read(authProfileServiceProvider);

      await expectLater(
        () => profileService.changeAccountCredentials(
          accountId: 'wrong-account',
          currentPassword: 'secret-password-15',
          email: 'baru@example.test',
        ),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'INVALID_SESSION'),
        ),
      );

      await profileService.updateDisplayName('test-account', 'Doni Baru');
      expect(
        container
            .read(authControllerProvider)
            .asData
            ?.value
            ?.account
            .displayName,
        'Doni Baru',
      );
      await container.read(accountPhotoProvider('test-account').future);

      await profileService.replaceProfilePhoto(
        'test-account',
        PickedAvatar(
          name: 'foto.jpg',
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
          mediaType: 'image/jpeg',
        ),
      );
      await container.read(accountPhotoProvider('test-account').future);
      await profileService.changeAccountCredentials(
        accountId: 'test-account',
        currentPassword: 'secret-password-15',
        email: 'baru@example.test',
      );
      await profileService.changeAccountCredentials(
        accountId: 'test-account',
        currentPassword: 'secret-password-15',
        password: 'new-secret-password-15',
      );

      expect(calls, [
        'GET /v1/auth/me',
        'GET /v1/auth/profile/photo',
        'PUT /v1/auth/profile',
        'PUT /v1/auth/profile/photo',
        'GET /v1/auth/profile/photo',
        'POST /v1/auth/account/email',
        'POST /v1/auth/account/password',
      ]);
    });
  });

  group('App destination resolver', () {
    test('resolveAppDestination returns pure destination values for every auth '
        'state and role without constructing widgets', () {
      expect(
        resolveAppDestination(session: const AsyncLoading()),
        isA<AppSplashDestination>().having(
          (d) => d.phase,
          'phase',
          SplashPhase.session,
        ),
      );
      expect(
        resolveAppDestination(
          session: AsyncError(StateError('boom'), StackTrace.empty),
        ),
        isA<AppSessionRecoveryDestination>(),
      );
      expect(
        resolveAppDestination(session: const AsyncData(null)),
        isA<AppCredentialsDestination>(),
      );

      final incompleteSession = AuthSession(
        SessionTokens.fromJson(_sessionJson(complete: false)),
        AuthAccount.fromJson(_accountJson(name: null, complete: false)),
      );
      expect(
        resolveAppDestination(session: AsyncData(incompleteSession)),
        isA<AppProfileCompletionDestination>(),
      );

      final customerSession = AuthSession(
        SessionTokens.fromJson(_sessionJson(complete: true)),
        AuthAccount.fromJson(_accountJson(name: 'Doni', complete: true)),
      );
      expect(
        resolveAppDestination(session: AsyncData(customerSession)),
        isA<AppCustomerHomeDestination>(),
      );

      final ownerSession = AuthSession(
        SessionTokens.fromJson(_sessionJson(complete: true)),
        AuthAccount.fromJson({
          ..._accountJson(name: 'Owner', complete: true),
          'role': 'owner',
        }),
      );
      expect(
        resolveAppDestination(
          session: AsyncData(ownerSession),
          ownerCustomerView: false,
        ),
        isA<AppOwnerHomeDestination>(),
      );
      expect(
        resolveAppDestination(
          session: AsyncData(ownerSession),
          ownerCustomerView: true,
        ),
        isA<AppCustomerHomeDestination>(),
      );
    });
  });

  group('Layer boundary architecture rules', () {
    test('presentation files do not import AuthRepository, AuthApiTransport, '
        'AuthSessionCoordinator, or requireAccountSession directly', () {
      final presentationDir = Directory('lib/features/auth/presentation');
      final dartFiles = presentationDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          isNot(contains('auth_repository.dart')),
          reason: '${file.path} must not import auth_repository.dart directly',
        );
        expect(
          content,
          isNot(contains('auth_api_transport.dart')),
          reason: '${file.path} must not import auth_api_transport.dart',
        );
        expect(
          content,
          isNot(contains('auth_session_coordinator.dart')),
          reason: '${file.path} must not import auth_session_coordinator.dart',
        );
        expect(
          content,
          isNot(contains('require_account_session.dart')),
          reason: '${file.path} must not enforce session guard directly in UI',
        );
      }
    });

    test('data layer does not import presentation or application layers', () {
      final dataDir = Directory('lib/features/auth/data');
      final dartFiles = dataDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          isNot(contains('features/auth/presentation/')),
          reason: '${file.path} must not import presentation layer',
        );
        expect(
          content,
          isNot(contains('features/auth/application/')),
          reason: '${file.path} must not import application layer',
        );
        expect(
          content,
          isNot(contains('package:kantin_cerdas/app/')),
          reason: '${file.path} must not import app navigation layer',
        );
        expect(
          content,
          isNot(contains('flutter_riverpod')),
          reason: '${file.path} must not depend on flutter_riverpod',
        );
      }
    });
  });
}

http.Response _ok(Object? data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);

Map<String, Object?> _sessionJson({required bool complete}) => {
  'access_token': 'test-token',
  'refresh_token': 'test-refresh',
  'expires_at': '2100-01-01T00:00:00Z',
  'account': _accountJson(name: complete ? 'Doni' : null, complete: complete),
};

Map<String, Object?> _accountJson({
  required String? name,
  required bool complete,
  String? googlePhoto,
}) => {
  'id': 'test-account',
  'email': 'doni@example.test',
  'role': 'customer',
  'display_name': name,
  'suggested_name': name == null ? 'Doni Draft' : null,
  'has_photo': complete,
  'profile_complete': complete,
  'google_photo': googlePhoto,
  'can_manage_credentials': true,
};

const _validJpegBytes = <int>[
  0xff,
  0xd8,
  0xff,
  0xe0,
  0x00,
  0x10,
  0x4a,
  0x46,
  0x49,
  0x46,
  0x00,
  0x01,
  0x01,
  0x01,
  0x00,
  0x48,
  0x00,
  0x48,
  0x00,
  0x00,
  0xff,
  0xdb,
  0x00,
  0x43,
  0x00,
  0x08,
  0x06,
  0x06,
  0x07,
  0x06,
  0x05,
  0x08,
  0x07,
  0x07,
  0x07,
  0x09,
  0x09,
  0x08,
  0x0a,
  0x0c,
  0x14,
  0x0d,
  0x0c,
  0x0b,
  0x0b,
  0x0c,
  0x19,
  0x12,
  0x13,
  0x0f,
  0x14,
  0x1d,
  0x1a,
  0x1f,
  0x1e,
  0x1d,
  0x1a,
  0x1c,
  0x1c,
  0x20,
  0x24,
  0x2e,
  0x27,
  0x20,
  0x22,
  0x2c,
  0x23,
  0x1c,
  0x1c,
  0x28,
  0x37,
  0x29,
  0x2c,
  0x30,
  0x31,
  0x34,
  0x34,
  0x34,
  0x1f,
  0x27,
  0x39,
  0x3d,
  0x38,
  0x32,
  0x3c,
  0x2e,
  0x33,
  0x34,
  0x32,
  0xff,
  0xc0,
  0x00,
  0x0b,
  0x08,
  0x00,
  0x01,
  0x00,
  0x01,
  0x01,
  0x01,
  0x11,
  0x00,
  0xff,
  0xc4,
  0x00,
  0x14,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x08,
  0xff,
  0xc4,
  0x00,
  0x14,
  0x10,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0xff,
  0xda,
  0x00,
  0x08,
  0x01,
  0x01,
  0x00,
  0x00,
  0x3f,
  0x00,
  0x7f,
  0x00,
  0xff,
  0xd9,
];
