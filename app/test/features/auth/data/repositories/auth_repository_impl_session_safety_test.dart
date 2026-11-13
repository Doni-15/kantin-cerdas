import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';

import '../../../../support/auth_test_doubles.dart';

const _activeUser = UserModel(
  id: 'usr-1',
  username: 'doni_student',
  email: 'doni@kantincerdas.ac.id',
  name: 'Doni Mahasiswa',
  role: 'customer',
  isActive: true,
);

const _disabledUser = UserModel(
  id: 'usr-2',
  username: 'akun_nonaktif',
  email: 'nonaktif@kantincerdas.ac.id',
  name: 'Akun Nonaktif',
  role: 'customer',
  isActive: false,
);

DateTime _inOneHour() => DateTime.now().toUtc().add(const Duration(hours: 1));

void main() {
  group('AuthRepositoryImpl — keamanan sesi', () {
    test('login akun nonaktif ditolak dan token tidak disimpan', () async {
      final storage = MemoryTokenStorage();
      final repo = AuthRepositoryImpl(
        tokenStorage: storage,
        dataSource: StubAuthDataSource(
          onLogin: (_, _) async => LoginResponseModel(
            user: _disabledUser,
            accessToken: 'acc',
            refreshToken: 'ref',
            expiresAt: _inOneHour(),
          ),
        ),
      );

      await expectLater(
        repo.login(identifier: 'akun_nonaktif', password: 'Password123'),
        throwsA(isA<AuthAccountDisabledFailure>()),
      );
      expect(storage.stored, isNull);
    });

    test(
      'logout saat login masih berjalan membatalkan login dan token tidak tersimpan',
      () async {
        final storage = MemoryTokenStorage();
        final pendingLogin = Completer<LoginResponseModel>();
        final repo = AuthRepositoryImpl(
          tokenStorage: storage,
          dataSource: StubAuthDataSource(
            onLogin: (_, _) => pendingLogin.future,
          ),
        );

        final login = repo.login(
          identifier: 'doni_student',
          password: 'Password123',
        );
        // Pasang ekspektasi sebelum future selesai agar error tidak "unhandled".
        final loginExpectation = expectLater(
          login,
          throwsA(isA<AuthOperationSupersededFailure>()),
        );

        await repo.logout();

        pendingLogin.complete(
          LoginResponseModel(
            user: _activeUser,
            accessToken: 'acc-late',
            refreshToken: 'ref-late',
            expiresAt: _inOneHour(),
          ),
        );

        await loginExpectation;
        expect(storage.stored, isNull);
      },
    );

    test(
      'restoreSession: refresh gagal karena jaringan tidak menghapus token dan bukan "sesi habis"',
      () async {
        final storage = MemoryTokenStorage(
          AuthTokens(
            accessToken: 'expired-acc',
            refreshToken: 'valid-ref',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 10),
            ),
          ),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: storage,
          dataSource: StubAuthDataSource(
            onRefreshSession: (_) async =>
                throw ApiException(type: ApiExceptionType.connection),
          ),
        );

        await expectLater(
          repo.restoreSession(),
          throwsA(
            allOf(isA<AuthFailure>(), isNot(isA<AuthSessionExpiredFailure>())),
          ),
        );

        // User yang membuka app saat offline tidak boleh kehilangan sesinya.
        expect(storage.stored?.refreshToken, 'valid-ref');
        expect(storage.clearCount, 0);
      },
    );
  });

  group('AuthRepositoryImpl.isEmailAvailable', () {
    test(
      'meneruskan hasil server apa adanya (tersedia dan tidak tersedia)',
      () async {
        for (final serverAnswer in <bool>[true, false]) {
          final repo = AuthRepositoryImpl(
            tokenStorage: MemoryTokenStorage(),
            dataSource: StubAuthDataSource(
              onIsEmailAvailable: (_) async => serverAnswer,
            ),
          );

          expect(
            await repo.isEmailAvailable(email: 'owner@gmail.com'),
            serverAnswer,
          );
        }
      },
    );

    test(
      'kegagalan server muncul sebagai AuthFailure, tidak diam-diam menjadi "tersedia"',
      () async {
        final repo = AuthRepositoryImpl(
          tokenStorage: MemoryTokenStorage(),
          dataSource: StubAuthDataSource(
            onIsEmailAvailable: (_) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
              code: 'ENDPOINT_NOT_FOUND',
            ),
          ),
        );

        await expectLater(
          repo.isEmailAvailable(email: 'owner@gmail.com'),
          throwsA(isA<AuthFailure>()),
        );
      },
    );
  });
}
