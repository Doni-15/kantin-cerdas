import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/user_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.dataSource,
    required this.tokenStorage,
  });

  final AuthDataSource dataSource;
  final TokenStorage tokenStorage;

  @override
  Future<User> login({required String identifier, required String password}) {
    return _guard<User>(() async {
      final response = await dataSource.login(
        identifier: identifier,
        password: password,
      );

      // Map dulu: jika data tidak valid, token tidak ikut tersimpan.
      final user = response.user.toEntity();

      await tokenStorage.save(
        AuthTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          expiresAt: DateTime.now().add(Duration(seconds: response.expiresIn)),
        ),
      );

      return user;
    });
  }

  @override
  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) {
    return _guard<User>(() async {
      final model = await dataSource.register(
        name: name,
        username: username,
        email: email,
        password: password,
      );

      return model.toEntity();
    });
  }

  @override
  Future<User?> restoreSession() {
    return _guard<User?>(() async {
      final tokens = await tokenStorage.read();

      if (tokens == null) {
        return null;
      }

      try {
        final model = await dataSource.getCurrentUser(
          accessToken: tokens.accessToken,
        );

        return model.toEntity();
      } on ApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          // Token ditolak. TODO: coba refresh token sebelum menyerah.
          await tokenStorage.clear();
          return null;
        }

        rethrow;
      }
    });
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard<void>(() async {
      final tokens = await tokenStorage.read();

      // Tanpa token = tidak ada sesi login; dipetakan menjadi SessionExpiredFailure.
      if (tokens == null) {
        throw const ApiException(
          statusCode: 401,
          code: ApiErrorCode.tokenInvalid,
        );
      }

      await dataSource.changePassword(
        accessToken: tokens.accessToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }

  @override
  Future<void> logout() async {
    final tokens = await tokenStorage.read();

    try {
      if (tokens != null) {
        await dataSource.logout(refreshToken: tokens.refreshToken);
      }
    } on ApiException {
      // Server gagal dihubungi: logout lokal tetap dijalankan.
    } finally {
      await tokenStorage.clear();
    }
  }

  /// Satu-satunya tempat error Data Layer dipetakan menjadi AuthFailure.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw _mapApiException(error);
    } on DataParsingException {
      throw const UnknownFailure();
    } on FormatException {
      throw const UnknownFailure();
    } on TypeError {
      throw const UnknownFailure();
    }
  }

  AuthFailure _mapApiException(ApiException error) {
    switch (error.code) {
      case ApiErrorCode.invalidCredentials:
        return const InvalidCredentialsFailure();
      case ApiErrorCode.wrongPassword:
        return const InvalidCurrentPasswordFailure();
      case ApiErrorCode.tokenInvalid:
      case ApiErrorCode.tokenExpired:
        return const SessionExpiredFailure();
      case ApiErrorCode.accountDisabled:
        return const AccountDisabledFailure();
      case ApiErrorCode.usernameTaken:
        return const UsernameTakenFailure();
      case ApiErrorCode.emailTaken:
        return const EmailTakenFailure();
      case ApiErrorCode.validationError:
        return ValidationFailure(error.fieldErrors);
      case ApiErrorCode.network:
      case ApiErrorCode.timeout:
        return const NetworkFailure();
    }

    // Code belum dikenal: putuskan berdasarkan status code.
    return switch (error.statusCode) {
      0 => const NetworkFailure(),
      401 => const InvalidCredentialsFailure(),
      403 => const AccountDisabledFailure(),
      _ => const UnknownFailure(),
    };
  }
}
