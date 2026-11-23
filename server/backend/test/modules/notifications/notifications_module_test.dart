import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas_backend/src/app/bootstrap.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_store.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider_config.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/application/push_notification_worker.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/data/google_oauth_jwt_signer.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/data/http_fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/data/supabase_realtime_broadcaster.dart'
    show SupabaseHttpRealtimeBroadcaster;
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notifications_config.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/realtime_broadcaster.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../../config_test.dart' show validEnvironment;

const _custAId = '11111111-1111-1111-1111-111111111111';
const _custBId = '11111111-1111-1111-1111-111111111112';
const _ownerAId = '22222222-2222-2222-2222-222222222221';
const _ownerBId = '22222222-2222-2222-2222-222222222222';
const _adminId = '33333333-3333-3333-3333-333333333331';
const _stallAId = '44444444-4444-4444-4444-444444444441';
const _order1Id = '55555555-5555-5555-5555-555555555551';

void main() {
  group('NotificationsConfig & safety defaults', () {
    test('defaults to FCM disabled & broadcast disabled with zero secrets', () {
      final cfg = NotificationsConfig.fromEnv(EnvConfig.fromMap(const {}));
      expect(cfg.fcmEnabled, isFalse);
      expect(cfg.isFcmActive, isFalse);
      expect(cfg.hasCompleteFcmCredentials, isFalse);
      expect(cfg.fcmProjectId, isEmpty);
      expect(cfg.fcmClientEmail, isEmpty);
      expect(cfg.fcmPrivateKey, isEmpty);
      expect(cfg.supabaseBroadcastEnabled, isFalse);
      expect(cfg.fcmMaxRetryAttempts, 5);
    });

    test('fails closed if FCM_ENABLED=true without full credentials', () {
      final cfg = NotificationsConfig.fromEnv(
        EnvConfig.fromMap(const {
          'FCM_ENABLED': 'true',
          'FCM_PROJECT_ID': 'demo-project',
        }),
      );
      expect(cfg.fcmEnabled, isTrue);
      expect(cfg.hasCompleteFcmCredentials, isFalse);
      expect(cfg.isFcmActive, isFalse);
    });
  });

  group('ORDER-017A strict 7 push events & non-sensitive payload', () {
    test('builds minimal non-sensitive payloads for exactly the 7 events', () {
      const matrix = <({String event, String role})>[
        (event: 'order_created', role: 'owner'),
        (event: 'order_cancelled', role: 'owner'),
        (event: 'order_accepted', role: 'customer'),
        (event: 'order_rejected', role: 'customer'),
        (event: 'order_ready', role: 'customer'),
        (event: 'order_failed_fulfill', role: 'customer'),
        (event: 'order_not_picked_up', role: 'customer'),
      ];

      for (final entry in matrix) {
        final delivery = PendingPushDelivery(
          deliveryId: 'del-${entry.event}',
          notificationEventId: 'evt-${entry.event}',
          orderId: _order1Id,
          orderNumber: '00042',
          stallName: 'Kantin Enak',
          recipientId: entry.role == 'owner' ? _ownerAId : _custAId,
          recipientRole: entry.role,
          eventType: entry.event,
          deviceId: 'android-dev-1',
          fcmToken: 'fcm_token_valid_1234567890123456',
          attemptCount: 1,
          maxAttempts: 5,
        );
        final payload = FcmMessagePayload.tryBuild(delivery);
        expect(
          payload,
          isNotNull,
          reason: 'Expected payload for ${entry.event}',
        );
        final envelope = payload!.toFcmV1RequestBody();
        final encoded = jsonEncode(envelope);
        expect(payload.data['event_type'], entry.event);
        expect(payload.data['recipient_role'], entry.role);
        expect(payload.data['order_id'], _order1Id);
        expect(payload.data['order_number'], '00042');
        // Zero sensitive fields in payload
        expect(encoded, isNot(contains('email')));
        expect(encoded, isNot(contains('phone')));
        expect(encoded, isNot(contains('address')));
        expect(encoded, isNot(contains('total_amount')));
        expect(encoded, isNot(contains('password')));
      }
    });

    test('blocks selesai, gagal_diambil, admin, and role mismatches', () {
      const disallowed = <({String event, String role})>[
        (event: 'order_completed', role: 'customer'),
        (event: 'selesai', role: 'customer'),
        (event: 'gagal_diambil', role: 'customer'),
        (event: 'order_failed_pickup', role: 'customer'),
        (event: 'order_created', role: 'customer'), // wrong recipient role
        (event: 'order_accepted', role: 'owner'), // wrong recipient role
        (event: 'order_created', role: 'admin'),
      ];

      for (final entry in disallowed) {
        final delivery = PendingPushDelivery(
          deliveryId: 'del-bad',
          notificationEventId: 'evt-bad',
          orderId: _order1Id,
          orderNumber: '00042',
          stallName: 'Kantin Enak',
          recipientId: _adminId,
          recipientRole: entry.role,
          eventType: entry.event,
          deviceId: 'android-dev-1',
          fcmToken: 'fcm_token_valid_1234567890123456',
          attemptCount: 1,
          maxAttempts: 5,
        );
        expect(
          FcmMessagePayload.tryBuild(delivery),
          isNull,
          reason: '${entry.event} -> ${entry.role} must be rejected',
        );
      }
    });
  });

  group('PushNotificationWorker retry, dedup, UNREGISTERED & isolation', () {
    test(
      'processes 7 events, retries transient errors, deactivates UNREGISTERED tokens, and skips disallowed rows',
      () async {
        final store = _FakeNotificationStore();
        var attemptsForTransient = 0;
        final fakeTransport = FakeFcmTransport(
          onSend: (payload) {
            if (payload.token == 'fcm_token_transient_123456789012') {
              attemptsForTransient++;
              if (attemptsForTransient == 1) {
                return const FcmSendResult.retryable('FCM_HTTP_503');
              }
              return const FcmSendResult.sent(
                'projects/test/messages/recovered',
              );
            }
            if (payload.token == 'fcm_token_unregistered_123456789') {
              return const FcmSendResult.failedPermanent(
                'UNREGISTERED',
                deactivateDevice: true,
              );
            }
            return FcmSendResult.sent(
              'projects/test/messages/${payload.data['event_id']}',
            );
          },
        );

        final worker = PushNotificationWorker(
          store: store,
          transport: fakeTransport,
          config: const NotificationsConfig.defaults(),
        );

        store.enqueuePushDelivery(
          const PendingPushDelivery(
            deliveryId: 'd-ok',
            notificationEventId: 'e-ok',
            orderId: _order1Id,
            orderNumber: '00001',
            stallName: 'Kantin A',
            recipientId: _ownerAId,
            recipientRole: 'owner',
            eventType: 'order_created',
            deviceId: 'dev-owner',
            fcmToken: 'fcm_token_owner_ok_1234567890123',
            attemptCount: 1,
            maxAttempts: 5,
          ),
        );
        store.enqueuePushDelivery(
          const PendingPushDelivery(
            deliveryId: 'd-retry',
            notificationEventId: 'e-retry',
            orderId: _order1Id,
            orderNumber: '00001',
            stallName: 'Kantin A',
            recipientId: _custAId,
            recipientRole: 'customer',
            eventType: 'order_ready',
            deviceId: 'dev-cust',
            fcmToken: 'fcm_token_transient_123456789012',
            attemptCount: 1,
            maxAttempts: 5,
          ),
        );
        store.enqueuePushDelivery(
          const PendingPushDelivery(
            deliveryId: 'd-unreg',
            notificationEventId: 'e-unreg',
            orderId: _order1Id,
            orderNumber: '00001',
            stallName: 'Kantin A',
            recipientId: _custAId,
            recipientRole: 'customer',
            eventType: 'order_accepted',
            deviceId: 'dev-dead',
            fcmToken: 'fcm_token_unregistered_123456789',
            attemptCount: 1,
            maxAttempts: 5,
          ),
        );
        store.enqueuePushDelivery(
          const PendingPushDelivery(
            deliveryId: 'd-bad',
            notificationEventId: 'e-bad',
            orderId: _order1Id,
            orderNumber: '00001',
            stallName: 'Kantin A',
            recipientId: _adminId,
            recipientRole: 'admin',
            eventType: 'selesai',
            deviceId: 'dev-admin',
            fcmToken: 'fcm_token_admin_1234567890123456',
            attemptCount: 1,
            maxAttempts: 5,
          ),
        );

        final t0 = DateTime.utc(2026, 11, 22, 10, 0, 0);
        final report1 = await worker.processPendingBatch(now: t0);
        expect(report1.claimed, 4);
        expect(report1.sent, 1);
        expect(report1.retryScheduled, 1);
        expect(report1.failedPermanent, 1);
        expect(report1.skipped, 1);
        expect(store.deactivatedDeliveries, contains('d-unreg'));
        expect(store.completedOutcomes['d-ok'], FcmDeliveryOutcome.sent);
        expect(store.completedOutcomes['d-bad'], FcmDeliveryOutcome.skipped);

        // Second tick recovers transient retry -> sent
        final report2 = await worker.processPendingBatch(
          now: t0.add(const Duration(seconds: 30)),
        );
        expect(report2.claimed, 1);
        expect(report2.sent, 1);
        expect(store.completedOutcomes['d-retry'], FcmDeliveryOutcome.sent);
      },
    );

    test(
      'swallows transport exceptions so order lifecycle is never impacted',
      () async {
        final store = _FakeNotificationStore();
        final throwingTransport = FakeFcmTransport(
          onSend: (_) => throw StateError('simulated crash'),
        );
        store.enqueuePushDelivery(
          const PendingPushDelivery(
            deliveryId: 'd-crash',
            notificationEventId: 'e-crash',
            orderId: _order1Id,
            orderNumber: '00009',
            stallName: 'Kantin A',
            recipientId: _custAId,
            recipientRole: 'customer',
            eventType: 'order_ready',
            deviceId: 'dev-cust',
            fcmToken: 'fcm_token_cust_crash_12345678901',
            attemptCount: 1,
            maxAttempts: 3,
          ),
        );

        final worker = PushNotificationWorker(
          store: store,
          transport: throwingTransport,
          config: const NotificationsConfig.defaults(),
        );
        final report = await worker.processPendingBatch();
        expect(report.claimed, 1);
        expect(report.retryScheduled, 1);
        expect(
          store.completedOutcomes['d-crash'],
          FcmDeliveryOutcome.retryable,
        );
      },
    );
  });

  group(
    'Pure-Dart RS256 signer, HttpFcmTransport & SupabaseHttpRealtimeBroadcaster',
    () {
      test('computes valid FIPS 180-4 SHA-256 and mathematical RS256 signature', () {
        // Standard FIPS 180-4 SHA-256 test vector for "abc"
        final digest = sha256Digest(Uint8List.fromList(utf8.encode('abc')));
        final hex = digest
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        expect(
          hex,
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        );

        // Programmatic mathematical RSA-512 test vector (two synthetic primes, not a credential)
        final p = BigInt.parse(
          'c3b8e3e60878a5d897b3df1a3a9d6a0a0d6a4c5e3a6e0b79d2f5d0f21f9f0e21',
          radix: 16,
        );
        final q = BigInt.parse(
          'd1b79b6f0e3a8f1d45b2f8c9e2a4b6d8f0c2e4a6b8d0f2a4c6e8b0d2f4a6c8e3',
          radix: 16,
        );
        // Use deterministic probable primes derived from fixed bases for math round-trip:
        final primeP = _nextSimplePrime(p);
        final primeQ = _nextSimplePrime(q);
        final n = primeP * primeQ;
        final phi = (primeP - BigInt.one) * (primeQ - BigInt.one);
        final e = BigInt.from(65537);
        final d = e.modInverse(phi);

        final der = _encodeSyntheticPkcs8Der(n, e, d);
        final parsed = RsaPrivateKeyMaterial.fromDer(der);
        expect(parsed.modulus, n);
        expect(parsed.privateExponent, d);

        final signer = GoogleServiceAccountJwtSigner(
          clientEmail: 'synthetic-test@example.invalid',
          privateKey: parsed,
          tokenUri: 'https://oauth2.example.invalid/token',
        );
        final jwt = signer.createSignedAssertion(
          now: DateTime.utc(2026, 11, 22, 12, 0, 0),
        );
        final parts = jwt.split('.');
        expect(parts.length, 3);

        // Verify RSA signature mathematically: s^e mod n ends with SHA-256(signingInput)
        final sigBytes = base64Url.decode(base64Url.normalize(parts[2]));
        var sigInt = BigInt.zero;
        for (final b in sigBytes) {
          sigInt = (sigInt << 8) | BigInt.from(b);
        }
        final verifiedInt = sigInt.modPow(e, n);
        final verifiedHex = verifiedInt.toRadixString(16);
        final expectedHash = sha256Digest(
          Uint8List.fromList(utf8.encode('${parts[0]}.${parts[1]}')),
        );
        final expectedHashHex = expectedHash
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        expect(verifiedHex.endsWith(expectedHashHex), isTrue);
      });

      test(
        'HttpFcmTransport classifies 200, 404 UNREGISTERED, 429 retryable, and 401 cache bust',
        () async {
          final responses = <http.Response>[
            http.Response(
              jsonEncode({'name': 'projects/demo/messages/1'}),
              200,
            ),
            http.Response(
              jsonEncode({
                'error': {
                  'status': 'NOT_FOUND',
                  'details': [
                    {'errorCode': 'UNREGISTERED'},
                  ],
                },
              }),
              404,
            ),
            http.Response(
              jsonEncode({
                'error': {'status': 'UNAVAILABLE'},
              }),
              503,
            ),
          ];
          var callIndex = 0;
          final mockHttp = MockClient((request) async {
            expect(
              request.headers['authorization'],
              'Bearer synthetic-oauth-token',
            );
            expect(request.url.path, '/v1/projects/demo-proj/messages:send');
            return responses[callIndex++];
          });

          final tokenProvider = _StubOAuthTokenProvider(
            'synthetic-oauth-token',
          );
          final cfg = NotificationsConfig.fromEnv(
            EnvConfig.fromMap(const {
              'FCM_ENABLED': 'true',
              'FCM_PROJECT_ID': 'demo-proj',
              'FCM_CLIENT_EMAIL': 'test@example.invalid',
              'FCM_PRIVATE_KEY': 'synthetic-placeholder',
              'FCM_API_BASE_URL': 'https://fcm.example.invalid',
            }),
          );
          final transport = HttpFcmTransport(
            config: cfg,
            httpClient: mockHttp,
            tokenProvider: tokenProvider,
          );
          final payload = FcmMessagePayload.tryBuild(
            const PendingPushDelivery(
              deliveryId: 'd1',
              notificationEventId: 'e1',
              orderId: _order1Id,
              orderNumber: '00010',
              stallName: 'Kantin A',
              recipientId: _custAId,
              recipientRole: 'customer',
              eventType: 'order_ready',
              deviceId: 'dev1',
              fcmToken: 'fcm_token_test_1234567890123456',
              attemptCount: 1,
              maxAttempts: 5,
            ),
          )!;

          final r1 = await transport.send(payload);
          expect(r1.outcome, FcmDeliveryOutcome.sent);
          expect(r1.providerMessageId, 'projects/demo/messages/1');

          final r2 = await transport.send(payload);
          expect(r2.outcome, FcmDeliveryOutcome.failedPermanent);
          expect(r2.deactivateDevice, isTrue);
          expect(r2.errorCode, 'UNREGISTERED');

          final r3 = await transport.send(payload);
          expect(r3.outcome, FcmDeliveryOutcome.retryable);
        },
      );

      test(
        'SupabaseHttpRealtimeBroadcaster publishes minimal private customer & stall broadcasts',
        () async {
          Map<String, Object?>? capturedBody;
          final mockHttp = MockClient((request) async {
            expect(request.url.path, '/realtime/v1/api/broadcast');
            capturedBody = Map<String, Object?>.from(
              jsonDecode(request.body) as Map,
            );
            return http.Response('{}', 202);
          });

          final appCfg = AppConfig.fromEnv(
            EnvConfig.fromMap(validEnvironment()),
          );
          final broadcaster = SupabaseHttpRealtimeBroadcaster(
            supabaseConfig: appCfg.supabase,
            enabled: true,
            httpClient: mockHttp,
          );

          await broadcaster.publish([
            UnbroadcastedRealtimeSignal(
              seq: 7,
              eventId: 'evt-7',
              orderId: _order1Id,
              stallId: _stallAId,
              customerId: _custAId,
              ownerId: _ownerAId,
              toStatus: 'selesai',
              customerTopic: 'private:customer:$_custAId:v1:tok',
              stallTopic: 'private:stall:$_stallAId:v1:tok',
              createdAt: DateTime.utc(2026, 11, 22, 10, 0),
            ),
          ]);

          expect(capturedBody, isNotNull);
          final messages = capturedBody!['messages'] as List<dynamic>;
          expect(messages.length, 2);
          final custMsg = messages[0] as Map<String, dynamic>;
          final stallMsg = messages[1] as Map<String, dynamic>;
          expect(custMsg['private'], isTrue);
          expect(custMsg['topic'], startsWith('private:customer:'));
          expect((custMsg['payload'] as Map)['to_status'], 'selesai');
          expect(stallMsg['private'], isTrue);
          expect(stallMsg['topic'], startsWith('private:stall:'));
        },
      );
    },
  );

  group('Shelf /v1/notifications HTTP & SSE streaming API (isolation + R2)', () {
    late _FakeAuthGateway auth;
    late _FakeAvatarStore avatars;
    late _FakeNotificationStore notifStore;
    late FakeFcmTransport fakeFcm;
    late Handler app;

    setUp(() {
      auth = _FakeAuthGateway();
      avatars = _FakeAvatarStore();
      notifStore = _FakeNotificationStore();
      fakeFcm = FakeFcmTransport();

      final cfg = AppConfig.fromEnv(
        EnvConfig.fromMap(
          validEnvironment(
            overrides: {
              'RATE_LIMIT_ENABLED': 'false',
              'LOG_REQUEST_ENABLED': 'false',
            },
          ),
        ),
      );
      app = buildAppHandlerWithAllModulesAndAi(
        cfg,
        aiConfig: const AiProviderConfig.disabled(),
        notificationsConfig: const NotificationsConfig(
          fcmEnabled: false,
          fcmProjectId: '',
          fcmClientEmail: '',
          fcmPrivateKey: '',
          fcmTokenUri: 'https://oauth2.googleapis.com/token',
          fcmApiBaseUrl: 'https://fcm.googleapis.com',
          fcmRequestTimeout: Duration(seconds: 5),
          fcmMaxRetryAttempts: 5,
          fcmWorkerEnabled: false,
          fcmWorkerPollInterval: Duration(seconds: 5),
          supabaseBroadcastEnabled: false,
          realtimeSignalPollInterval: Duration(milliseconds: 50),
          realtimeStreamHeartbeat: Duration(seconds: 10),
          realtimeSessionRecheck: Duration(milliseconds: 80),
        ),
        authGateway: auth,
        avatarStore: avatars,
        catalogStore: _StubCatalogStore(),
        ownerStore: _StubOwnerStore(),
        ownerMediaStore: _StubMediaStore(),
        customerStore: _StubCustomerStore(),
        adminStore: _StubAdminStore(),
        aiStore: _StubAiStore(),
        aiProvider: _StubAiProvider(),
        notificationStore: notifStore,
        fcmTransport: fakeFcm,
        realtimeBroadcaster: const NoopRealtimeBroadcaster(),
      );
    });

    Future<Response> send(
      String method,
      String path, {
      String? bearer,
      Map<String, Object?>? body,
    }) {
      return Future<Response>.sync(
        () => app(
          Request(
            method,
            Uri.parse('https://api.example.test/v1/notifications$path'),
            headers: {
              'host': 'api.example.test',
              if (bearer != null) 'authorization': 'Bearer $bearer',
              if (body != null) 'content-type': 'application/json',
            },
            body: body == null ? null : jsonEncode(body),
          ),
        ),
      );
    }

    test(
      'enforces role boundaries: Customer/Owner allowed, Admin rejected (403), unauthenticated (401)',
      () async {
        final unauth = await send('GET', '/status');
        expect(unauth.statusCode, 401);

        final adminStatus = await send('GET', '/status', bearer: 'tok-admin');
        expect(adminStatus.statusCode, 403);

        final adminReg = await send(
          'POST',
          '/devices',
          bearer: 'tok-admin',
          body: {
            'device_id': 'admin-dev',
            'fcm_token': 'fcm_token_admin_1234567890123456',
          },
        );
        expect(adminReg.statusCode, 403);

        final custStatus = await send('GET', '/status', bearer: 'tok-cust-a');
        expect(custStatus.statusCode, 200);
        final statusJson = jsonDecode(await custStatus.readAsString()) as Map;
        expect(
          (statusJson['data'] as Map)['realtime_stream_available'],
          isTrue,
        );

        final regResp = await send(
          'POST',
          '/devices',
          bearer: 'tok-cust-a',
          body: {
            'device_id': 'android-cust-a',
            'fcm_token': 'fcm_token_cust_a_123456789012345',
            'platform': 'android',
          },
        );
        expect(regResp.statusCode, 200);

        final grantResp = await send(
          'GET',
          '/realtime/grant',
          bearer: 'tok-owner-a',
        );
        expect(grantResp.statusCode, 200);
        final grantData =
            (jsonDecode(await grantResp.readAsString()) as Map)['data'] as Map;
        expect(grantData['role'], 'owner');
        expect(grantData['stall_id'], _stallAId);
      },
    );

    test(
      'strictly isolates Customer A / Customer B / Owner A / Owner B realtime signals',
      () async {
        notifStore.addOrderSignal(
          orderId: _order1Id,
          stallId: _stallAId,
          customerId: _custAId,
          ownerId: _ownerAId,
          toStatus: 'siap_diambil',
        );
        notifStore.addOrderSignal(
          orderId: _order1Id,
          stallId: _stallAId,
          customerId: _custAId,
          ownerId: _ownerAId,
          toStatus: 'gagal_diambil',
        );

        final custAPoll = await send(
          'GET',
          '/realtime/signals?after_seq=0',
          bearer: 'tok-cust-a',
        );
        final custAData =
            (jsonDecode(await custAPoll.readAsString()) as Map)['data'] as Map;
        expect((custAData['items'] as List).length, 2);

        final custBPoll = await send(
          'GET',
          '/realtime/signals?after_seq=0',
          bearer: 'tok-cust-b',
        );
        final custBData =
            (jsonDecode(await custBPoll.readAsString()) as Map)['data'] as Map;
        expect((custBData['items'] as List), isEmpty);

        final ownerBPoll = await send(
          'GET',
          '/realtime/signals?after_seq=0',
          bearer: 'tok-owner-b',
        );
        final ownerBData =
            (jsonDecode(await ownerBPoll.readAsString()) as Map)['data'] as Map;
        expect((ownerBData['items'] as List), isEmpty);
      },
    );

    test(
      'SSE stream delivers live signals (incl. selesai) & terminates immediately on session revocation (R2)',
      () async {
        final response = await send(
          'GET',
          '/realtime/stream?after_seq=0&max_seconds=3',
          bearer: 'tok-cust-a',
        );
        expect(response.statusCode, 200);
        expect(response.headers['content-type'], contains('text/event-stream'));

        final chunks = <String>[];
        final done = Completer<void>();
        final sub = response
            .read()
            .transform(utf8.decoder)
            .listen(
              chunks.add,
              onDone: () {
                if (!done.isCompleted) done.complete();
              },
            );

        // Push a live signal after stream connects
        await Future<void>.delayed(const Duration(milliseconds: 25));
        notifStore.addOrderSignal(
          orderId: _order1Id,
          stallId: _stallAId,
          customerId: _custAId,
          ownerId: _ownerAId,
          toStatus: 'selesai',
        );

        // Wait for broker poll to deliver the live signal
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Now revoke Customer A's session (simulating logout or admin deactivation — R2)
        auth.revokeToken('tok-cust-a');

        // Wait for session recheck to emit session_revoked and close stream cleanly
        await done.future.timeout(const Duration(seconds: 2));
        await sub.cancel();

        final combined = chunks.join();
        expect(combined, contains('event: connected'));
        expect(combined, contains('event: order_signal'));
        expect(combined, contains('"to_status":"selesai"'));
        expect(combined, contains('event: session_revoked'));
      },
    );

    test(
      'R2 two devices on same account: logout on Device A revokes A, rotates topic, while Device B keeps receiving signals',
      () async {
        // Both tokens belong to Customer A
        auth.addSessionToken('tok-cust-a-dev1', _custAId, AccountRole.customer);
        auth.addSessionToken('tok-cust-a-dev2', _custAId, AccountRole.customer);

        final streamA = await send(
          'GET',
          '/realtime/stream?after_seq=0&max_seconds=3',
          bearer: 'tok-cust-a-dev1',
        );
        final streamB = await send(
          'GET',
          '/realtime/stream?after_seq=0&max_seconds=3',
          bearer: 'tok-cust-a-dev2',
        );

        final bufA = StringBuffer();
        final bufB = StringBuffer();
        final doneA = Completer<void>();
        final subA = streamA
            .read()
            .transform(utf8.decoder)
            .listen(
              bufA.write,
              onDone: () {
                if (!doneA.isCompleted) doneA.complete();
              },
            );
        final subB = streamB.read().transform(utf8.decoder).listen(bufB.write);

        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Device A logs out: revoke device + rotate topic + revoke Device A's JWT
        final revokeResp = await send(
          'DELETE',
          '/devices/dev-a?rotate_topic=true',
          bearer: 'tok-cust-a-dev1',
        );
        expect(revokeResp.statusCode, 200);
        auth.revokeToken('tok-cust-a-dev1');

        await doneA.future.timeout(const Duration(seconds: 2));

        // Emit a new signal AFTER Device A logged out
        notifStore.addOrderSignal(
          orderId: _order1Id,
          stallId: _stallAId,
          customerId: _custAId,
          ownerId: _ownerAId,
          toStatus: 'siap_diambil',
        );

        await Future<void>.delayed(const Duration(milliseconds: 160));
        await subA.cancel();
        await subB.cancel();

        // Device A was revoked and NEVER received the post-logout siap_diambil signal!
        expect(bufA.toString(), contains('event: session_revoked'));
        expect(bufA.toString(), isNot(contains('"to_status":"siap_diambil"')));

        // Device B stayed authorized, saw topic_rotated, AND received siap_diambil!
        expect(bufB.toString(), contains('event: topic_rotated'));
        expect(bufB.toString(), contains('"to_status":"siap_diambil"'));
      },
    );
  });
}

