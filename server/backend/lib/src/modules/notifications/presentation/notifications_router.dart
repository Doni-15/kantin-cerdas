import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/application/notifications_service.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/notifications_failure_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/routes/notification_status_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/routes/notifications_route_context.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/routes/push_device_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/routes/realtime_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildNotificationsHandler(
  AuthGateway auth, {
  required AvatarStore avatars,
  required NotificationsService service,
}) {
  final router = Router(notFoundHandler: notFoundNoStoreResponse);
  final context = NotificationsRouteContext(
    auth: auth,
    avatars: avatars,
    service: service,
  );

  registerNotificationStatusRoutes(router, context: context);
  registerPushDeviceRoutes(router, context: context);
  registerRealtimeRoutes(router, context: context);

  return (Request request) async {
    try {
      return await router.call(request);
    } on AuthFailure catch (failure) {
      final error = authFailureException(failure);
      return ApiResponse.error(
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        headers: noStoreHeaders,
      );
    } on NotificationFailure catch (failure) {
      final error = notificationFailureException(failure);
      return ApiResponse.error(
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        headers: noStoreHeaders,
      );
    } on ApiException catch (error) {
      return ApiResponse.error(
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        headers: noStoreHeaders,
      );
    }
  };
}
