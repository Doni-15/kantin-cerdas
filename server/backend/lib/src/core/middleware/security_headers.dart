import 'package:shelf/shelf.dart';
import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';

Middleware securityHeaders(SecurityConfig config) {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);

      if (!config.enableSecurityHeaders) {
        return response;
      }

      return response.change(
        headers: {
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'SAMEORIGIN',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
          'Content-Security-Policy': "frame-ancestors 'self'",
        },
      );
    };
  };
}
