import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/security/auth_web_session.dart';
import 'package:shelf/shelf.dart';

Response authPhotoResponse(Uint8List jpeg) => Response.ok(
  jpeg,
  headers: {
    'content-type': 'image/jpeg',
    'content-disposition': 'inline; filename="avatar.jpg"',
    'x-content-type-options': 'nosniff',
  },
);

Response authSessionResponse(
  AuthSession session,
  Map<String, Object?> account, {
  AuthWebSessionCookie? cookie,
}) => ApiResponse.success(
  data: {
    'access_token': session.accessToken,
    if (cookie == null) 'refresh_token': session.refreshToken,
    'expires_at': session.expiresAt.toIso8601String(),
    'account': account,
  },
  headers: {
    if (cookie != null) 'set-cookie': cookie.serialize(session.refreshToken),
  },
);

Map<String, Object?> authAccountJson(
  AuthAccount account, {
  required bool hasPhoto,
}) => {
  'id': account.id,
  'email': account.email,
  'role': account.role.name,
  'display_name': account.displayName,
  'suggested_name': account.suggestedName,
  'has_photo': hasPhoto,
  'google_photo': account.googlePhoto?.toString(),
  'can_manage_credentials': account.canManageCredentials,
  'profile_complete': account.displayName != null && hasPhoto,
};
