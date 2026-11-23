import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/app/auth_view.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_repository.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/catalog/application/catalog_providers.dart';
import 'package:kantin_cerdas/features/catalog/data/catalog_repository.dart'
    show CatalogRepository;
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_repository.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_detail_page.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/notifications/data/push_device_bridge.dart';
import 'package:kantin_cerdas/features/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas/features/notifications/domain/notifications_repository.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_messaging_client.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_notification_payload.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_repository.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_order_detail_page.dart';
import 'package:kantin_cerdas/theme/kc_theme.dart';

const _custAId = '10000000-0000-4000-8000-000000000801';
const _custBId = '10000000-0000-4000-8000-000000000802';
const _ownerAId = '20000000-0000-4000-8000-000000000801';
const _adminId = '30000000-0000-4000-8000-000000000801';
const _stallAId = '40000000-0000-4000-8000-000000000801';
const _order1Id = '50000000-0000-4000-8000-000000000801';

void main() {
  group('PushNotificationPayload & ORDER-017A strict filtering', () {
    test(
      'accepts exactly the 7 ORDER-017A push events and rejects selesai, gagal_diambil, admin, or role mismatch',
      () {
        const validCases = <({String event, String role})>[
          (event: 'order_created', role: 'owner'),
          (event: 'order_cancelled', role: 'owner'),
          (event: 'order_accepted', role: 'customer'),
          (event: 'order_rejected', role: 'customer'),
          (event: 'order_ready', role: 'customer'),
          (event: 'order_failed_fulfill', role: 'customer'),
          (event: 'order_not_picked_up', role: 'customer'),
        ];

        for (final c in validCases) {
          final parsed = PushNotificationPayload.tryParseRemoteData({
            'event_id': 'evt-${c.event}',
            'event_type': c.event,
            'order_id': _order1Id,
            'order_number': '00042',
            'recipient_role': c.role,
          });
          expect(
            parsed,
            isNotNull,
            reason: 'Expected valid payload for ${c.event}',
          );
          expect(parsed!.orderId, _order1Id);
          expect(parsed.targetRole.wireValue, c.role);
        }

        const rejectedCases = <Map<String, dynamic>>[
          {
            'event_type': 'selesai',
            'order_id': _order1Id,
            'recipient_role': 'customer',
          },
          {
            'event_type': 'gagal_diambil',
            'order_id': _order1Id,
            'recipient_role': 'customer',
          },
          {
            'event_type': 'order_created',
            'order_id': _order1Id,
            'recipient_role': 'admin',
          },
          {
            'event_type': 'order_created',
            'order_id': _order1Id,
            'recipient_role': 'customer', // mismatch
          },
          {
            'event_type': 'order_ready',
            'order_id': _order1Id,
            'recipient_role': 'owner', // mismatch
          },
          {
            'event_type': 'order_ready',
            'order_id': '',
            'recipient_role': 'customer',
          },
        ];

        for (final raw in rejectedCases) {
          expect(
            PushNotificationPayload.tryParseRemoteData(raw),
            isNull,
            reason: 'Payload must be rejected: $raw',
          );
        }
      },
    );

    test(
      'resolveAuthorizedPushDestination blocks unauthenticated, incomplete profile, Admin, and Customer->Owner escalation',
      () {
        final custPayload = _payload('evt-1', PushOrderEventType.orderReady);
        final ownerPayload = _payload('evt-2', PushOrderEventType.orderCreated);

        expect(
          resolveAuthorizedPushDestination(session: null, payload: custPayload),
          isNull,
        );

        final incompleteCust = _makeSession(
          id: _custAId,
          email: 'inc@example.test',
          role: AuthRole.customer,
          profileComplete: false,
        );
        expect(
          resolveAuthorizedPushDestination(
            session: incompleteCust,
            payload: custPayload,
          ),
          isNull,
        );

        final adminSession = _makeSession(
          id: _adminId,
          email: 'admin@example.test',
          role: AuthRole.admin,
        );
        expect(
          resolveAuthorizedPushDestination(
            session: adminSession,
            payload: custPayload,
          ),
          isNull,
        );
        expect(
          resolveAuthorizedPushDestination(
            session: adminSession,
            payload: ownerPayload,
          ),
          isNull,
        );

        final custSession = _makeSession(
          id: _custAId,
          email: 'cust@example.test',
          role: AuthRole.customer,
        );
        expect(
          resolveAuthorizedPushDestination(
            session: custSession,
            payload: ownerPayload,
          ),
          isNull,
        );
        expect(
          resolveAuthorizedPushDestination(
            session: custSession,
            payload: custPayload,
          )?.orderId,
          _order1Id,
        );

        final ownerSession = _makeSession(
          id: _ownerAId,
          email: 'owner@example.test',
          role: AuthRole.owner,
        );
        expect(
          resolveAuthorizedPushDestination(
            session: ownerSession,
            payload: ownerPayload,
          )?.targetRole,
          PushTargetRole.owner,
        );
      },
    );
  });

  group('FirebasePushTokenSource & RealtimeOrderSyncNotifier token lifecycle', () {
    test(
      'registers initial token, updates backend on token refresh, skips duplicate token, and revokes on logout',
      () async {
        final session = _makeSession(
          id: _custAId,
          email: 'cust-a@example.test',
          role: AuthRole.customer,
        );
        final fakeClient = _FakePushMessagingClient(
          initialized: true,
          permission: PushPermissionOutcome.granted,
          initialToken: 'fcm_initial_token_00000000000001',
        );
        final fakeNotifRepo = _FakeNotificationsRepo(role: 'customer');

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_makeAuthRepo(session)),
            notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
            pushMessagingClientProvider.overrideWithValue(fakeClient),
            pushTokenSourceProvider.overrideWithValue(
              FirebasePushTokenSource(client: fakeClient),
            ),
            realtimeReconnectBackoffProvider.overrideWithValue(const [
              Duration(milliseconds: 20),
            ]),
          ],
        );
        addTearDown(() {
          fakeClient.dispose();
          container.dispose();
        });

        await container.read(authControllerProvider.future);
        final sub = container.listen(
          realtimeOrderSyncProvider(_custAId),
          (_, _) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(fakeNotifRepo.registrations.length, 1);
        expect(
          fakeNotifRepo.registrations.single.fcmToken,
          'fcm_initial_token_00000000000001',
        );
        final deviceId = fakeNotifRepo.registrations.single.deviceId;

        // Duplicate refresh with identical token -> no extra API call
        fakeClient.emitTokenRefresh('fcm_initial_token_00000000000001');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(fakeNotifRepo.registrations.length, 1);

        // Rotated token -> re-registers cleanly with same deviceId
        fakeClient.emitTokenRefresh('fcm_rotated_token_00000000000002');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(fakeNotifRepo.registrations.length, 2);
        expect(fakeNotifRepo.registrations.last.deviceId, deviceId);
        expect(
          fakeNotifRepo.registrations.last.fcmToken,
          'fcm_rotated_token_00000000000002',
        );

        // Logout revokes device binding and stops token refresh listener
        await container.read(authControllerProvider.notifier).logout();
        expect(fakeNotifRepo.revokedDeviceIds, [deviceId]);

        fakeClient.emitTokenRefresh('fcm_post_logout_token_00000000003');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(fakeNotifRepo.registrations.length, 2);
        sub.close();
      },
    );

    test(
      'permission denial skips push registration while realtime SSE continues unaffected',
      () async {
        final session = _makeSession(
          id: _custAId,
          email: 'cust-a@example.test',
          role: AuthRole.customer,
        );
        final fakeClient = _FakePushMessagingClient(
          initialized: true,
          permission: PushPermissionOutcome.denied,
          initialToken: 'fcm_should_never_be_registered_01',
        );
        final fakeNotifRepo = _FakeNotificationsRepo(role: 'customer');

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_makeAuthRepo(session)),
            notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
            pushMessagingClientProvider.overrideWithValue(fakeClient),
            pushTokenSourceProvider.overrideWithValue(
              FirebasePushTokenSource(client: fakeClient),
            ),
          ],
        );
        addTearDown(() {
          fakeClient.dispose();
          container.dispose();
        });

        await container.read(authControllerProvider.future);
        final sub = container.listen(
          realtimeOrderSyncProvider(_custAId),
          (_, _) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(fakeNotifRepo.registrations, isEmpty);
        expect(
          container.read(realtimeOrderSyncProvider(_custAId)).mode,
          RealtimeConnectionMode.live,
        );

        // Token refresh while permission denied must NOT register either
        fakeClient.emitTokenRefresh('fcm_denied_refresh_token_00000001');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(fakeNotifRepo.registrations, isEmpty);
        sub.close();
      },
    );

    test(
      'Firebase initialization failure (missing google-services.json) degrades gracefully without crashing',
      () async {
        final session = _makeSession(
          id: _custAId,
          email: 'cust-a@example.test',
          role: AuthRole.customer,
        );
        final fakeClient = _FakePushMessagingClient(
          initialized: false,
          permission: PushPermissionOutcome.unavailable,
          initialToken: null,
        );
        final fakeNotifRepo = _FakeNotificationsRepo(role: 'customer');

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_makeAuthRepo(session)),
            notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
            pushMessagingClientProvider.overrideWithValue(fakeClient),
            pushTokenSourceProvider.overrideWithValue(
              FirebasePushTokenSource(client: fakeClient),
            ),
          ],
        );
        addTearDown(() {
          fakeClient.dispose();
          container.dispose();
        });

        await container.read(authControllerProvider.future);
        final sub = container.listen(
          realtimeOrderSyncProvider(_custAId),
          (_, _) {},
        );
        final coordSub = container.listen(
          pushNotificationCoordinatorProvider,
          (_, _) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(fakeNotifRepo.registrations, isEmpty);
        expect(
          container.read(pushNotificationCoordinatorProvider).initialized,
          isFalse,
        );
        expect(
          container.read(realtimeOrderSyncProvider(_custAId)).mode,
          RealtimeConnectionMode.live,
        );
        sub.close();
        coordSub.close();
      },
    );

    test(
      'account switch detaches previous account and clears stale pending push navigation',
      () async {
        final sessionA = _makeSession(
          id: _custAId,
          email: 'cust-a@example.test',
          role: AuthRole.customer,
        );
        final sessionB = _makeSession(
          id: _custBId,
          email: 'cust-b@example.test',
          role: AuthRole.customer,
        );
        final fakeClient = _FakePushMessagingClient(
          initialized: true,
          permission: PushPermissionOutcome.granted,
          initialToken: 'fcm_shared_device_token_00000001',
        );
        final fakeNotifRepo = _FakeNotificationsRepo(role: 'customer');
        final tokenSource = FirebasePushTokenSource(client: fakeClient);

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _makeSwitchableAuthRepo(initial: sessionA, nextLogin: sessionB),
            ),
            notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
            pushMessagingClientProvider.overrideWithValue(fakeClient),
            pushTokenSourceProvider.overrideWithValue(tokenSource),
          ],
        );
        addTearDown(() {
          fakeClient.dispose();
          container.dispose();
        });

        await container.read(authControllerProvider.future);
        final syncA = container.listen(
          realtimeOrderSyncProvider(_custAId),
          (_, _) {},
        );
        final coordSub = container.listen(
          pushNotificationCoordinatorProvider,
          (_, _) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(fakeNotifRepo.registrations.length, 1);
        expect(fakeNotifRepo.registrations.last.accountId, _custAId);

        // Queue a pending tap under Account A, then log out before it is consumed
        fakeClient.emitMessageOpenedApp(
          _payload('evt-stale-a', PushOrderEventType.orderReady),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          container.read(pushNotificationCoordinatorProvider).pendingNavigation,
          isNotNull,
        );

        await container.read(authControllerProvider.notifier).logout();
        container
            .read(pushNotificationCoordinatorProvider.notifier)
            .clearForSessionChange();
        syncA.close();

        expect(fakeNotifRepo.revokedDeviceIds.length, 1);
        expect(
          container.read(pushNotificationCoordinatorProvider).pendingNavigation,
          isNull,
        );

        // Login as Customer B -> registers device under Account B (never leaks A)
        await container
            .read(authControllerProvider.notifier)
            .login('cust-b@example.test', 'Pass1234!');
        final syncB = container.listen(
          realtimeOrderSyncProvider(_custBId),
          (_, _) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(fakeNotifRepo.registrations.length, 2);
        expect(fakeNotifRepo.registrations.last.accountId, _custBId);
        syncB.close();
        coordSub.close();
      },
    );
  });

  group(
    'Foreground, background tap, deduplication & navigation authorization in AuthView',
    () {
      testWidgets(
        'unauthenticated notification tap is blocked and stays on Login',
        (tester) async {
          final fakeClient = _FakePushMessagingClient(
            initialized: true,
            permission: PushPermissionOutcome.granted,
            initialMessage: _payload(
              'evt-cold-unauth',
              PushOrderEventType.orderReady,
            ),
          );
          addTearDown(fakeClient.dispose);

          await _pumpAuthView(tester, session: null, pushClient: fakeClient);
          await tester.pumpAndSettle();

          expect(find.byType(CustomerOrderDetailPage), findsNothing);
          expect(find.byType(OwnerOrderDetailPage), findsNothing);
          expect(find.text('Masuk'), findsWidgets);
        },
      );

      testWidgets('Admin notification tap is blocked (ADMIN-005)', (
        tester,
      ) async {
        final adminSession = _makeSession(
          id: _adminId,
          email: 'admin@example.test',
          role: AuthRole.admin,
        );
        final fakeClient = _FakePushMessagingClient(
          initialized: true,
          permission: PushPermissionOutcome.granted,
          initialMessage: _payload(
            'evt-admin-tap',
            PushOrderEventType.orderCreated,
          ),
        );
        addTearDown(fakeClient.dispose);

        await _pumpAuthView(
          tester,
          session: adminSession,
          pushClient: fakeClient,
        );
        await tester.pumpAndSettle();

        expect(find.byType(CustomerOrderDetailPage), findsNothing);
        expect(find.byType(OwnerOrderDetailPage), findsNothing);
      });

      testWidgets(
        'Customer tapping Owner notification is blocked; Customer notification opens CustomerOrderDetailPage & deduplicates foreground notices',
        (tester) async {
          final custSession = _makeSession(
            id: _custAId,
            email: 'cust-a@example.test',
            role: AuthRole.customer,
          );
          final fakeClient = _FakePushMessagingClient(
            initialized: true,
            permission: PushPermissionOutcome.granted,
          );
          final fakeCustomerRepo = _FakeCustomerRepo();
          addTearDown(fakeClient.dispose);

          await _pumpAuthView(
            tester,
            session: custSession,
            pushClient: fakeClient,
            customerRepo: fakeCustomerRepo,
          );
          await tester.pumpAndSettle();

          // 1. Customer receives Owner-targeted tap -> MUST be blocked!
          fakeClient.emitMessageOpenedApp(
            _payload('evt-owner-only', PushOrderEventType.orderCreated),
          );
          await tester.pumpAndSettle();
          expect(find.byType(OwnerOrderDetailPage), findsNothing);
          expect(find.byType(CustomerOrderDetailPage), findsNothing);

          // 2. Foreground Customer notification -> shows SnackBar once & deduplicates replay
          final fgPayload = _payload(
            'evt-fg-ready',
            PushOrderEventType.orderReady,
          );
          fakeClient.emitForegroundMessage(fgPayload);
          fakeClient.emitForegroundMessage(
            fgPayload,
          ); // duplicate event_id ignored
          await tester.pumpAndSettle();
          expect(find.textContaining('Pesanan siap diambil'), findsOneWidget);
          expect(find.text('Lihat'), findsOneWidget);

          // 3. Tapping background notification for Customer -> opens existing CustomerOrderDetailPage
          fakeClient.emitMessageOpenedApp(
            _payload('evt-open-cust', PushOrderEventType.orderReady),
          );
          await tester.pumpAndSettle();
          expect(find.byType(CustomerOrderDetailPage), findsOneWidget);
          expect(fakeCustomerRepo.detailFetchCount, greaterThanOrEqualTo(1));
        },
      );

      testWidgets(
        'Owner tapping Owner notification (cold-start getInitialMessage) opens existing OwnerOrderDetailPage',
        (tester) async {
          final ownerSession = _makeSession(
            id: _ownerAId,
            email: 'owner-a@example.test',
            role: AuthRole.owner,
          );
          final fakeClient = _FakePushMessagingClient(
            initialized: true,
            permission: PushPermissionOutcome.granted,
            initialMessage: _payload(
              'evt-cold-owner',
              PushOrderEventType.orderCreated,
            ),
          );
          final fakeOwnerRepo = _FakeOwnerRepo();
          addTearDown(fakeClient.dispose);

          await _pumpAuthView(
            tester,
            session: ownerSession,
            pushClient: fakeClient,
            ownerRepo: fakeOwnerRepo,
          );
          await tester.pumpAndSettle();

          expect(find.byType(OwnerOrderDetailPage), findsOneWidget);
          expect(fakeOwnerRepo.detailFetchCount, greaterThanOrEqualTo(1));
        },
      );
    },
  );
}