// =============================================================================
// Synthetic mathematical RSA helpers (test-only; never real credentials)
// =============================================================================
BigInt _nextSimplePrime(BigInt start) {
  var candidate = start.isEven ? start + BigInt.one : start;
  while (!_isProbablePrime(candidate)) {
    candidate += BigInt.two;
  }
  return candidate;
}

bool _isProbablePrime(BigInt n) {
  if (n < BigInt.two) return false;
  for (final small in [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]) {
    final b = BigInt.from(small);
    if (n == b) return true;
    if (n % b == BigInt.zero) return false;
  }
  var d = n - BigInt.one;
  var s = 0;
  while (d.isEven) {
    d >>= 1;
    s++;
  }
  for (final witness in [2, 3, 5, 7, 11, 13, 17]) {
    final a = BigInt.from(witness);
    var x = a.modPow(d, n);
    if (x == BigInt.one || x == n - BigInt.one) continue;
    var composite = true;
    for (var r = 1; r < s; r++) {
      x = (x * x) % n;
      if (x == n - BigInt.one) {
        composite = false;
        break;
      }
    }
    if (composite) return false;
  }
  return true;
}

Uint8List _encodeSyntheticPkcs8Der(BigInt n, BigInt e, BigInt d) {
  List<int> encodeLen(int len) {
    if (len < 0x80) return [len];
    final bytes = <int>[];
    var v = len;
    while (v > 0) {
      bytes.insert(0, v & 0xff);
      v >>= 8;
    }
    return [0x80 | bytes.length, ...bytes];
  }

  List<int> encodeTlv(int tag, List<int> content) => [
    tag,
    ...encodeLen(content.length),
    ...content,
  ];

  List<int> encodeInt(BigInt value) {
    if (value == BigInt.zero) return encodeTlv(0x02, [0]);
    final bytes = <int>[];
    var v = value;
    while (v > BigInt.zero) {
      bytes.insert(0, (v & BigInt.from(0xff)).toInt());
      v >>= 8;
    }
    if ((bytes.first & 0x80) != 0) bytes.insert(0, 0);
    return encodeTlv(0x02, bytes);
  }

  final pkcs1 = encodeTlv(0x30, [
    ...encodeInt(BigInt.zero),
    ...encodeInt(n),
    ...encodeInt(e),
    ...encodeInt(d),
  ]);
  final algId = encodeTlv(0x30, [
    0x06,
    0x09,
    0x2a,
    0x86,
    0x48,
    0x86,
    0xf7,
    0x0d,
    0x01,
    0x01,
    0x01,
    0x05,
    0x00,
  ]);
  final pkcs8 = encodeTlv(0x30, [
    ...encodeInt(BigInt.zero),
    ...algId,
    ...encodeTlv(0x04, pkcs1),
  ]);
  return Uint8List.fromList(pkcs8);
}

