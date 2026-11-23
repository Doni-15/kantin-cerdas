import 'dart:math';

import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/config/storage_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/core/media/avatar_image.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/application/owner_service.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/owner_request_parser.dart';
import 'package:shelf/shelf.dart';

class OwnerRouteContext {
  const OwnerRouteContext({
    required this.auth,
    required this.avatars,
    required this.service,
    required this.storage,
  });

  final AuthGateway auth;
  final AvatarStore avatars;
  final OwnerService service;
  final StorageConfig storage;

  Future<AuthAccount> requireOwner(Request request) async {
    final actor = await auth.account(requireBearer(request));
    if (actor.displayName == null || !await avatars.exists(actor.id)) {
      throw AuthFailure.profileIncomplete;
    }
    if (actor.role != AccountRole.owner) {
      throw const OwnerFailure(OwnerFailureCode.ownerRoleRequired);
    }
    return actor;
  }

  Future<Response> handlePhotoUpload(
    Request request, {
    required Future<List<int>> Function(List<int> bytes, String mediaType)
    onUpload,
  }) async {
    final mediaType = normalizedMediaType(request);
    if (mediaType == null || !storage.allowedImageTypes.contains(mediaType)) {
      throw const OwnerFailure(OwnerFailureCode.unsupportedMediaType);
    }
    final bytes = await readOwnerBytes(
      request,
      limit: min(storage.maxUploadBytes, maxAvatarInputBytes),
    );
    final jpeg = await onUpload(bytes, mediaType);
    return jpegDownloadResponse(jpeg);
  }
}
