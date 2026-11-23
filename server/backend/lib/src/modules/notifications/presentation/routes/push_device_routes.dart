import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/notifications_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/routes/notifications_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerPushDeviceRoutes(
  Router router, {
  required NotificationsRouteContext context,
}) {
  // Register or refresh Android FCM device token for authenticated Customer/Owner.
  router.post('/devices', (Request request) async {
    final (_, actor) = await context.requireParticipant(request);
    final body = await readNotificationJsonObject(request);
    final deviceId = requireNotificationTrimmedString(
      body['device_id'],
      field: 'device_id',
      minLen: 1,
      maxLen: 128,
    );
    final fcmToken = requireNotificationTrimmedString(
      body['fcm_token'],
      field: 'fcm_token',
      minLen: 16,
      maxLen: 512,
    );
    final rawPlatform = body['platform'];
    final platform = rawPlatform == null
        ? 'android'
        : rawPlatform.toString().trim().toLowerCase();
    if (platform != 'android') {
      throw const NotificationFailure(
        NotificationFailureCode.invalidInput,
        'Platform notifikasi yang didukung pada MVP adalah android.',
      );
    }

    final registered = await context.service.registerDevice(
      userId: actor.id,
      deviceId: deviceId,
      fcmToken: fcmToken,
      platform: platform,
    );
    return ApiResponse.success(
      data: registered.toJson(),
      headers: noStoreHeaders,
    );
  });

  // Revoke device push registration & rotate private realtime topics on logout (R2).
  router.delete('/devices/<deviceId>', (
    Request request,
    String deviceId,
  ) async {
    final (_, actor) = await context.requireParticipant(request);
    final cleanId = deviceId.trim();
    if (cleanId.isEmpty || cleanId.length > 128) {
      throw const NotificationFailure(
        NotificationFailureCode.invalidInput,
        'device_id tidak valid.',
      );
    }
    final rotateParam = request.url.queryParameters['rotate_topic']
        ?.trim()
        .toLowerCase();
    final rotateTopics = rotateParam != 'false' && rotateParam != '0';

    final revoked = await context.service.revokeDevice(
      userId: actor.id,
      deviceId: cleanId,
      rotateTopics: rotateTopics,
    );
    return ApiResponse.success(
      data: {
        'device_id': cleanId,
        'revoked': revoked,
        'topics_rotated': rotateTopics,
      },
      headers: noStoreHeaders,
    );
  });
}
