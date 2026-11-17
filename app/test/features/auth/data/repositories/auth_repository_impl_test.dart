import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/update_profile_avatar_usecase.dart';

import '../../../../support/auth_test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleUserModel = UserModel(
    id: 'usr-1',
    username: 'doni_student',
    email: 'doni@kantincerdas.ac.id',
    name: 'Doni Mahasiswa',
    role: 'customer',
    isActive: true,
  );

  group('AuthRepositoryImpl (LOW-03)', () {
    test(
      'login menyimpan pasangan token ke TokenStorage dan mengembalikan User',
      () async {
        final tokenStorage = MemoryTokenStorage();
        final expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onLogin: (identifier, password) async => LoginResponseModel(
              user: sampleUserModel,
              accessToken: 'acc-123',
              refreshToken: 'ref-456',
              expiresAt: expiry,
            ),
          ),
        );

        final user = await repo.login(
          identifier: 'doni_student',
          password: 'Password123',
        );
        expect(user.id, 'usr-1');
        expect(user.role, UserRole.customer);
        expect(tokenStorage.stored?.accessToken, 'acc-123');
        expect(tokenStorage.stored?.refreshToken, 'ref-456');
      },
    );

    test(
      'restoreSession memperbarui token kedaluwarsa via refreshSession dan mengembalikan User',
      () async {
        final tokenStorage = MemoryTokenStorage(
          AuthTokens(
            accessToken: 'expired-acc',
            refreshToken: 'valid-ref',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 10),
            ),
          ),
        );
        final freshExpiry = DateTime.now().toUtc().add(
          const Duration(minutes: 45),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onRefreshSession: (refreshToken) async {
              expect(refreshToken, 'valid-ref');
              return LoginResponseModel(
                user: sampleUserModel,
                accessToken: 'new-acc-999',
                refreshToken: 'new-ref-999',
                expiresAt: freshExpiry,
              );
            },
          ),
        );

        final restored = await repo.restoreSession();
        expect(restored?.id, 'usr-1');
        expect(tokenStorage.stored?.accessToken, 'new-acc-999');
        expect(tokenStorage.stored?.refreshToken, 'new-ref-999');
      },
    );

    test(
      'restoreSession membersihkan TokenStorage dan mengembalikan null ketika refresh gagal 401',
      () async {
        final tokenStorage = MemoryTokenStorage(
          AuthTokens(
            accessToken: 'expired-acc',
            refreshToken: 'revoked-ref',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 5),
            ),
          ),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onRefreshSession: (_) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 401,
              code: 'TOKEN_EXPIRED',
            ),
          ),
        );

        final restored = await repo.restoreSession();
        expect(restored, isNull);
        expect(tokenStorage.stored, isNull);
        expect(tokenStorage.clearCount, greaterThanOrEqualTo(1));
      },
    );

    test(
      'logout selalu menghapus sesi lokal meskipun pencabutan token jarak jauh gagal',
      () async {
        final tokenStorage = MemoryTokenStorage(
          const AuthTokens(accessToken: 'acc-active', refreshToken: 'ref-1'),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onLogout: (accessToken, refreshToken) async {
              throw ApiException(type: ApiExceptionType.connection);
            },
          ),
        );

        await repo.logout();
        expect(tokenStorage.stored, isNull);
        expect(tokenStorage.clearCount, 1);
      },
    );

    test(
      'single-flight refresh mencegah duplikasi POST /v1/auth/refresh dan changePassword/updateProfileAvatar me-refresh saat menerima 401 TOKEN_EXPIRED',
      () async {
        final tokenStorage = MemoryTokenStorage(
          const AuthTokens(
            accessToken: 'stale-acc',
            refreshToken: 'ref-shared',
          ),
        );
        var refreshCalls = 0;
        var changePasswordCalls = 0;
        final refreshCompleter = Completer<LoginResponseModel>();
        final freshExpiry = DateTime.now().toUtc().add(
          const Duration(minutes: 45),
        );

        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onRefreshSession: (refreshToken) {
              refreshCalls++;
              expect(refreshToken, 'ref-shared');
              return refreshCompleter.future;
            },
            onChangePassword: (accessToken, _, _) async {
              changePasswordCalls++;
              if (accessToken == 'stale-acc') {
                throw ApiException(
                  type: ApiExceptionType.response,
                  statusCode: 401,
                  code: 'TOKEN_EXPIRED',
                );
              }
              expect(accessToken, 'fresh-acc');
            },
            onUpdateProfileAvatar: (accessToken, avatarUrl) async {
              expect(accessToken, 'fresh-acc');
              return UserModel(
                id: sampleUserModel.id,
                username: sampleUserModel.username,
                email: sampleUserModel.email,
                name: sampleUserModel.name,
                role: sampleUserModel.role,
                isActive: sampleUserModel.isActive,
                avatarUrl: avatarUrl,
              );
            },
          ),
        );

        final futureRefresh = repo.refreshTokens('ref-shared');
        final futureChangePassword = repo.changePassword(
          currentPassword: 'Password123',
          newPassword: 'PasswordBaru123',
        );

        refreshCompleter.complete(
          LoginResponseModel(
            user: sampleUserModel,
            accessToken: 'fresh-acc',
            refreshToken: 'fresh-ref',
            expiresAt: freshExpiry,
          ),
        );

        final refreshedTokens = await futureRefresh;
        await futureChangePassword;

        expect(refreshCalls, 1);
        expect(changePasswordCalls, 2);
        expect(refreshedTokens?.accessToken, 'fresh-acc');
        expect(tokenStorage.stored?.accessToken, 'fresh-acc');

        final useCase = UpdateProfileAvatarUseCase(repo);
        final updatedUser = await useCase.execute(
          avatarUrl:
              'https://cdn.kantincerdas.ac.id/usr-1_profile_avatar_12345678.webp',
        );
        expect(
          updatedUser.avatarUrl,
          'https://cdn.kantincerdas.ac.id/usr-1_profile_avatar_12345678.webp',
        );
      },
    );
  });
}