// =============================================================================
// Helpers & Fakes
// =============================================================================
PushNotificationPayload _payload(String eventId, PushOrderEventType type) {
  return PushNotificationPayload.tryParseRemoteData({
    'event_id': eventId,
    'event_type': type.wireValue,
    'order_id': _order1Id,
    'order_number': '00042',
    'recipient_role': type.expectedRole.wireValue,
  })!;
}

Future<void> _pumpAuthView(
  WidgetTester tester, {
  required AuthSession? session,
  required _FakePushMessagingClient pushClient,
  _FakeCustomerRepo? customerRepo,
  _FakeOwnerRepo? ownerRepo,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final fakeNotifRepo = _FakeNotificationsRepo(
    role: session?.account.role == AuthRole.owner ? 'owner' : 'customer',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_makeAuthRepo(session)),
        catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepo()),
        customerRepositoryProvider.overrideWithValue(
          customerRepo ?? _FakeCustomerRepo(),
        ),
        ownerRepositoryProvider.overrideWithValue(
          ownerRepo ?? _FakeOwnerRepo(),
        ),
        adminRepositoryProvider.overrideWithValue(_FakeAdminRepo()),
        notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
        pushMessagingClientProvider.overrideWithValue(pushClient),
        pushTokenSourceProvider.overrideWithValue(
          FirebasePushTokenSource(client: pushClient),
        ),
      ],
      child: MaterialApp(theme: KcTheme.light, home: const AuthView()),
    ),
  );
  // Advance past SplashTransition minimum 3s display
  await tester.pump(const Duration(milliseconds: 3200));
  await tester.pumpAndSettle();
}

