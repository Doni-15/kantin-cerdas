import 'dart:convert';

import 'package:kantin_cerdas_backend/src/app/bootstrap.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/error_handler_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_id_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_logging_middleware.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_store.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider_config.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/realtime_broadcaster.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'config_test.dart' show validEnvironment;

void main() {
  group('requestIdMiddleware and log correlation', () {
    test('generates x-request-id when absent and echoes on response', () async {
      String? seenContextId;
      final handler = Pipeline()
          .addMiddleware(requestIdMiddleware())
          .addHandler((request) {
            seenContextId = requestIdFromContext(request);
            return Response.ok('ok');
          });

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/health')),
      );

      expect(seenContextId, isNotNull);
      expect(seenContextId, startsWith('req-'));
      expect(response.headers[requestIdHeader], seenContextId);
    });

    test(
      'preserves valid incoming x-request-id and rejects invalid one',
      () async {
        final handler = Pipeline()
            .addMiddleware(requestIdMiddleware())
            .addHandler((request) => Response.ok('ok'));

        final preserved = await handler(
          Request(
            'GET',
            Uri.parse('http://localhost/v1/health'),
            headers: {'x-request-id': 'trace.abc_123-XYZ'},
          ),
        );
        expect(preserved.headers['x-request-id'], 'trace.abc_123-XYZ');

        final replaced = await handler(
          Request(
            'GET',
            Uri.parse('http://localhost/v1/health'),
            headers: {'x-request-id': 'bad/header value!'},
          ),
        );
        expect(replaced.headers['x-request-id'], startsWith('req-'));
        expect(replaced.headers['x-request-id'], isNot('bad/header value!'));
      },
    );

    test(
      'correlates request_id across RequestLoggingMiddleware and ErrorHandlerMiddleware',
      () async {
        final accessLogs = <String>[];
        final errorLogs = <String>[];
        final loggingConfig = LoggingConfig.fromEnv(
          EnvConfig.fromMap(const {
            'LOG_LEVEL': 'info',
            'LOG_FORMAT': 'json',
            'LOG_REQUEST_ENABLED': 'true',
            'LOG_INCLUDE_STACK_TRACE': 'false',
          }),
        );

        final handler = Pipeline()
            .addMiddleware(requestIdMiddleware())
            .addMiddleware(
              RequestLoggingMiddleware(
                config: loggingConfig,
                writer: accessLogs.add,
                clock: () => DateTime.utc(2026, 11, 22),
              ).middleware,
            )
            .addMiddleware(
              ErrorHandlerMiddleware(
                config: loggingConfig,
                writer: errorLogs.add,
                clock: () => DateTime.utc(2026, 11, 22),
              ).middleware,
            )
            .addHandler((_) => throw StateError('boom'));

        final response = await handler(
          Request(
            'GET',
            Uri.parse('http://localhost/v1/boom'),
            headers: {'x-request-id': 'req-corr-42'},
          ),
        );

        expect(response.statusCode, 500);
        expect(response.headers['x-request-id'], 'req-corr-42');
        expect(accessLogs, hasLength(1));
        expect(errorLogs, hasLength(1));

        final accessJson =
            jsonDecode(accessLogs.single) as Map<String, dynamic>;
        final errorJson = jsonDecode(errorLogs.single) as Map<String, dynamic>;
        expect(accessJson['request_id'], 'req-corr-42');
        expect(errorJson['request_id'], 'req-corr-42');
      },
    );
  });

  group('AppRuntime lifecycle disposal', () {
    test('dispose() closes FcmTransport and RealtimeBroadcaster', () async {
      final fcm = _SpyFcmTransport();
      final broadcaster = _SpyRealtimeBroadcaster();
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

      final runtime = buildAppRuntime(
        cfg,
        authGateway: _DummyAuthGateway(),
        avatarStore: _DummyAvatarStore(),
        catalogStore: _DummyCatalogStore(),
        ownerStore: _DummyOwnerStore(),
        ownerMediaStore: _DummyOwnerMediaStore(),
        customerStore: _DummyCustomerStore(),
        adminStore: _DummyAdminStore(),
        aiStore: _DummyAiStore(),
        aiProvider: _DummyAiProvider(),
        notificationStore: _DummyNotificationStore(),
        fcmTransport: fcm,
        realtimeBroadcaster: broadcaster,
      );

      final res = await runtime.handler(
        Request(
          'GET',
          Uri.parse('https://api.example.test/v1/health'),
          headers: {'host': 'api.example.test'},
        ),
      );
      expect(res.statusCode, 200);
      expect(res.headers['x-request-id'], startsWith('req-'));
      expect(fcm.closed, isFalse);
      expect(broadcaster.closed, isFalse);

      await runtime.dispose();
      expect(fcm.closed, isTrue);
      expect(broadcaster.closed, isTrue);
    });
  });
}

class _SpyFcmTransport implements FcmTransport {
  var closed = false;

  @override
  bool get isLiveEnabled => false;

  @override
  Future<FcmSendResult> send(FcmMessagePayload payload) async =>
      const FcmSendResult.skipped('TEST');

  @override
  void close() {
    closed = true;
  }
}

class _SpyRealtimeBroadcaster implements RealtimeBroadcaster {
  var closed = false;

  @override
  bool get isEnabled => false;

  @override
  Future<void> publish(List<UnbroadcastedRealtimeSignal> signals) async {}

  @override
  void close() {
    closed = true;
  }
}

class _DummyAuthGateway implements AuthGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyAvatarStore implements AvatarStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyCatalogStore implements CatalogStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyOwnerStore implements OwnerStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyOwnerMediaStore implements OwnerMediaStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyCustomerStore implements CustomerStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyAdminStore implements AdminStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyAiStore implements AiStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyAiProvider implements AiProvider {
  @override
  String get modelName => 'test';

  @override
  String get providerId => 'test';

  @override
  bool get isReady => false;

  @override
  AiActivationCheck checkActivation() => const AiActivationCheck(
    isValid: false,
    reasonCode: 'disabled',
    message: 'disabled',
  );

  @override
  Future<AiProviderReply> generateReply(AiProviderRequest request) =>
      throw UnimplementedError();
}

class _DummyNotificationStore implements NotificationStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
