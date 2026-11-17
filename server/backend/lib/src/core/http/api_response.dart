import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

class ApiResponse {
  ApiResponse._();

  static const Map<String, String> _jsonHeaders = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
  };

  static Response success({
    required Object? data,
    int statusCode = 200,
    Map<String, Object?>? meta,
    Map<String, String> headers = const {},
  }) {
    if (statusCode < 200 || statusCode > 299) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'Status code success harus berada antara 200 dan 299.',
      );
    }

    final body = <String, Object?>{'success': true, 'data': data};

    if (meta != null) {
      body['meta'] = meta;
    }

    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: {...headers, ..._jsonHeaders},
    );
  }

  static Response error({
    required int statusCode,
    required String code,
    required String message,
    Map<String, String> headers = const {},
  }) {
    if (statusCode < 400 || statusCode > 599) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'Status code error harus berada antara 400 dan 599.',
      );
    }

    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': {'code': code, 'message': message},
      }),
      headers: {...headers, ..._jsonHeaders},
    );
  }
}
