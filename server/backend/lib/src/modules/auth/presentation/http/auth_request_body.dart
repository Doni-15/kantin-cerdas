import 'dart:convert';
import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:shelf/shelf.dart';

Future<Map<String, Object?>> readAuthJsonBody(Request request) async {
  final contentType = request.headers['content-type']?.split(';').first.trim();
  if (contentType?.toLowerCase() != 'application/json') {
    throw ApiException(
      statusCode: 415,
      code: 'UNSUPPORTED_MEDIA_TYPE',
      message: 'Gunakan Content-Type application/json.',
    );
  }
  final bytes = await readAuthBytes(request, limit: 32 * 1024);
  try {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is Map<String, Object?>) return value;
  } on FormatException {
    throw invalidAuthInput('Format JSON tidak valid.');
  }
  throw invalidAuthInput('Data autentikasi harus berupa objek JSON.');
}

Future<Uint8List> readAuthBytes(Request request, {required int limit}) async {
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in request.read()) {
    if (bytes.length + chunk.length > limit) {
      throw ApiException(
        statusCode: 413,
        code: 'REQUEST_BODY_TOO_LARGE',
        message: 'Ukuran data melebihi batas.',
      );
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
