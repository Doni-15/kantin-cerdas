import 'dart:convert';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:test/test.dart';

void main() {
  group('ApiException', () {
    test('stores status code, error code, and message', () {
      final exception = ApiException(
        statusCode: 422,
        code: 'VALIDATION_ERROR',
        message: 'Data tidak valid.',
      );

      expect(exception.statusCode, 422);
      expect(exception.code, 'VALIDATION_ERROR');
      expect(exception.message, 'Data tidak valid.');
      expect(exception.toString(), contains('VALIDATION_ERROR'));
    });

    test('rejects status codes outside the 400-599 range', () {
      expect(
        () => ApiException(
          statusCode: 399,
          code: 'INVALID_STATUS',
          message: 'Invalid status.',
        ),
        throwsArgumentError,
      );

      expect(
        () => ApiException(
          statusCode: 600,
          code: 'INVALID_STATUS',
          message: 'Invalid status.',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ApiResponse', () {
    test('creates a successful JSON response', () async {
      final response = ApiResponse.success(data: {'id': 1});

      expect(response.statusCode, 200);
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['success'], true);
      expect(body['data']['id'], 1);
      expect(body.containsKey('error'), false);
    });

    test('supports a custom success status code', () async {
      final response = ApiResponse.success(data: {'id': 1}, statusCode: 201);

      expect(response.statusCode, 201);
    });

    test('rejects status codes outside the 200-299 range', () {
      expect(
        () => ApiResponse.success(data: {}, statusCode: 199),
        throwsArgumentError,
      );

      expect(
        () => ApiResponse.success(data: {}, statusCode: 300),
        throwsArgumentError,
      );
    });

    test('includes metadata when provided', () async {
      final response = ApiResponse.success(
        data: [],
        meta: {'page': 1, 'total': 0},
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['meta']['page'], 1);
      expect(body['meta']['total'], 0);
    });

    test('omits metadata when not provided', () async {
      final response = ApiResponse.success(data: []);

      final body = jsonDecode(await response.readAsString());

      expect(body.containsKey('meta'), false);
    });

    test('creates a standard JSON error response', () async {
      final response = ApiResponse.error(
        statusCode: 422,
        code: 'VALIDATION_ERROR',
        message: 'Data yang dikirim tidak valid.',
      );

      expect(response.statusCode, 422);
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['success'], false);
      expect(body['error']['code'], 'VALIDATION_ERROR');
      expect(body['error']['message'], 'Data yang dikirim tidak valid.');
      expect(body.containsKey('data'), false);
    });

    test('preserves custom response headers', () {
      final response = ApiResponse.error(
        statusCode: 429,
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Terlalu banyak request.',
        headers: {'retry-after': '10'},
      );

      expect(response.headers['retry-after'], '10');
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
    });

    test('rejects status codes outside the 400-599 range', () {
      expect(
        () => ApiResponse.error(
          statusCode: 399,
          code: 'INVALID_STATUS',
          message: 'Invalid status.',
        ),
        throwsArgumentError,
      );

      expect(
        () => ApiResponse.error(
          statusCode: 600,
          code: 'INVALID_STATUS',
          message: 'Invalid status.',
        ),
        throwsArgumentError,
      );
    });
  });
}
