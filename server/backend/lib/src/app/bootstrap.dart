import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kantin_cerdas_backend/src/app/middleware_pipeline.dart';
import 'package:kantin_cerdas_backend/src/app/router.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/application/admin_service.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/data/supabase_admin_store.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_store.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/admin_router.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/application/ai_service.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/data/gemini_ai_provider.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/data/supabase_ai_store.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider_config.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_store.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/presentation/ai_router.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/supabase_auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/supabase_avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/auth_router.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/data/supabase_catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/catalog_router.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/application/customer_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/data/supabase_customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_router.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/application/notifications_service.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/data/http_fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/data/supabase_notification_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/data/supabase_realtime_broadcaster.dart'
    show SupabaseHttpRealtimeBroadcaster;
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notifications_config.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/realtime_broadcaster.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/notifications_router.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/application/owner_service.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/data/supabase_owner_media_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/data/supabase_owner_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/owner_router.dart';
import 'package:shelf/shelf.dart';

part 'bootstrap_compat.dart';

class AppRuntime {
  const AppRuntime({required this.handler, required this.dispose});

  final Handler handler;
  final Future<void> Function() dispose;
}

/// Canonical composition root activating Health, Auth, Catalog, Owner, Customer,
/// Admin, AI Food Assistant, and Realtime/Push Notifications in one Shelf process.
AppRuntime buildAppRuntime(
  AppConfig config, {
  EnvConfig? env,
  AiProviderConfig? aiConfig,
  NotificationsConfig? notificationsConfig,
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
  CustomerStore? customerStore,
  AdminStore? adminStore,
  AiStore? aiStore,
  AiProvider? aiProvider,
  NotificationStore? notificationStore,
  FcmTransport? fcmTransport,
  RealtimeBroadcaster? realtimeBroadcaster,
}) {
  final factory = SupabaseClientFactory(config: config.supabase);

  final auth =
      authGateway ??
      SupabaseAuthGateway(
        SupabaseAuthDataSource(
          clientFactory: factory,
          requestTimeout: config.supabase.requestTimeout,
        ),
        config: config.auth,
        onSignupFailure: (code, status) =>
            _logSignupFailure(config.logging, code, status),
      );

  final avatars =
      avatarStore ??
      SupabaseAvatarStore(factory, timeout: config.supabase.requestTimeout);
  final catalog = catalogStore ?? SupabaseCatalogStore(factory);
  final resolvedOwnerStore = ownerStore ?? SupabaseOwnerStore(factory);
  final resolvedOwnerMedia =
      ownerMediaStore ??
      SupabaseOwnerMediaStore(
        factory,
        bucketName: config.storage.bucketName,
        timeout: config.supabase.requestTimeout,
      );
  final resolvedCustomerStore = customerStore ?? SupabaseCustomerStore(factory);
  final resolvedAdminStore = adminStore ?? SupabaseAdminStore(factory);

  final resolvedAiConfig =
      aiConfig ??
      (env != null
          ? AiProviderConfig.fromEnv(env)
          : const AiProviderConfig.disabled());
  final resolvedAiStore = aiStore ?? SupabaseAiStore(factory);
  final resolvedAiProvider =
      aiProvider ?? GeminiAiProvider(config: resolvedAiConfig);

  final notificationsService = _buildNotificationsService(
    config,
    factory: factory,
    env: env,
    notificationsConfig: notificationsConfig,
    notificationStore: notificationStore,
    fcmTransport: fcmTransport,
    realtimeBroadcaster: realtimeBroadcaster,
  );

  final authHandler = buildAuthHandler(
    auth,
    avatars: avatars,
    storage: config.storage,
    webOrigin: config.auth.webOrigin,
    googleEnabled: config.auth.googleEnabled,
    supabaseUrl: config.supabase.url,
  );

  final catalogHandler = buildCatalogHandler(auth, avatars, catalog);

  final ownerHandler = _withBestEffortNotificationDispatch(
    buildOwnerHandler(
      auth,
      avatars: avatars,
      service: OwnerService(
        store: resolvedOwnerStore,
        mediaStore: resolvedOwnerMedia,
      ),
      storage: config.storage,
    ),
    notificationsService,
  );

  final customerHandler = _withBestEffortNotificationDispatch(
    buildCustomerHandler(
      auth,
      avatars: avatars,
      service: CustomerService(
        store: resolvedCustomerStore,
        readMedia: resolvedOwnerMedia.read,
      ),
    ),
    notificationsService,
  );

  final adminHandler = buildAdminHandler(
    auth,
    avatars: avatars,
    service: AdminService(
      store: resolvedAdminStore,
      readMedia: resolvedOwnerMedia.read,
    ),
  );

  final aiHandler = buildAiHandler(
    auth,
    avatars: avatars,
    service: AiService(
      store: resolvedAiStore,
      provider: resolvedAiProvider,
      config: resolvedAiConfig,
    ),
  );

  final notificationsHandler = buildNotificationsHandler(
    auth,
    avatars: avatars,
    service: notificationsService,
  );

  final router = buildRouter(
    config,
    authHandler: authHandler,
    catalogHandler: catalogHandler,
    ownerHandler: ownerHandler,
    customerHandler: customerHandler,
    adminHandler: adminHandler,
    aiHandler: aiHandler,
    notificationsHandler: notificationsHandler,
  );

  final pipeline = buildMiddlewarePipeline(config);

  return AppRuntime(
    handler: pipeline.addHandler(router.call),
    dispose: () async {
      notificationsService.dispose();
    },
  );
}

