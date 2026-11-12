import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:kantin_cerdas_backend/src/core/middleware/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_service.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_validator.dart';

/// Router modul Media (`POST /v1/media/images`).
Router buildMediaRouter({
  required AuthService authService,
  required MediaService mediaService,
}) {
  final router = Router();
  final guard = authGuard(authService);

  router.post(
    '/images',
    guard((Request request) async {
      final actor = request.authActor;
      final input = await MediaValidator.validateUploadRequest(
        request: request,
        actorId: actor.id,
        actorRole: actor.role,
        storage: mediaService.config.storage,
      );

      final result = await mediaService.uploadAndRegisterImage(
        actor: actor,
        input: input,
      );

      return Response(
        201,
        body: jsonEncode(result),
        headers: const {
          'content-type': 'application/json; charset=utf-8',
          'cache-control': 'no-store',
        },
      );
    }),
  );

  return router;
}
