import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:shelf/shelf.dart';

bool isAuthBrowserRequest(Request request) =>
    request.headers.containsKey('origin') ||
    request.headers.containsKey('sec-fetch-site') ||
    request.headers.containsKey('sec-fetch-mode');

void requireAuthWebOrigin(Request request, String? origin) {
  if (origin == null) {
    throw ApiException(
      statusCode: 503,
      code: 'WEB_AUTH_DISABLED',
      message: 'Sesi web belum dikonfigurasi.',
    );
  }
  final site = request.headers['sec-fetch-site'];
  if (request.headers['origin'] != origin ||
      (site != null && site != 'same-origin')) {
    throw ApiException(
      statusCode: 403,
      code: 'WEB_ORIGIN_DENIED',
      message: 'Origin aplikasi web tidak diizinkan.',
    );
  }
}