AuthSession _makeSession({
  required String id,
  required String email,
  required AuthRole role,
  bool profileComplete = true,
}) {
  return AuthSession(
    SessionTokens.fromJson({
      'access_token': 'jwt-$id',
      'refresh_token': 'ref-$id',
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String(),
      'account_id': id,
    }),
    AuthAccount.fromJson({
      'id': id,
      'email': email,
      'display_name': profileComplete ? 'Test User' : null,
      'role': role.name,
      'has_photo': profileComplete,
      'profile_complete': profileComplete,
      'can_manage_credentials': true,
    }),
  );
}

AuthRepository _makeAuthRepo(AuthSession? session) {
  final store = MemorySessionStore();
  if (session != null) store.write(session.tokens);
  final client = MockClient((request) async {
    if (request.url.path.endsWith('/v1/auth/me') && session != null) {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'id': session.account.id,
            'email': session.account.email,
            'display_name': session.account.displayName,
            'role': session.account.role.name,
            'has_photo': session.account.hasPhoto,
            'profile_complete': session.account.profileComplete,
            'can_manage_credentials': true,
          },
        }),
        200,
      );
    }
    if (request.url.path.endsWith('/v1/auth/logout')) {
      return http.Response(jsonEncode({'success': true, 'data': null}), 200);
    }
    return http.Response(
      jsonEncode({
        'success': false,
        'error': {'code': 'ROUTE_NOT_FOUND', 'message': 'not found'},
      }),
      404,
    );
  });
  return AuthRepository(
    client: client,
    store: store,
    baseUrl: 'https://api.example.test',
  );
}