Handler buildAppHandler(
  AppConfig config, {
  EnvConfig? env,
  AiProviderConfig? aiConfig,
  NotificationsConfig? notificationsConfig,
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
  CustomerStore? customerStore,
  AdminStore? adminStore,
  AiStore? aiStore,
  AiProvider? aiProvider,
  NotificationStore? notificationStore,
  FcmTransport? fcmTransport,
  RealtimeBroadcaster? realtimeBroadcaster,
}) => buildAppRuntime(
  config,
  env: env,
  aiConfig: aiConfig,
  notificationsConfig: notificationsConfig,
  authGateway: authGateway,
  avatarStore: avatarStore,
  catalogStore: catalogStore,
  ownerStore: ownerStore,
  ownerMediaStore: ownerMediaStore,
  customerStore: customerStore,
  adminStore: adminStore,
  aiStore: aiStore,
  aiProvider: aiProvider,
  notificationStore: notificationStore,
  fcmTransport: fcmTransport,
  realtimeBroadcaster: realtimeBroadcaster,
).handler;

NotificationsService _buildNotificationsService(
  AppConfig config, {
  required SupabaseClientFactory factory,
  EnvConfig? env,
  NotificationsConfig? notificationsConfig,
  NotificationStore? notificationStore,
  FcmTransport? fcmTransport,
  RealtimeBroadcaster? realtimeBroadcaster,
}) {
  final resolvedNotifConfig =
      notificationsConfig ??
      (env != null
          ? NotificationsConfig.fromEnv(env)
          : const NotificationsConfig.defaults());
  final resolvedNotifStore =
      notificationStore ?? SupabaseNotificationStore(factory);
  final resolvedFcmTransport =
      fcmTransport ??
      (resolvedNotifConfig.isFcmActive
          ? HttpFcmTransport(config: resolvedNotifConfig)
          : const DisabledFcmTransport());
  final resolvedBroadcaster =
      realtimeBroadcaster ??
      (resolvedNotifConfig.supabaseBroadcastEnabled
          ? SupabaseHttpRealtimeBroadcaster(
              supabaseConfig: config.supabase,
              enabled: true,
            )
          : const NoopRealtimeBroadcaster());
  return NotificationsService(
    store: resolvedNotifStore,
    fcmTransport: resolvedFcmTransport,
    broadcaster: resolvedBroadcaster,
    config: resolvedNotifConfig,
  );
}

void _logSignupFailure(LoggingConfig logging, String code, int? status) {
  final timestamp = DateTime.now().toIso8601String();
  if (logging.isJsonFormat) {
    stderr.writeln(
      jsonEncode({
        'timestamp': timestamp,
        'level': 'error',
        'event': 'auth.signup',
        'provider_code': code,
        'provider_status': status,
      }),
    );
  } else {
    stderr.writeln(
      '$timestamp ERROR auth.signup '
      'provider_code=$code provider_status=${status ?? '-'}',
    );
  }
}

Handler _withBestEffortNotificationDispatch(
  Handler inner,
  NotificationsService service,
) {
  return (Request request) async {
    final response = await inner(request);
    final isMutation =
        request.method == 'POST' ||
        request.method == 'PUT' ||
        request.method == 'PATCH' ||
        request.method == 'DELETE';
    if (isMutation && response.statusCode >= 200 && response.statusCode < 300) {
      final hasLiveTarget =
          service.broker.subscriberCount > 0 ||
          service.pushWorker.isEnabled ||
          service.config.supabaseBroadcastEnabled;
      if (hasLiveTarget) {
        unawaited(service.dispatchPendingBestEffort());
      }
    }
    return response;
  };
}
