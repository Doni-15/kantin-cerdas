import 'package:shelf/shelf.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/config/cors_config.dart';

const _varyHeaders =
    'Origin, Access-Control-Request-Method, Access-Control-Request-Headers';

Middleware corsMiddleware(CorsConfig config) {
  return (Handler innerHandler) {
    return (Request request) async {
      if (!config.enabled) {
        return innerHandler(request);
      }

      final origin = request.headers['origin'];

      if (origin == null || origin.isEmpty) {
        return innerHandler(request);
      }

      final normalizedOrigin = _normalizeOrigin(origin);

      final isAllowedOrigin =
          normalizedOrigin != null &&
          (config.allowAnyOrigin ||
              config.allowedOrigins.contains(normalizedOrigin));

      final isPreflight =
          request.method.toUpperCase() == 'OPTIONS' &&
          request.headers.containsKey('access-control-request-method');

      if (!isAllowedOrigin) {
        if (isPreflight) {
          return _rejectedPreflight();
        }

        // Non-browser clients are not blocked by CORS.
        return innerHandler(request);
      }

      if (isPreflight) {
        return _handlePreflight(request, config, origin);
      }

      final response = await innerHandler(request);

      return response.change(
        headers: _corsHeaders(config, origin, includePreflightHeaders: false),
      );
    };
  };
}

Response _handlePreflight(Request request, CorsConfig config, String origin) {
  final requestedMethod = request.headers['access-control-request-method']
      ?.toUpperCase();

  if (requestedMethod == null ||
      !config.allowedMethods.contains(requestedMethod)) {
    return _rejectedPreflight();
  }

  final requestedHeaders = request.headers['access-control-request-headers'];

  if (requestedHeaders != null && requestedHeaders.trim().isNotEmpty) {
    final allowedHeaders = config.allowedHeaders
        .map((header) => header.toLowerCase())
        .toSet();

    final requested = requestedHeaders
        .split(',')
        .map((header) => header.trim().toLowerCase())
        .where((header) => header.isNotEmpty);

    if (requested.any((header) => !allowedHeaders.contains(header))) {
      return _rejectedPreflight();
    }
  }

  return Response(
    204,
    headers: _corsHeaders(config, origin, includePreflightHeaders: true),
  );
}

Response _rejectedPreflight() {
  return ApiResponse.error(
    statusCode: 403,
    code: 'CORS_PREFLIGHT_REJECTED',
    message: 'Permintaan CORS preflight ditolak.',
    headers: {'vary': _varyHeaders},
  );
}

Map<String, String> _corsHeaders(
  CorsConfig config,
  String origin, {
  required bool includePreflightHeaders,
}) {
  final headers = <String, String>{
    'access-control-allow-origin': config.allowAnyOrigin ? '*' : origin,
    'vary': _varyHeaders,
  };

  if (config.allowCredentials) {
    headers['access-control-allow-credentials'] = 'true';
  }

  if (includePreflightHeaders) {
    headers['access-control-allow-methods'] = config.allowedMethods.join(', ');

    headers['access-control-allow-headers'] = config.allowedHeaders.join(', ');

    headers['access-control-max-age'] = config.maxAge.inSeconds.toString();
  }

  return headers;
}

String? _normalizeOrigin(String value) {
  final uri = Uri.tryParse(value);

  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    return null;
  }

  return uri.origin;
}
