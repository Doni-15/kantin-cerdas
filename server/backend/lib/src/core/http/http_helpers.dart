import 'dart:convert';
import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:shelf/shelf.dart';

const Map<String, String> noStoreHeaders = {'cache-control': 'no-store'};

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);
final _strictControlCharsPattern = RegExp(r'[\x00-\x1f\x7f]');
final _multilineUnsafeControlCharsPattern = RegExp(
  r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]',
);

Response notFoundNoStoreResponse(Request _) => ApiResponse.error(
  statusCode: 404,
  code: 'ROUTE_NOT_FOUND',
  message: 'Route not found',
  headers: noStoreHeaders,
);

Response jpegDownloadResponse(List<int>? jpeg) {
  if (jpeg == null) return Response(204, headers: noStoreHeaders);
  return Response.ok(
    jpeg,
    headers: {
      ...noStoreHeaders,
      'content-type': 'image/jpeg',
      'content-length': '${jpeg.length}',
    },
  );
}

bool isValidUuid(String value) => _uuidPattern.hasMatch(value);

String? tryNormalizeUuid(String raw) {
  final value = raw.trim().toLowerCase();
  return _uuidPattern.hasMatch(value) ? value : null;
}

bool hasStrictControlChars(String value) =>
    _strictControlCharsPattern.hasMatch(value);

bool hasMultilineUnsafeControlChars(String value) =>
    _multilineUnsafeControlCharsPattern.hasMatch(value);

String? normalizedMediaType(Request request) =>
    request.headers['content-type']?.split(';').first.trim().toLowerCase();

Future<Uint8List> readRequestBytesLimited(
  Request request, {
  required int limit,
  required Object Function() onTooLarge,
}) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in request.read()) {
    if (builder.length + chunk.length > limit) {
      throw onTooLarge();
    }
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Future<Map<String, Object?>> readJsonObjectBody(
  Request request, {
  int limit = 64 * 1024,
  required Object Function() onUnsupportedMediaType,
  required Object Function() onTooLarge,
  required Object Function() onInvalidJson,
}) async {
  if (normalizedMediaType(request) != 'application/json') {
    throw onUnsupportedMediaType();
  }
  final bytes = await readRequestBytesLimited(
    request,
    limit: limit,
    onTooLarge: onTooLarge,
  );
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map<String, Object?>) return decoded;
    if (decoded is Map) return Map<String, Object?>.from(decoded);
  } on FormatException {
    throw onInvalidJson();
  }
  throw onInvalidJson();
}
