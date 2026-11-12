import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/auth_interceptor.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';
import 'package:kantin_cerdas/features/owner/data/storage/secure_owner_mutation_journal.dart';

class _InMemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}

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

  group('AuthInterceptor', () {
    test(
      'menyisipkan Bearer token dan memperbarui token kedaluwarsa',
      () async {
        final storage = _InMemoryTokenStorage();
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
      final storage = _InMemoryTokenStorage();
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
        final storage = _InMemoryTokenStorage();
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
        final storage = _InMemoryTokenStorage();
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

  group('SecureMutationJournalBase (PROD-NEW-04)', () {
    test(
      'menangani ArgumentError dari invarian domain pada entri jurnal rusak dan menghapusnya dengan aman',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        // Menyimpan entri jurnal owner dengan mutationId kosong yang memicu ArgumentError di PendingOwnerMutation
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          'kantin_cerdas.owner.mutation.v1.owner-1':
              '{"ownerId":"owner-1","mutationId":"   ","stallId":"stall-1","kind":"saveStall","targetId":"stall-1","expectedVersion":1}',
        });
        final journal = SecureOwnerMutationJournal(
          const FlutterSecureStorage(),
        );

        final pending = await journal.read('owner-1');
        expect(pending, isNull);
      },
    );
  });
}

class _RecordingErrorHandler extends ErrorInterceptorHandler {
  _RecordingErrorHandler({required this.onNext});
  final void Function() onNext;

  @override
  void next(DioException err) {
    onNext();
  }
}
