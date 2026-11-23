import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_repository.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_detail_page.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/notifications/data/push_device_bridge.dart';
import 'package:kantin_cerdas/features/notifications/data/sse_frame_parser.dart';
import 'package:kantin_cerdas/features/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas/features/notifications/domain/notifications_repository.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_repository.dart';
import 'package:kantin_cerdas/features/owner/presentation/owner_shell_page.dart';
import 'package:kantin_cerdas/theme/kc_theme.dart';

const _custAId = '10000000-0000-4000-8000-000000000701';
const _custBId = '10000000-0000-4000-8000-000000000702';
const _ownerAId = '20000000-0000-4000-8000-000000000701';
const _stallAId = '30000000-0000-4000-8000-000000000701';
const _order1Id = '40000000-0000-4000-8000-000000000701';

void main() {
  group('SSE frame parser', () {
    test(
      'parses split UTF-8 chunks, comments, connected, order_signal, topic_rotated, and session_revoked',
      () async {
        final controller = StreamController<List<int>>();
        final framesFuture = parseRealtimeSseStream(controller.stream).toList();

        controller.add(
          utf8.encode(': ping\n\nevent: connected\ndata: {"last_seq":4,"cus'),
        );
        controller.add(utf8.encode('tomer_epoch":1}\n\n'));
        controller.add(
          utf8.encode(
            'id: 5\nevent: order_signal\ndata: {"seq":5,"event_id":"e5","order_id":"$_order1Id","stall_id":"$_stallAId","to_status":"siap_diambil","audience_scope":"customer","created_at":"2026-11-22T10:00:00Z"}\n\n',
          ),
        );
        controller.add(
          utf8.encode(
            'event: topic_rotated\ndata: {"customer_epoch":2,"stall_epoch":3}\n\n',
          ),
        );
        controller.add(
          utf8.encode(
            'event: session_revoked\ndata: {"reason":"SESSION_REVOKED"}\n\n',
          ),
        );
        await controller.close();

        final frames = await framesFuture;
        expect(frames.length, 4);
        expect(frames[0], isA<RealtimeConnectedFrame>());
        expect((frames[0] as RealtimeConnectedFrame).lastSeq, 4);
        expect(frames[1], isA<RealtimeOrderSignalFrame>());
        expect(
          (frames[1] as RealtimeOrderSignalFrame).signal.toStatus,
          'siap_diambil',
        );
        expect(frames[2], isA<RealtimeTopicRotatedFrame>());
        expect((frames[2] as RealtimeTopicRotatedFrame).customerEpoch, 2);
        expect(frames[3], isA<RealtimeSessionRevokedFrame>());
      },
    );
  });

  group('Customer & Owner live UI updates without manual refresh (ORDER-017)', () {
    testWidgets(
      'CustomerOrderDetailPage updates live from Menunggu Konfirmasi -> Diproses -> Siap Diambil -> Selesai & deduplicates replays',
      (tester) async {
        final session = _makeSession(
          id: _custAId,
          email: 'cust-a@example.test',
          role: AuthRole.customer,
        );
        final fakeCustomerRepo = _FakeCustomerRepo(
          status: CustomerOrderStatus.menungguKonfirmasi,
        );
        final fakeNotifRepo = _FakeNotificationsRepo(role: 'customer');
        final fakeTokenSource = _FakePushTokenSource(
          deviceId: 'android-cust-a',
          fcmToken: 'fcm_token_cust_a_device_00000001',
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_makeAuthRepo(session)),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
            notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
            pushTokenSourceProvider.overrideWithValue(fakeTokenSource),
            realtimeReconnectBackoffProvider.overrideWithValue(const [
              Duration(milliseconds: 20),
            ]),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: KcTheme.light,
              home: const CustomerOrderDetailPage(
                accountId: _custAId,
                orderId: _order1Id,
                syncInterval: null,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Menunggu Konfirmasi'), findsWidgets);
        expect(fakeCustomerRepo.detailFetchCount, 1);
        // Push token registered cleanly for Customer
        expect(fakeNotifRepo.registeredDevices, {'android-cust-a'});

        // Owner accepts order on backend -> emit realtime signal -> UI refreshes without pull-to-refresh!
        fakeCustomerRepo.status = CustomerOrderStatus.diproses;
        fakeNotifRepo.emitOrderSignal(
          seq: 1,
          eventId: 'evt-accept',
          orderId: _order1Id,
          toStatus: 'diproses',
          audienceScope: 'customer',
        );
        await tester.pumpAndSettle();
        expect(find.text('Diproses'), findsWidgets);
        expect(fakeCustomerRepo.detailFetchCount, 2);

        // Duplicate / replayed signal with same eventId triggers ZERO redundant fetches!
        fakeNotifRepo.emitOrderSignal(
          seq: 1,
          eventId: 'evt-accept',
          orderId: _order1Id,
          toStatus: 'diproses',
          audienceScope: 'customer',
        );
        await tester.pumpAndSettle();
        expect(fakeCustomerRepo.detailFetchCount, 2);

        // Owner marks ready -> barcode section appears live!
        fakeCustomerRepo.status = CustomerOrderStatus.siapDiambil;
        fakeNotifRepo.emitOrderSignal(
          seq: 2,
          eventId: 'evt-ready',
          orderId: _order1Id,
          toStatus: 'siap_diambil',
          audienceScope: 'customer',
        );
        await tester.pumpAndSettle();
        expect(find.text('Siap Diambil'), findsWidgets);
        expect(fakeCustomerRepo.detailFetchCount, 3);

        // Owner completes order (selesai has NO push, YES realtime!) -> updates live!
        fakeCustomerRepo.status = CustomerOrderStatus.selesai;
        fakeNotifRepo.emitOrderSignal(
          seq: 3,
          eventId: 'evt-complete',
          orderId: _order1Id,
          toStatus: 'selesai',
          audienceScope: 'customer',
        );
        await tester.pumpAndSettle();
        expect(find.text('Selesai'), findsWidgets);
        expect(fakeCustomerRepo.detailFetchCount, 4);
      },
    );

    testWidgets(
      'OwnerShellPage updates live dashboard counts on new order & recovers after disconnect',
      (tester) async {
        final session = _makeSession(
          id: _ownerAId,
          email: 'owner-a@example.test',
          role: AuthRole.owner,
        );
        final fakeOwnerRepo = _FakeOwnerRepo(waitingCount: 0);
        final fakeNotifRepo = _FakeNotificationsRepo(
          role: 'owner',
          stallId: _stallAId,
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_makeAuthRepo(session)),
            ownerRepositoryProvider.overrideWithValue(fakeOwnerRepo),
            notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
            pushTokenSourceProvider.overrideWithValue(
              _FakePushTokenSource(deviceId: 'android-owner-a', fcmToken: null),
            ),
            realtimeReconnectBackoffProvider.overrideWithValue(const [
              Duration(milliseconds: 20),
            ]),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: KcTheme.light,
              home: OwnerShellPage(session: session, syncInterval: null),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(fakeOwnerRepo.dashboardFetchCount, 1);
        // Notification permission denied / null FCM token -> no push register call, realtime still live
        expect(fakeNotifRepo.registeredDevices, isEmpty);

        // Customer checks out -> Owner receives live signal without manual refresh!
        fakeOwnerRepo.waitingCount = 2;
        fakeNotifRepo.emitOrderSignal(
          seq: 10,
          eventId: 'evt-new-order',
          orderId: _order1Id,
          toStatus: 'menunggu_konfirmasi',
          audienceScope: 'owner',
        );
        await tester.pumpAndSettle();
        expect(fakeOwnerRepo.dashboardFetchCount, 2);

        // Simulate network drop -> reconnect catches up missed signals & reloads backend REST truth!
        fakeOwnerRepo.waitingCount = 3;
        fakeNotifRepo.queuedCatchUpSignals.add(
          RealtimeOrderSignal(
            seq: 11,
            eventId: 'evt-missed-while-offline',
            orderId: _order1Id,
            stallId: _stallAId,
            toStatus: 'dibatalkan',
            audienceScope: 'owner',
            createdAt: DateTime.utc(2026, 11, 22, 10, 5),
          ),
        );
        await fakeNotifRepo.dropCurrentStream();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(fakeNotifRepo.streamOpenCount, greaterThanOrEqualTo(2));
        expect(fakeNotifRepo.lastPollAfterSeq, 10);
        expect(fakeOwnerRepo.dashboardFetchCount, greaterThanOrEqualTo(3));
      },
    );
  });

  group('Logout, account switch (R2) & REST fallback', () {
    test(
      'logout immediately closes stream, revokes device binding, and prevents cross-account leakage',
      () async {
        final sessionA = _makeSession(
          id: _custAId,
          email: 'cust-a@example.test',
          role: AuthRole.customer,
        );
        final fakeNotifRepo = _FakeNotificationsRepo(role: 'customer');
        final fakeTokenSource = _FakePushTokenSource(
          deviceId: 'shared-android-phone',
          fcmToken: 'fcm_token_shared_phone_000000001',
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_makeAuthRepo(sessionA)),
            notificationsRepositoryProvider.overrideWithValue(fakeNotifRepo),
            pushTokenSourceProvider.overrideWithValue(fakeTokenSource),
            realtimeReconnectBackoffProvider.overrideWithValue(const [
              Duration(milliseconds: 20),
            ]),
          ],
        );
        addTearDown(container.dispose);

        // Wait for auth session to restore
        await container.read(authControllerProvider.future);
        final subA = container.listen(
          realtimeOrderSyncProvider(_custAId),
          (_, _) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(
          container.read(realtimeOrderSyncProvider(_custAId)).mode,
          RealtimeConnectionMode.live,
        );
        expect(fakeNotifRepo.registeredDevices, {'shared-android-phone'});

        // Trigger logout -> pre-logout hook revokes device & closes stream BEFORE JWT invalidation
        await container.read(authControllerProvider.notifier).logout();
        expect(fakeNotifRepo.revokedDevices, {'shared-android-phone'});
        expect(fakeNotifRepo.streamClosedCount, greaterThanOrEqualTo(1));
        expect(
          container.read(realtimeOrderSyncProvider(_custAId)).mode,
          RealtimeConnectionMode.revoked,
        );
        subA.close();

        // Another account (Customer B) starts fresh with zero state leaked from Customer A
        expect(
          container.read(realtimeOrderSyncProvider(_custBId)).receivedSignals,
          0,
        );
      },
    );

    test(
      'gracefully falls back to REST mode without tight retry loops on 404 ROUTE_NOT_FOUND',
      () async {
        final sessionA = _makeSession(
          id: _custAId,
          email: 'cust-a@example.test',
          role: AuthRole.customer,
        );
        final unsupportedRepo = _UnsupportedNotificationsRepo();

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_makeAuthRepo(sessionA)),
            notificationsRepositoryProvider.overrideWithValue(unsupportedRepo),
            pushTokenSourceProvider.overrideWithValue(
              _FakePushTokenSource(deviceId: 'dev-1', fcmToken: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authControllerProvider.future);
        final sub = container.listen(
          realtimeOrderSyncProvider(_custAId),
          (_, _) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(
          container.read(realtimeOrderSyncProvider(_custAId)).mode,
          RealtimeConnectionMode.restFallback,
        );
        expect(unsupportedRepo.grantAttempts, 1);
        sub.close();
      },
    );
  });
}

// =============================================================================
// Test helpers & fakes
// =============================================================================
AuthSession _makeSession({
  required String id,
  required String email,
  required AuthRole role,
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
      'display_name': 'Test User',
      'role': role.name,
      'has_photo': true,
      'profile_complete': true,
      'can_manage_credentials': true,
    }),
  );
}

