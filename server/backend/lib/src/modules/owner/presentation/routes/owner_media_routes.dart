import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/owner_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerOwnerMediaRoutes(
  Router router, {
  required OwnerRouteContext context,
}) {
  router.get('/stall/photo', (Request request) async {
    final owner = await context.requireOwner(request);
    return jpegDownloadResponse(await context.service.readStallPhoto(owner.id));
  });

  router.put('/stall/photo', (Request request) async {
    final owner = await context.requireOwner(request);
    return context.handlePhotoUpload(
      request,
      onUpload: (bytes, mediaType) {
        return context.service.uploadStallPhoto(
          owner.id,
          bytes: Uint8List.fromList(bytes),
          mediaType: mediaType,
        );
      },
    );
  });

  router.delete('/stall/photo', (Request request) async {
    final owner = await context.requireOwner(request);
    return ApiResponse.success(
      data: await context.service.removeStallPhoto(owner.id),
      headers: noStoreHeaders,
    );
  });

  router.get('/menus/<id>/photo', (Request request, String id) async {
    final owner = await context.requireOwner(request);
    return jpegDownloadResponse(
      await context.service.readMenuPhoto(
        owner.id,
        menuId: requireOwnerUuid(id),
      ),
    );
  });

  router.put('/menus/<id>/photo', (Request request, String id) async {
    final owner = await context.requireOwner(request);
    final menuId = requireOwnerUuid(id);
    return context.handlePhotoUpload(
      request,
      onUpload: (bytes, mediaType) {
        return context.service.uploadMenuPhoto(
          owner.id,
          menuId: menuId,
          bytes: Uint8List.fromList(bytes),
          mediaType: mediaType,
        );
      },
    );
  });

  router.delete('/menus/<id>/photo', (Request request, String id) async {
    final owner = await context.requireOwner(request);
    return ApiResponse.success(
      data: await context.service.removeMenuPhoto(
        owner.id,
        menuId: requireOwnerUuid(id),
      ),
      headers: noStoreHeaders,
    );
  });
}