AuthRepository _makeSwitchableAuthRepo({
  required AuthSession initial,
  required AuthSession nextLogin,
}) {
  final store = MemorySessionStore()..write(initial.tokens);
  final client = MockClient((request) async {
    if (request.url.path.endsWith('/v1/auth/me')) {
      final token = request.headers['authorization'] ?? '';
      final active = token.contains(nextLogin.account.id) ? nextLogin : initial;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'id': active.account.id,
            'email': active.account.email,
            'display_name': active.account.displayName,
            'role': active.account.role.name,
            'has_photo': true,
            'profile_complete': true,
            'can_manage_credentials': true,
          },
        }),
        200,
      );
    }
    if (request.url.path.endsWith('/v1/auth/login')) {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'access_token': nextLogin.tokens.accessToken,
            'refresh_token': nextLogin.tokens.refreshToken,
            'expires_at': nextLogin.tokens.expiresAt.toIso8601String(),
            'account': {
              'id': nextLogin.account.id,
              'email': nextLogin.account.email,
              'display_name': nextLogin.account.displayName,
              'role': nextLogin.account.role.name,
              'has_photo': true,
              'profile_complete': true,
              'can_manage_credentials': true,
            },
          },
        }),
        200,
      );
    }
    if (request.url.path.endsWith('/v1/auth/logout')) {
      return http.Response(jsonEncode({'success': true, 'data': null}), 200);
    }
    return http.Response(
      jsonEncode({
        'success': false,
        'error': {'code': 'ROUTE_NOT_FOUND', 'message': 'not found'},
      }),
      404,
    );
  });
  return AuthRepository(
    client: client,
    store: store,
    baseUrl: 'https://api.example.test',
  );
}

