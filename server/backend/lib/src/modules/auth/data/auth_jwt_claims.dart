import 'dart:convert';

import 'package:kantin_cerdas_backend/src/core/config/auth_config.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';

final _lowercaseUuid = RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$');

/// Supabase verifies the signature on GET /user or issues the session itself.
/// These checks additionally restrict which verified JWTs Shelf accepts.
({String user, String session}) readVerifiedJwtClaims(
  String jwt,
  AuthConfig settings,
) {
  try {
    final parts = jwt.split('.');
    if (parts.length != 3) throw const FormatException();
    Object? decode(String part) =>
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(part))));
    final header = decode(parts[0]);
    final body = decode(parts[1]);
    if (header is! Map<String, dynamic> || body is! Map<String, dynamic>) {
      throw const FormatException();
    }
    final expired = body['exp'];
    final starts = body['nbf'];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final skew = settings.clockSkew.inSeconds;
    final audience = body['aud'];
    final sub = body['sub'];
    final sid = body['session_id'];
    if (!settings.allowedAlgorithms.contains(header['alg']) ||
        body['iss'] != settings.issuer.toString() ||
        !(audience == settings.audience ||
            audience is List && audience.contains(settings.audience)) ||
        body['role'] != 'authenticated' ||
        expired is! int ||
        expired <= now - skew ||
        (starts != null && (starts is! int || starts > now + skew)) ||
        sub is! String ||
        !_lowercaseUuid.hasMatch(sub) ||
        sid is! String ||
        !_lowercaseUuid.hasMatch(sid)) {
      throw const FormatException();
    }
    return (user: sub, session: sid);
  } on FormatException {
    throw AuthFailure.invalidSession;
  }
}
