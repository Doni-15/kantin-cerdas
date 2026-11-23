import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/notifications_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/realtime_sse_stream.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/routes/notifications_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerRealtimeRoutes(
  Router router, {
  required NotificationsRouteContext context,
}) {
  // Authorized private channel topic grant (RT-TECH-003, RT-TECH-005).
  router.get('/realtime/grant', (Request request) async {
    final (_, actor) = await context.requireParticipant(request);
    final grant = await context.service.getChannelGrant(actor.id);
    return ApiResponse.success(data: grant.toJson(), headers: noStoreHeaders);
  });

  // Strictly scoped catch-up & fallback signal polling (ORDER-017).
  router.get('/realtime/signals', (Request request) async {
    final (_, actor) = await context.requireParticipant(request);
    final params = request.url.queryParameters;
    final afterSeq = parseNotificationNonNegativeInt(
      params['after_seq'],
      defaultValue: 0,
    );
    final limit = parseNotificationBoundedInt(
      params['limit'],
      defaultValue: 50,
      min: 1,
      max: 100,
    );
    final page = await context.service.pollSignals(
      userId: actor.id,
      afterSeq: afterSeq,
      limit: limit,
    );
    return ApiResponse.success(data: page.toJson(), headers: noStoreHeaders);
  });

  router.get('/realtime/stream', (Request request) async {
    final (bearer, actor) = await context.requireParticipant(request);
    final params = request.url.queryParameters;
    final afterSeq = parseNotificationNonNegativeInt(
      params['after_seq'],
      defaultValue: 0,
    );
    final maxDurationParam = params['max_seconds'];
    final maxDurationSeconds = maxDurationParam == null
        ? null
        : parseNotificationBoundedInt(
            maxDurationParam,
            defaultValue: 60,
            min: 1,
            max: 300,
          );

    return openRealtimeSseStream(
      auth: context.auth,
      service: context.service,
      bearer: bearer,
      actor: actor,
      afterSeq: afterSeq,
      maxDurationSeconds: maxDurationSeconds,
    );
  });
}