class _FakePushMessagingClient implements PushMessagingClient {
  _FakePushMessagingClient({
    required this.initialized,
    required this.permission,
    this.initialToken,
    this.initialMessage,
  });

  final bool initialized;
  final PushPermissionOutcome permission;
  final String? initialToken;
  PushNotificationPayload? initialMessage;

  final _tokenRefreshCtrl = StreamController<String>.broadcast();
  final _foregroundCtrl = StreamController<PushNotificationPayload>.broadcast();
  final _openedCtrl = StreamController<PushNotificationPayload>.broadcast();

  void emitTokenRefresh(String token) => _tokenRefreshCtrl.add(token);
  void emitForegroundMessage(PushNotificationPayload payload) =>
      _foregroundCtrl.add(payload);
  void emitMessageOpenedApp(PushNotificationPayload payload) =>
      _openedCtrl.add(payload);

  void dispose() {
    unawaited(_tokenRefreshCtrl.close());
    unawaited(_foregroundCtrl.close());
    unawaited(_openedCtrl.close());
  }

  @override
  Future<bool> ensureInitialized() async => initialized;

  @override
  Future<PushPermissionOutcome> requestNotificationPermission() async =>
      permission;

  @override
  Future<String?> getToken() async => initialToken;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshCtrl.stream;

