import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';

Middleware requestHeaderGuard({
  required SecurityConfig securityConfig,
  required ServerConfig serverConfig,
}) {
  return (Handler innerHandler) {
    return (Request request) {
      // 1. Validate Host header.
      final rawHost = request.headers['host'];

      if (rawHost == null || rawHost.trim().isEmpty) {
        return ApiResponse.error(
          statusCode: 400,
          code: 'MISSING_HOST_HEADER',
          message: 'Header Host wajib disertakan.',
        );
      }

      final normalizedHost = _normalizeHost(rawHost);

      if (normalizedHost == null) {
        return ApiResponse.error(
          statusCode: 400,
          code: 'INVALID_HOST_HEADER',
          message: 'Format header Host tidak valid.',
        );
      }

      if (!securityConfig.allowAnyHost &&
          !securityConfig.allowedHosts.any(
            (allowedHost) => _hostMatches(normalizedHost, allowedHost),
          )) {
        return ApiResponse.error(
          statusCode: 403,
          code: 'HOST_NOT_ALLOWED',
          message: 'Host tidak diizinkan mengakses server.',
        );
      }

      // 2. Validate Content-Length when provided.
      final contentLength = request.headers['content-length'];

      if (contentLength != null) {
        final declaredLength = int.tryParse(contentLength.trim());

        if (declaredLength == null || declaredLength < 0) {
          return ApiResponse.error(
            statusCode: 400,
            code: 'INVALID_CONTENT_LENGTH',
            message: 'Header Content-Length tidak valid.',
          );
        }

        if (declaredLength > serverConfig.maxRequestBodyBytes) {
          return ApiResponse.error(
            statusCode: 413,
            code: 'REQUEST_BODY_TOO_LARGE',
            message: 'Ukuran request body melebihi batas yang diizinkan.',
          );
        }
      }

      // Do not read or buffer the request body here.
      return innerHandler(request);
    };
  };
}

String? _normalizeHost(String value) {
  final host = value.trim().toLowerCase();

  if (host.isEmpty || host.contains(RegExp(r'\s'))) {
    return null;
  }

  final uri = Uri.tryParse('http://$host');

  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.path.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }

  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
    return null;
  }

  if (uri.authority != host) {
    return null;
  }

  return host;
}

bool _hostMatches(String requestHost, String allowedHost) {
  final allowed = allowedHost.toLowerCase();

  if (_hasExplicitPort(allowed)) {
    return requestHost == allowed;
  }

  return _stripPort(requestHost) == allowed;
}

bool _hasExplicitPort(String host) {
  if (host.startsWith('[')) {
    final closingBracket = host.indexOf(']');
    return closingBracket >= 0 &&
        host.substring(closingBracket + 1).startsWith(':');
  }

  final firstColon = host.indexOf(':');
  final lastColon = host.lastIndexOf(':');

  return firstColon >= 0 && firstColon == lastColon;
}

String _stripPort(String host) {
  if (host.startsWith('[')) {
    final closingBracket = host.indexOf(']');

    if (closingBracket >= 0) {
      return host.substring(0, closingBracket + 1);
    }
  }

  final firstColon = host.indexOf(':');
  final lastColon = host.lastIndexOf(':');

  if (firstColon >= 0 && firstColon == lastColon) {
    return host.substring(0, firstColon);
  }

  return host;
}