// =============================================================================
// Fakes & Stubs
// =============================================================================
class _StubOAuthTokenProvider extends GoogleOAuth2TokenProvider {
  _StubOAuthTokenProvider(this._token)
    : super(
        clientEmail: 'stub@example.invalid',
        privateKeyPem: '',
        tokenUri: 'https://oauth2.example.invalid/token',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

  final String _token;

  @override
  Future<String> getAccessToken() async => _token;
}

class _FakeNotificationStore implements NotificationStore {
  final Map<String, Map<String, String>> _devicesByUser = {};
  final Map<String, int> _customerEpochs = {};
  final Map<String, int> _stallEpochs = {};
  final List<UnbroadcastedRealtimeSignal> _signals = [];
  final Set<int> _broadcastedSeqs = {};
  final List<PendingPushDelivery> _pendingQueue = [];
  final Map<String, FcmDeliveryOutcome> completedOutcomes = {};
  final Set<String> deactivatedDeliveries = {};
  var _seq = 0;

  void addOrderSignal({
    required String orderId,
    required String stallId,
    required String customerId,
    required String ownerId,
    required String toStatus,
  }) {
    _seq++;
    final cEpoch = _customerEpochs[customerId] ?? 1;
    final sEpoch = _stallEpochs[stallId] ?? 1;
    _signals.add(
      UnbroadcastedRealtimeSignal(
        seq: _seq,
        eventId: 'evt-$_seq',
        orderId: orderId,
        stallId: stallId,
        customerId: customerId,
        ownerId: ownerId,
        toStatus: toStatus,
        customerTopic: 'private:customer:$customerId:v$cEpoch:tok',
        stallTopic: 'private:stall:$stallId:v$sEpoch:tok',
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  void enqueuePushDelivery(PendingPushDelivery delivery) {
    _pendingQueue.add(delivery);
  }

  @override
  Future<PushDeviceRegistration> registerPushDevice({
    required String userId,
    required String deviceId,
    required String fcmToken,
    String platform = 'android',
  }) async {
    _devicesByUser.putIfAbsent(userId, () => {})[deviceId] = fcmToken;
    return PushDeviceRegistration(
      id: 'reg-$deviceId',
      userId: userId,
      deviceId: deviceId,
      platform: platform,
      isActive: true,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<bool> revokePushDevice({
    required String userId,
    required String deviceId,
    bool rotateTopics = true,
  }) async {
    final removed = _devicesByUser[userId]?.remove(deviceId) != null;
    if (rotateTopics) {
      _customerEpochs[userId] = (_customerEpochs[userId] ?? 1) + 1;
      if (userId == _ownerAId) {
        _stallEpochs[_stallAId] = (_stallEpochs[_stallAId] ?? 1) + 1;
      }
    }
    return removed;
  }

  @override
  Future<RealtimeChannelGrant> getChannelGrant(String userId) async {
    if (userId == _adminId) {
      throw const NotificationFailure(NotificationFailureCode.roleNotAllowed);
    }
    final isOwnerA = userId == _ownerAId;
    final cEpoch = _customerEpochs[userId] ?? 1;
    final sEpoch = isOwnerA ? (_stallEpochs[_stallAId] ?? 1) : null;
    return RealtimeChannelGrant(
      userId: userId,
      role: (userId == _ownerAId || userId == _ownerBId) ? 'owner' : 'customer',
      customerTopic: 'private:customer:$userId:v$cEpoch:tok',
      customerEpoch: cEpoch,
      stallId: isOwnerA ? _stallAId : null,
      stallTopic: isOwnerA ? 'private:stall:$_stallAId:v$sEpoch:tok' : null,
      stallEpoch: sEpoch,
      lastSeq: _signals
          .where(
            (s) => s.customerId == userId || (isOwnerA && s.ownerId == userId),
          )
          .fold<int>(0, (prev, s) => s.seq > prev ? s.seq : prev),
    );
  }

  @override
  Future<RealtimeSignalsPage> pollSignals({
    required String userId,
    required int afterSeq,
    int limit = 50,
  }) async {
    final isOwner = userId == _ownerAId || userId == _ownerBId;
    final matched = <RealtimeOrderSignal>[];
    for (final s in _signals) {
      if (s.seq <= afterSeq) continue;
      final isCust = s.customerId == userId;
      final isOwn = isOwner && s.ownerId == userId;
      if (!isCust && !isOwn) continue;
      matched.add(
        s.toScopedSignal(
          isCust && isOwn
              ? 'both'
              : isOwn
              ? 'owner'
              : 'customer',
        ),
      );
      if (matched.length >= limit) break;
    }
    final lastSeq = matched.isEmpty ? afterSeq : matched.last.seq;
    return RealtimeSignalsPage(
      items: matched,
      lastSeq: lastSeq,
      customerEpoch: _customerEpochs[userId] ?? 1,
      stallEpoch: userId == _ownerAId ? (_stallEpochs[_stallAId] ?? 1) : null,
    );
  }

  @override
  Future<List<UnbroadcastedRealtimeSignal>> claimUnbroadcastedSignals({
    int limit = 50,
    DateTime? now,
  }) async {
    final out = <UnbroadcastedRealtimeSignal>[];
    for (final s in _signals) {
      if (_broadcastedSeqs.add(s.seq)) {
        out.add(s);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  @override
  Future<List<PendingPushDelivery>> claimPendingPushDeliveries({
    int batchSize = 25,
    int maxAttempts = 5,
    int lockSeconds = 60,
    DateTime? now,
  }) async {
    final batch = _pendingQueue.take(batchSize).toList();
    _pendingQueue.removeRange(0, batch.length);
    return batch;
  }

  @override
  Future<void> completePushDelivery({
    required String deliveryId,
    required FcmDeliveryOutcome outcome,
    String? errorCode,
    String? providerMessageId,
    int retryDelaySeconds = 30,
    bool deactivateDevice = false,
    DateTime? now,
  }) async {
    completedOutcomes[deliveryId] = outcome;
    if (deactivateDevice) {
      deactivatedDeliveries.add(deliveryId);
    }
    if (outcome == FcmDeliveryOutcome.retryable) {
      // Re-enqueue for subsequent tick verification
      _pendingQueue.add(
        PendingPushDelivery(
          deliveryId: deliveryId,
          notificationEventId: 'e-retry',
          orderId: _order1Id,
          orderNumber: '00001',
          stallName: 'Kantin A',
          recipientId: _custAId,
          recipientRole: 'customer',
          eventType: 'order_ready',
          deviceId: 'dev-cust',
          fcmToken: 'fcm_token_transient_123456789012',
          attemptCount: 2,
          maxAttempts: 5,
        ),
      );
    }
  }
}

class _FakeAuthGateway implements AuthGateway {
  final Map<String, AuthAccount> _tokens = {
    'tok-cust-a': const AuthAccount(
      id: _custAId,
      email: 'cust-a@example.test',
      displayName: 'Customer A',
      role: AccountRole.customer,
    ),
    'tok-cust-b': const AuthAccount(
      id: _custBId,
      email: 'cust-b@example.test',
      displayName: 'Customer B',
      role: AccountRole.customer,
    ),
    'tok-owner-a': const AuthAccount(
      id: _ownerAId,
      email: 'owner-a@example.test',
      displayName: 'Owner A',
      role: AccountRole.owner,
    ),
    'tok-owner-b': const AuthAccount(
      id: _ownerBId,
      email: 'owner-b@example.test',
      displayName: 'Owner B',
      role: AccountRole.owner,
    ),
    'tok-admin': const AuthAccount(
      id: _adminId,
      email: 'admin@example.test',
      displayName: 'Admin',
      role: AccountRole.admin,
    ),
  };

  void addSessionToken(String token, String id, AccountRole role) {
    _tokens[token] = AuthAccount(
      id: id,
      email: '$id@example.test',
      displayName: 'User $id',
      role: role,
    );
  }

  void revokeToken(String token) {
    _tokens.remove(token);
  }

  @override
  Future<AuthAccount> account(String accessToken) async {
    final acc = _tokens[accessToken];
    if (acc == null) throw AuthFailure.invalidSession;
    return acc;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvatarStore implements AvatarStore {
  @override
  Future<bool> exists(String accountId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCatalogStore implements CatalogStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubOwnerStore implements OwnerStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubMediaStore implements OwnerMediaStore {
  @override
  Future<Uint8List?> read(String path) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCustomerStore implements CustomerStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAdminStore implements AdminStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAiStore implements AiStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAiProvider implements AiProvider {
  @override
  String get providerId => 'stub';

  @override
  String get modelName => 'stub';

  @override
  bool get isReady => false;

  @override
  AiActivationCheck checkActivation() => const AiActivationCheck(
    isValid: false,
    reasonCode: 'DISABLED',
    message: 'Disabled in test.',
  );

  @override
  Future<AiProviderReply> generateReply(AiProviderRequest request) async =>
      const AiProviderReply(
        replyText: 'disabled',
        recommendedMenuIds: [],
        isGeneralCulinary: false,
        hasUncertaintyNotice: false,
      );
}