  @override
  Stream<PushNotificationPayload> get onForegroundMessage =>
      _foregroundCtrl.stream;

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp => _openedCtrl.stream;

  @override
  Future<PushNotificationPayload?> getInitialMessage() async {
    final msg = initialMessage;
    initialMessage = null;
    return msg;
  }
}

class _FakeNotificationsRepo implements NotificationsRepository {
  _FakeNotificationsRepo({required this.role});

  final String role;
  final List<({String accountId, String deviceId, String fcmToken})>
  registrations = [];
  final List<String> revokedDeviceIds = [];

  @override
  Future<RealtimeChannelGrant> fetchChannelGrant(AuthSession session) async {
    return RealtimeChannelGrant(
      role: role,
      customerTopic: 'private:customer:${session.account.id}:v1:tok',
      customerEpoch: 1,
      lastSeq: 0,
    );
  }

  @override
  Future<RealtimeSignalsPage> pollSignals(
    AuthSession session, {
    required int afterSeq,
    int limit = 50,
  }) async {
    return RealtimeSignalsPage(
      items: const [],
      lastSeq: afterSeq,
      customerEpoch: 1,
    );
  }

  @override
  Future<RealtimeStreamHandle> openRealtimeStream(
    AuthSession session, {
    required int afterSeq,
  }) async {
    final ctrl = StreamController<RealtimeStreamFrame>();
    ctrl.add(RealtimeConnectedFrame(lastSeq: afterSeq, customerEpoch: 1));
    return RealtimeStreamHandle(
      frames: ctrl.stream,
      close: () async {
        if (!ctrl.isClosed) await ctrl.close();
      },
    );
  }