AuthRepository _makeAuthRepo(AuthSession session) {
  final store = MemorySessionStore()..write(session.tokens);
  final client = MockClient((request) async {
    if (request.url.path.endsWith('/v1/auth/me')) {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'id': session.account.id,
            'email': session.account.email,
            'display_name': session.account.displayName,
            'role': session.account.role.name,
            'has_photo': true,
            'has_password': true,
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

class _FakePushTokenSource implements PushTokenSource {
  _FakePushTokenSource({required this.deviceId, required this.fcmToken});

  final String deviceId;
  final String? fcmToken;

  @override
  Future<String?> getAndroidFcmToken() async => fcmToken;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<String> getOrCreateDeviceId() async => deviceId;
}

class _FakeNotificationsRepo implements NotificationsRepository {
  _FakeNotificationsRepo({required this.role, this.stallId});

  final String role;
  final String? stallId;
  final Set<String> registeredDevices = {};
  final Set<String> revokedDevices = {};
  final List<RealtimeOrderSignal> queuedCatchUpSignals = [];

  StreamController<RealtimeStreamFrame>? _currentController;
  var streamOpenCount = 0;
  var streamClosedCount = 0;
  int? lastPollAfterSeq;

  void emitOrderSignal({
    required int seq,
    required String eventId,
    required String orderId,
    required String toStatus,
    required String audienceScope,
  }) {
    _currentController?.add(
      RealtimeOrderSignalFrame(
        RealtimeOrderSignal(
          seq: seq,
          eventId: eventId,
          orderId: orderId,
          stallId: stallId ?? _stallAId,
          toStatus: toStatus,
          audienceScope: audienceScope,
          createdAt: DateTime.utc(2026, 11, 22, 10, 0),
        ),
      ),
    );
  }

  Future<void> dropCurrentStream() async {
    final ctrl = _currentController;
    _currentController = null;
    if (ctrl != null && !ctrl.isClosed) {
      await ctrl.close();
    }
  }

  @override
  Future<RealtimeChannelGrant> fetchChannelGrant(AuthSession session) async {
    return RealtimeChannelGrant(
      role: role,
      customerTopic: 'private:customer:${session.account.id}:v1:tok',
      customerEpoch: 1,
      stallId: stallId,
      stallTopic: stallId == null ? null : 'private:stall:$stallId:v1:tok',
      stallEpoch: stallId == null ? null : 1,
      lastSeq: 0,
    );
  }

  @override
  Future<RealtimeSignalsPage> pollSignals(
    AuthSession session, {
    required int afterSeq,
    int limit = 50,
  }) async {
    lastPollAfterSeq = afterSeq;
    final items = queuedCatchUpSignals.where((s) => s.seq > afterSeq).toList();
    queuedCatchUpSignals.clear();
    final lastSeq = items.isEmpty ? afterSeq : items.last.seq;
    return RealtimeSignalsPage(
      items: items,
      lastSeq: lastSeq,
      customerEpoch: 1,
      stallEpoch: stallId == null ? null : 1,
    );
  }

  @override
  Future<RealtimeStreamHandle> openRealtimeStream(
    AuthSession session, {
    required int afterSeq,
  }) async {
    streamOpenCount++;
    final ctrl = StreamController<RealtimeStreamFrame>();
    _currentController = ctrl;
    ctrl.add(
      RealtimeConnectedFrame(
        lastSeq: afterSeq,
        customerEpoch: 1,
        stallEpoch: stallId == null ? null : 1,
      ),
    );
    return RealtimeStreamHandle(
      frames: ctrl.stream,
      close: () async {
        streamClosedCount++;
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
    registeredDevices.add(deviceId);
  }

  @override
  Future<void> revokePushDevice(
    AuthSession session, {
    required String deviceId,
    bool rotateTopics = true,
  }) async {
    revokedDevices.add(deviceId);
  }
}

class _UnsupportedNotificationsRepo implements NotificationsRepository {
  var grantAttempts = 0;

  @override
  Future<RealtimeChannelGrant> fetchChannelGrant(AuthSession session) async {
    grantAttempts++;
    throw const AuthException('ROUTE_NOT_FOUND', 'Route tidak tersedia.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomerRepo implements CustomerRepository {
  _FakeCustomerRepo({required this.status});

  CustomerOrderStatus status;
  var detailFetchCount = 0;

  @override
  Future<CustomerOrderDetail> fetchOrderDetail(
    AuthSession session, {
    required String orderId,
  }) async {
    detailFetchCount++;
    final summary = CustomerOrderSummary(
      id: orderId,
      orderNumber: '00042',
      stallId: _stallAId,
      stallName: 'Kantin Realtime',
      stallBlock: 'Blok A',
      stallCampus: 'USU',
      status: status,
      paymentStatus: status == CustomerOrderStatus.selesai
          ? CustomerOrderPaymentStatus.lunas
          : CustomerOrderPaymentStatus.belumLunas,
      totalAmount: 18000,
      itemSummary: '1x Ayam Penyet',
      itemCount: 1,
      prepEstimateMinutes: 10,
      generalNote: '',
      statusReason: null,
      createdAt: DateTime.utc(2026, 11, 22, 10, 0),
      updatedAt: DateTime.utc(2026, 11, 22, 10, 1),
      terminalAt: null,
    );
    return CustomerOrderDetail(
      summary: summary,
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
          fromStatus: null,
          toStatus: status,
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
  }) async {
    return (items: const <CustomerOrderSummary>[], hasMore: false);
  }

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
  _FakeOwnerRepo({required this.waitingCount});

  int waitingCount;
  var dashboardFetchCount = 0;

  @override
  Future<OwnerDashboard> fetchDashboard(AuthSession session) async {
    dashboardFetchCount++;
    return OwnerDashboard(
      stallBundle: const OwnerStallBundle(
        stall: OwnerStall(
          id: _stallAId,
          ownerId: _ownerAId,
          name: 'Kantin Owner RT',
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
        menungguKonfirmasi: waitingCount,
        diproses: 0,
        siapDiambil: 0,
      ),
      attentionOrders: const [],
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
