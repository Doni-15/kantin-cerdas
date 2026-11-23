import 'dart:math';
import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/config/storage_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/core/media/avatar_image.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_body.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_response_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerProfileRoutes(
  Router router, {
  required AuthRouteContext context,
  required StorageConfig storage,
}) {
  var activeImageWorkers = 0;

  router.get('/me', (Request request) async {
    return ApiResponse.success(
      data: await context.accountJson(
        await context.auth.account(requireBearer(request)),
      ),
    );
  });

  router.put('/profile', (Request request) async {
    final token = requireBearer(request);
    final body = await readAuthJsonBody(request);
    final name = readAuthDisplayName(body);
    final actor = await context.auth.account(token);
    if (!await context.avatars.exists(actor.id)) {
      throw AuthFailure.profileIncomplete;
    }
    return ApiResponse.success(
      data: authAccountJson(
        await context.auth.setDisplayName(actor, name),
        hasPhoto: true,
      ),
    );
  });

  router.get('/profile/photo', (Request request) async {
    final actor = await context.auth.account(requireBearer(request));
    final jpeg = await context.avatars.read(actor.id);
    if (jpeg == null) return Response(204);
    return authPhotoResponse(jpeg);
  });

  router.put('/profile/photo', (Request request) async {
    final bearer = requireBearer(request);
    final mediaType = normalizedMediaType(request);

    if (mediaType == null || !storage.allowedImageTypes.contains(mediaType)) {
      throw ApiException(
        statusCode: 415,
        code: 'UNSUPPORTED_MEDIA_TYPE',
        message: 'Format foto profil tidak didukung.',
      );
    }
    final actor = await context.auth.account(bearer);

    final bytes = await readAuthBytes(
      request,
      limit: min(storage.maxUploadBytes, maxAvatarInputBytes),
    );

    if (activeImageWorkers >= 2) throw AuthFailure.unavailable;
    final Uint8List? jpeg;
    activeImageWorkers++;

    try {
      jpeg = await normalizeAvatar(bytes, mediaType);
    } finally {
      activeImageWorkers--;
    }

    if (jpeg == null) {
      throw ApiException(
        statusCode: 422,
        code: 'INVALID_PROFILE_PHOTO',
        message:
            'Pilih foto yang valid dengan ukuran hingga 4096 × 4096 piksel.',
      );
    }

    await context.avatars.write(actor.id, jpeg);
    return authPhotoResponse(jpeg);
  });

  router.post('/profile/photo/google', (Request request) async {
    final actor = await context.auth.account(requireBearer(request));
    final url = actor.googlePhoto;

    if (url == null) {
      throw invalidAuthInput(
        'Foto default Google tidak tersedia untuk profil ini.',
      );
    }

    final existing = await context.avatars.read(actor.id);

    if (existing != null) return authPhotoResponse(existing);
    if (activeImageWorkers >= 2) throw AuthFailure.unavailable;
    activeImageWorkers++;

    try {
      final jpeg = await context.avatars.importGooglePhoto(
        actor.id,
        url,
        maxBytes: min(storage.maxUploadBytes, maxAvatarInputBytes),
      );
      return authPhotoResponse(jpeg);
    } finally {
      activeImageWorkers--;
    }
  });
}
