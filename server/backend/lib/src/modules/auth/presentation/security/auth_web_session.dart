import 'dart:io';

import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:shelf/shelf.dart';

class AuthWebSessionCookie {
  const AuthWebSessionCookie();

  static const _name = '__Host-kc_refresh';
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9._~-]{1,4096}$');

  String? read(Request request) {
    final header = request.headers['cookie'];
    if (header == null || header.length > 8192) return null;
    String? found;
    for (final pair in header.split(';')) {
      final trimmed = pair.trim();
      if (!trimmed.startsWith('$_name=')) continue;
      final value = trimmed.substring(_name.length + 1);
      if (found != null || !_tokenPattern.hasMatch(value)) return null;
      found = value;
    }
    return found;
  }

  String serialize(String token) {
    if (token.isNotEmpty && !_tokenPattern.hasMatch(token)) {
      throw AuthFailure.unavailable;
    }
    return (Cookie(_name, token)
          ..maxAge = token.isEmpty ? 0 : const Duration(days: 30).inSeconds
          ..path = '/'
          ..httpOnly = true
          ..secure = true
          ..sameSite = SameSite.strict)
        .toString();
  }

  Response empty() =>
      ApiResponse.success(data: null, headers: {'set-cookie': serialize('')});
}
