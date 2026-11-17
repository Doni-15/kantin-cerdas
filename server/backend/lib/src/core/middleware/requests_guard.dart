import 'dart:typed_data';
import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';

Middleware requestsGuard({
  required SecurityConfig securityConfig,
  required ServerConfig serverConfig,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 1. Validate Host header.
      final rawHost = request.headers['host'];

      if (rawHost == null || rawHost.trim().isEmpty) {
        return Response(400, body: 'Missing Host header.\n');
      }

      final normalizedHost = _normalizeHost(rawHost);

      if (normalizedHost == null) {
        return Response(400, body: 'Invalid Host header.\n');
      }

      if (!securityConfig.allowAnyHost &&
          !securityConfig.allowedHosts.any(
            (allowedHost) => _hostMatches(normalizedHost, allowedHost),
          )) {
        return Response(403, body: 'Host not allowed.\n');
      }

      // 2. Validate Content-Length when provided.
      final contentLength = request.headers['content-length'];

      if (contentLength != null) {
        final declaredLength = int.tryParse(contentLength.trim());

        if (declaredLength == null || declaredLength < 0) {
          return Response(400, body: 'Invalid Content-Length.\n');
        }

        if (declaredLength > serverConfig.maxRequestBodyBytes) {
          return Response(413, body: 'Request body too large.\n');
        }
      }

      // 3. Enforce the limit while reading the actual request stream.
      // This also covers chunked requests without Content-Length.
      final bodyBuilder = BytesBuilder(copy: false);
      var totalBytes = 0;

      await for (final chunk in request.read()) {
        totalBytes += chunk.length;

        if (totalBytes > serverConfig.maxRequestBodyBytes) {
          return Response(413, body: 'Request body too large.\n');
        }

        bodyBuilder.add(chunk);
      }

      // 4. Pass the validated body to the next handler.
      final body = bodyBuilder.takeBytes();

      final guardedRequest = request.change(
        body: Stream<List<int>>.value(body),
      );

      return innerHandler(guardedRequest);
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

  // Port harus berada pada rentang 1-65535.
  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
    return null;
  }

  // Pastikan Host tidak mengandung karakter yang tidak valid.
  if (uri.authority != host) {
    return null;
  }

  return host;
}

bool _hostMatches(String requestHost, String allowedHost) {
  final allowed = allowedHost.toLowerCase();

  // An explicitly configured port must match exactly.
  if (_hasExplicitPort(allowed)) {
    return requestHost == allowed;
  }

  // Without a configured port, allow the hostname on any port.
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
