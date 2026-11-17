import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/network/auth_interceptor.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';

import '../../support/auth_test_doubles.dart';

class _RecordingErrorHandler extends ErrorInterceptorHandler {
  _RecordingErrorHandler({required this.onNext});
  final void Function() onNext;

  @override
  void next(DioException err) {
    onNext();
  }
}

void main() {
  group('AuthInterceptor', () {
    test(
      'menyisipkan Bearer token dan memperbarui token kedaluwarsa',
      () async {
        final storage = MemoryTokenStorage();
        await storage.save(
          AuthTokens(
            accessToken: 'expired-access',
            refreshToken: 'valid-refresh',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 5),
            ),
          ),
        );

        var refreshCalls = 0;
        final interceptor = AuthInterceptor(
          tokenStorage: storage,
          onRefreshTokens: (refreshToken) async {
            refreshCalls++;
            expect(refreshToken, 'valid-refresh');
            return AuthTokens(
              accessToken: 'fresh-access',
              refreshToken: 'fresh-refresh',
              expiresAt: DateTime.now().toUtc().add(
                const Duration(minutes: 30),
              ),
            );
          },
        );

        final options = RequestOptions(path: '/v1/orders');
        final handler = RequestInterceptorHandler();
        await interceptor.onRequest(options, handler);

        expect(refreshCalls, 1);
        expect(options.headers['Authorization'], 'Bearer fresh-access');
        expect((await storage.read())?.accessToken, 'fresh-access');
      },
    );

    test('menginvalidasi sesi ketika menerima 403 ACCOUNT_DISABLED', () async {
      final storage = MemoryTokenStorage();
      await storage.save(const AuthTokens(accessToken: 'active-token'));

      bool? invalidatedAsDisabled;
      final interceptor = AuthInterceptor(
        tokenStorage: storage,
        onSessionInvalidated: ({required accountDisabled}) async {
          invalidatedAsDisabled = accountDisabled;
        },
      );

      final requestOptions = RequestOptions(path: '/v1/orders');
      final dioErr = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: requestOptions,
          statusCode: 403,
          data: <String, Object?>{
            'error': <String, Object?>{'code': 'ACCOUNT_DISABLED'},
          },
        ),
      );

      var forwarded = false;
      final errHandler = _RecordingErrorHandler(onNext: () => forwarded = true);
      await interceptor.onError(dioErr, errHandler);

      expect(forwarded, isTrue);
      expect(invalidatedAsDisabled, isTrue);
      expect(await storage.read(), isNull);
    });

    test(
      'kegagalan refresh sementara (offline/timeout) mempertahankan token dan tidak me-logout pengguna',
      () async {
        final storage = MemoryTokenStorage();
        await storage.save(
          AuthTokens(
            accessToken: 'expired-access',
            refreshToken: 'valid-refresh',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 5),
            ),
          ),
        );

        var sessionInvalidated = false;
        final interceptor = AuthInterceptor(
          tokenStorage: storage,
          onRefreshTokens: (_) async {
            throw ApiException(type: ApiExceptionType.connection);
          },
          onSessionInvalidated: ({required accountDisabled}) async {
            sessionInvalidated = true;
          },
        );

        final options = RequestOptions(path: '/v1/catalog', method: 'GET');
        final handler = RequestInterceptorHandler();
        await interceptor.onRequest(options, handler);

        expect(sessionInvalidated, isFalse);
        expect((await storage.read())?.refreshToken, 'valid-refresh');
      },
    );

    test(
      '401 pada mutasi POST me-refresh token tetapi tidak mengulang request POST secara otomatis',
      () async {
        final storage = MemoryTokenStorage();
        await storage.save(
          const AuthTokens(
            accessToken: 'stale-access',
            refreshToken: 'valid-refresh',
          ),
        );

        var refreshCalls = 0;
        var sessionInvalidated = false;
        final interceptor = AuthInterceptor(
          tokenStorage: storage,
          onRefreshTokens: (_) async {
            refreshCalls++;
            return const AuthTokens(
              accessToken: 'new-access',
              refreshToken: 'new-refresh',
            );
          },
          onSessionInvalidated: ({required accountDisabled}) async {
            sessionInvalidated = true;
          },
        );

        final postOptions = RequestOptions(
          path: '/v1/orders',
          method: 'POST',
          headers: <String, Object?>{'Authorization': 'Bearer stale-access'},
        );
        final dioErr = DioException(
          requestOptions: postOptions,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: postOptions,
            statusCode: 401,
            data: <String, Object?>{
              'error': <String, Object?>{'code': 'UNAUTHORIZED'},
            },
          ),
        );

        var forwarded = false;
        final errHandler = _RecordingErrorHandler(
          onNext: () => forwarded = true,
        );
        await interceptor.onError(dioErr, errHandler);

        expect(refreshCalls, 1);
        expect(forwarded, isTrue);
        expect(sessionInvalidated, isFalse);
        expect((await storage.read())?.accessToken, 'new-access');
      },
    );
  });
}
