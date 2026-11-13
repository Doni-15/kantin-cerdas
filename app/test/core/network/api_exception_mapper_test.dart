import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';

void main() {
  group('mapDioException', () {
    test('memetakan timeout, connection, dan nested error payload', () {
      final requestOptions = RequestOptions(path: '/v1/auth/login');

      final timeoutEx = mapDioException(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(timeoutEx.type, ApiExceptionType.timeout);

      final responseEx = mapDioException(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: requestOptions,
            statusCode: 409,
            data: <String, Object?>{
              'error': <String, Object?>{
                'code': 'USERNAME_TAKEN',
                'field_errors': <String, Object?>{
                  'username': 'invalidUsername',
                },
              },
            },
          ),
        ),
      );
      expect(responseEx.type, ApiExceptionType.response);
      expect(responseEx.statusCode, 409);
      expect(responseEx.code, 'USERNAME_TAKEN');
      expect(responseEx.fieldErrors['username'], 'invalidUsername');
    });
  });
}
