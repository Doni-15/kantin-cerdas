import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';

/// Membatasi waktu tunggu handler sebelum memberikan respons HTTP 408.
Middleware requestTimeoutMiddleware(Duration timeout) {
  if (timeout <= Duration.zero) {
    throw ArgumentError.value(
      timeout,
      'timeout',
      'Timeout harus lebih besar dari nol.',
    );
  }

  return (Handler innerHandler) {
    return (Request request) {
      return Future<Response>.sync(() => innerHandler(request)).timeout(
        timeout,
        onTimeout: () {
          return ApiResponse.error(
            statusCode: 408,
            code: 'REQUEST_TIMEOUT',
            message: 'Waktu pemrosesan request telah habis.',
          );
        },
      );
    };
  };
}