  @override
  Future<void> registerPushDevice(
    AuthSession session, {
    required String deviceId,
    required String fcmToken,
  }) async {
    registrations.add((
      accountId: session.account.id,
      deviceId: deviceId,
      fcmToken: fcmToken,
    ));
  }

  @override
  Future<void> revokePushDevice(
    AuthSession session, {
    required String deviceId,
    bool rotateTopics = true,
  }) async {
    revokedDeviceIds.add(deviceId);
  }
}

class _FakeCatalogRepo implements CatalogRepository {
  @override
  Future<CatalogPage> list(
    AuthSession session,
    CatalogKind kind, {
    String query = '',
    String? cursor,
    String? stallId,
  }) async => (items: const <CatalogItem>[], nextCursor: null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomerRepo implements CustomerRepository {
  var detailFetchCount = 0;

  @override
  Future<CustomerCart> fetchCart(AuthSession session) async {
    return const CustomerCart(
      stall: null,
      items: [],
      generalNote: '',
      draftVersion: 0,
      subtotal: 0,
      seenSubtotal: 0,
      itemCount: 0,
      canCheckout: false,
      blockers: [],
    );
  }

  @override
  Future<CustomerOrderDetail> fetchOrderDetail(
    AuthSession session, {
    required String orderId,
  }) async {
    detailFetchCount++;
    return CustomerOrderDetail(
      summary: CustomerOrderSummary(
        id: orderId,
        orderNumber: '00042',
        stallId: _stallAId,
        stallName: 'Kantin Push',
        stallBlock: 'Blok A',
        stallCampus: 'USU',
        status: CustomerOrderStatus.siapDiambil,
        paymentStatus: CustomerOrderPaymentStatus.belumLunas,
        totalAmount: 18000,
        itemSummary: '1x Ayam Penyet',
        itemCount: 1,
        prepEstimateMinutes: 10,
        generalNote: '',
        statusReason: null,
        createdAt: DateTime.utc(2026, 11, 22, 10, 0),
        updatedAt: DateTime.utc(2026, 11, 22, 10, 1),
        terminalAt: null,
      ),
      items: const [
        CustomerOrderItem(
          id: 'item-1',
          menuItemId: 'menu-1',
          menuName: 'Ayam Penyet',
          unitPrice: 18000,
          quantity: 1,
          lineTotal: 18000,
          itemNote: '',
        ),
      ],
      events: [
        CustomerOrderEvent(
          id: 'ev-1',
          fromStatus: CustomerOrderStatus.diproses,
          toStatus: CustomerOrderStatus.siapDiambil,
          actorRole: 'owner',
          reason: null,
          createdAt: DateTime.utc(2026, 11, 22, 10, 1),
        ),
      ],
    );
  }

  @override
  Future<({List<CustomerOrderSummary> items, bool hasMore})> listOrders(
    AuthSession session, {
    required bool activeOnly,
    int limit = 30,
    int offset = 0,
  }) async => (items: const <CustomerOrderSummary>[], hasMore: false);

  @override
  Future<Uint8List?> fetchStallPhoto(
    AuthSession session, {
    required String stallId,
  }) async => null;

  @override
  Future<Uint8List?> fetchMenuPhoto(
    AuthSession session, {
    required String menuId,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOwnerRepo implements OwnerRepository {
  var detailFetchCount = 0;

  @override
  Future<OwnerDashboard> fetchDashboard(AuthSession session) async {
    return const OwnerDashboard(
      stallBundle: OwnerStallBundle(
        stall: OwnerStall(
          id: _stallAId,
          ownerId: _ownerAId,
          name: 'Kantin Owner Push',
          campus: 'USU',
          block: 'Blok A',
          description: '',
          waitMinutes: 10,
          isListed: true,
          isOpen: true,
          hasPhoto: false,
        ),
        schedules: [],
        publishEligibility: OwnerPublishEligibility(
          canPublish: true,
          missingProfileFields: [],
          availableMenuCount: 1,
        ),
      ),
      activeCounts: OwnerActiveCounts(
        menungguKonfirmasi: 1,
        diproses: 0,
        siapDiambil: 0,
      ),
      attentionOrders: [],
    );
  }

  @override
  Future<OwnerOrderDetail> fetchOrderDetail(
    AuthSession session, {
    required String orderId,
  }) async {
    detailFetchCount++;
    return OwnerOrderDetail(
      summary: OwnerOrderSummary(
        id: orderId,
        orderNumber: '00042',
        stallId: _stallAId,
        customerName: 'Pelanggan Uji',
        status: OwnerOrderStatus.menungguKonfirmasi,
        paymentStatus: OwnerPaymentStatus.belumLunas,
        generalNote: '',
        totalAmount: 18000,
        prepEstimateMinutes: 10,
        statusReason: null,
        itemSummary: '1x Ayam Penyet',
        itemCount: 1,
        createdAt: DateTime.utc(2026, 11, 22, 10, 0),
        acceptedAt: null,
        readyAt: null,
        terminalAt: null,
        updatedAt: DateTime.utc(2026, 11, 22, 10, 0),
      ),
      items: const [
        OwnerOrderItemSnapshot(
          id: 'item-1',
          menuItemId: 'menu-1',
          menuName: 'Ayam Penyet',
          unitPrice: 18000,
          quantity: 1,
          lineTotal: 18000,
          itemNote: '',
        ),
      ],
      events: [
        OwnerOrderEvent(
          id: 'ev-1',
          fromStatus: null,
          toStatus: OwnerOrderStatus.menungguKonfirmasi,
          actorRole: 'customer',
          reason: null,
          createdAt: DateTime.utc(2026, 11, 22, 10, 0),
        ),
      ],
    );
  }

  @override
  Future<List<OwnerOrderSummary>> listOrders(
    AuthSession session, {
    bool? activeOnly,
    OwnerOrderStatus? status,
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async => const [];

  @override
  Future<Uint8List?> fetchStallPhoto(AuthSession session) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdminRepo implements AdminRepository {
  @override
  Future<AdminDashboardSummary> fetchDashboard(AuthSession session) async {
    return const AdminDashboardSummary(
      pendingApplications: 0,
      totalUsers: 3,
      activeUsers: 3,
      inactiveUsers: 0,
      totalStalls: 1,
      publishedStalls: 1,
      openStalls: 1,
      recentPendingApplications: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
