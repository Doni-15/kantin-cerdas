import 'dart:typed_data';
import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';

Middleware requestBodyGuard({required ServerConfig serverConfig}) {
  return (Handler innerHandler) {
    var activeBodyRequests = 0;

    return (Request request) async {
      final contentLengthHeader = request.headers['content-length'];
      final transferEncoding = request.headers['transfer-encoding'];

      final declaredLength = contentLengthHeader == null
          ? null
          : int.tryParse(contentLengthHeader.trim());

      if (contentLengthHeader != null &&
          (declaredLength == null || declaredLength < 0)) {
        return ApiResponse.error(
          statusCode: 400,
          code: 'INVALID_CONTENT_LENGTH',
          message: 'Header Content-Length tidak valid.',
        );
      }

      if (declaredLength != null &&
          declaredLength > serverConfig.maxRequestBodyBytes) {
        return ApiResponse.error(
          statusCode: 413,
          code: 'REQUEST_BODY_TOO_LARGE',
          message: 'Ukuran request body melebihi batas yang diizinkan.',
        );
      }

      // Content-Length and Transfer-Encoding must not be combined.
      if (contentLengthHeader != null && transferEncoding != null) {
        return ApiResponse.error(
          statusCode: 400,
          code: 'CONFLICTING_REQUEST_HEADERS',
          message:
              'Content-Length dan Transfer-Encoding tidak boleh digunakan bersamaan.',
        );
      }

      var acquiredSlot = false;

      try {
        final bodyBuilder = BytesBuilder(copy: false);
        var totalBytes = 0;
        var bodyTooLarge = false;
        var serverBusy = false;

        // Inspect and consume the complete stream, even after a rejection.
        // This prevents the connection from closing while the client is
        // still sending the remaining request body.
        await for (final chunk in request.read()) {
          if (chunk.isEmpty) continue;

          // Acquire a concurrency slot only when body data is received.
          if (!acquiredSlot && !serverBusy) {
            if (activeBodyRequests >= serverConfig.maxConcurrentBodyRequests) {
              serverBusy = true;
              continue;
            }

            activeBodyRequests++;
            acquiredSlot = true;
          }

          // Discard remaining chunks after the request has been rejected.
          if (serverBusy || bodyTooLarge) continue;

          totalBytes += chunk.length;

          if (totalBytes > serverConfig.maxRequestBodyBytes) {
            bodyTooLarge = true;
            continue;
          }

          bodyBuilder.add(chunk);
        }

        if (serverBusy) {
          return ApiResponse.error(
            statusCode: 503,
            code: 'SERVER_BUSY',
            message: 'Server sedang sibuk memproses request body.',
            headers: {'retry-after': '1'},
          );
        }

        if (bodyTooLarge) {
          return ApiResponse.error(
            statusCode: 413,
            code: 'REQUEST_BODY_TOO_LARGE',
            message: 'Ukuran request body melebihi batas yang diizinkan.',
          );
        }

        final body = bodyBuilder.takeBytes();

        final guardedRequest = request.change(
          body: Stream<List<int>>.value(body),
        );

        // Keep the slot until downstream processing has completed.
        return await innerHandler(guardedRequest);
      } finally {
        if (acquiredSlot) {
          activeBodyRequests--;
        }
      }
    };
  };
}
