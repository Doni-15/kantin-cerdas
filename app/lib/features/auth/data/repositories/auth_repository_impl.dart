import 'dart:async';

import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/auth_failure_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/user_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._dataSource, required this._tokenStorage});

  final AuthDataSource _dataSource;
  final TokenStorage _tokenStorage;
  static const _requestLimit = Duration(seconds: 30);
  int _sessionRevision = 0;
  Future<void> _storageQueue = Future<void>.value();

  @override
  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final revision = ++_sessionRevision;
    return _api<User>(AuthApiOperation.login, () async {
      final response = await _dataSource
          .login(identifier: identifier, password: password)
          .timeout(_requestLimit);
      _requireCurrent(revision);
      final user = response.user.toEntity();
      _requireActive(user);
      final tokens = _tokensFromResponse(response);
      if (tokens.isExpiredAt(DateTime.now())) {
        throw const AuthSessionExpiredFailure();
      }
      await _guardedStorage(revision, () => _tokenStorage.save(tokens));
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
    return _api<User>(AuthApiOperation.register, () async {
      final model = await _dataSource
          .register(
            name: name,
            username: username,
            email: email,
            password: password,
          )
          .timeout(_requestLimit);
      return model.toEntity();
    });
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _dataSource
          .requestPasswordReset(email: email)
          .timeout(_requestLimit);
    } on AuthNotConfiguredFailure {
      rethrow;
    } on AuthRateLimitedFailure {
      rethrow;
    } on ApiException catch (error) {
      if (error.type == ApiExceptionType.response && error.statusCode == 429) {
        throw const AuthRateLimitedFailure();
      }
      throw const AuthPasswordResetUnconfirmedFailure();
    } catch (_) {
      throw const AuthPasswordResetUnconfirmedFailure();
    }
  }

  @override
  Future<User?> restoreSession() async {
    final revision = ++_sessionRevision;
    var tokens = await _guardedStorage(revision, _tokenStorage.read);
    if (tokens == null) return null;
    if (tokens.isExpiredAt(DateTime.now())) {
      final refreshed = await _tryRefreshTokens(revision, tokens);
      if (refreshed == null) {
        return null;
      }
      tokens = refreshed.$1;
      if (refreshed.$2 != null) {
        return refreshed.$2;
      }
    }
    final activeTokens = tokens;
    try {
      return await _api<User>(AuthApiOperation.restoreSession, () async {
        final model = await _dataSource
            .getCurrentUser(accessToken: activeTokens.accessToken)
            .timeout(_requestLimit);
        _requireCurrent(revision);
        if (activeTokens.isExpiredAt(DateTime.now())) {
          throw const AuthSessionExpiredFailure();
        }
        final user = model.toEntity();
        _requireActive(user);
        return user;
      });
    } on AuthSessionExpiredFailure {
      final refreshed = await _tryRefreshTokens(revision, activeTokens);
      if (refreshed != null && refreshed.$2 != null) {
        return refreshed.$2;
      }
      await _guardedStorage(revision, _tokenStorage.clear);
      return null;
    } on AuthAccountDisabledFailure {
      await _guardedStorage(revision, _tokenStorage.clear);
      rethrow;
    }
  }

  /// Memperbarui pasangan token di bawah revisi dan antrean penyimpanan sesi.
  Future<AuthTokens?> refreshTokens(String refreshToken) async {
    final revision = _sessionRevision;
    final stored = await _guardedStorage(revision, _tokenStorage.read);
    if (stored == null) {
      throw const AuthSessionExpiredFailure();
    }
    if (stored.accessToken.trim().isNotEmpty &&
        !stored.isExpiredAt(DateTime.now()) &&
        stored.refreshToken != null &&
        stored.refreshToken != refreshToken) {
      return stored;
    }
    final refreshed = await _tryRefreshTokens(
      revision,
      AuthTokens(
        accessToken: stored.accessToken,
        refreshToken: refreshToken,
        expiresAt: stored.expiresAt,
      ),
    );
    return refreshed?.$1;
  }

  @override
  Future<void> logout() async {
    ++_sessionRevision;
    final tokens = await _enqueueStorage<AuthTokens?>(() async {
      AuthTokens? captured;
      try {
        captured = await _withStorage(_tokenStorage.read);
      } on AuthStorageFailure {
        // Pembacaan rusak tidak boleh mencegah percobaan menghapus sesi.
      }
      await _withStorage(_tokenStorage.clear);
      return captured;
    });
    if (tokens != null) {
      unawaited(_revokeCapturedSession(tokens));
    }
  }

  Future<void> _revokeCapturedSession(AuthTokens tokens) async {
    try {
      await _dataSource
          .logout(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Lokal sudah bersih.
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final revision = _sessionRevision;
    var tokens = await _guardedStorage(revision, _tokenStorage.read);
    if (tokens == null) throw const AuthSessionExpiredFailure();
    if (tokens.isExpiredAt(DateTime.now())) {
      final refreshed = await _tryRefreshTokens(revision, tokens);
      if (refreshed == null) {
        throw const AuthSessionExpiredFailure();
      }
      tokens = refreshed.$1;
    }
    final activeTokens = tokens;
    try {
      await _api<void>(AuthApiOperation.changePassword, () {
        return _dataSource
            .changePassword(
              accessToken: activeTokens.accessToken,
              currentPassword: currentPassword,
              newPassword: newPassword,
            )
            .timeout(_requestLimit);
      });
      _requireCurrent(revision);
    } on AuthFailure catch (failure) {
      if (failure is AuthSessionExpiredFailure ||
          failure is AuthAccountDisabledFailure) {
        await _guardedStorage(revision, _tokenStorage.clear);
      }
      rethrow;
    }
  }

  @override
  Future<User> updateProfileAvatar({required String? avatarUrl}) async {
    final String? safeUrl;
    try {
      safeUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        avatarUrl,
        fieldName: 'avatar_url',
      );
    } on FormatException {
      throw AuthValidationFailure(const {'avatar_url': 'invalid'});
    }

    final revision = _sessionRevision;
    var tokens = await _guardedStorage(revision, _tokenStorage.read);
    if (tokens == null) throw const AuthSessionExpiredFailure();
    if (tokens.isExpiredAt(DateTime.now())) {
      final refreshed = await _tryRefreshTokens(revision, tokens);
      if (refreshed == null) {
        throw const AuthSessionExpiredFailure();
      }
      tokens = refreshed.$1;
    }
    final activeTokens = tokens;
    try {
      final user = await _api<User>(
        AuthApiOperation.updateProfileAvatar,
        () async {
          final model = await _dataSource
              .updateProfileAvatar(
                accessToken: activeTokens.accessToken,
                avatarUrl: safeUrl,
              )
              .timeout(_requestLimit);
          _requireCurrent(revision);
          final mapped = model.toEntity();
          _requireActive(mapped);
          if (mapped.avatarUrl != safeUrl) {
            throw const AuthUnexpectedFailure();
          }
          return mapped;
        },
      );
      _requireCurrent(revision);
      return user;
    } on AuthFailure catch (failure) {
      if (failure is AuthSessionExpiredFailure ||
          failure is AuthAccountDisabledFailure) {
        await _guardedStorage(revision, _tokenStorage.clear);
      }
      rethrow;
    }
  }

  Future<(AuthTokens, User?)?> _tryRefreshTokens(
    int revision,
    AuthTokens currentTokens,
  ) async {
    final refreshToken = currentTokens.refreshToken;
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      await _guardedStorage(revision, _tokenStorage.clear);
      return null;
    }
    try {
      return await _api<(AuthTokens, User?)>(
        AuthApiOperation.refreshSession,
        () async {
          final response = await _dataSource
              .refreshSession(refreshToken: refreshToken)
              .timeout(_requestLimit);
          _requireCurrent(revision);
          final user = response.user.toEntity();
          _requireActive(user);
          final newTokens = _tokensFromResponse(
            LoginResponseModel(
              user: response.user,
              accessToken: response.accessToken,
              refreshToken: response.refreshToken ?? refreshToken,
              expiresAt: response.expiresAt,
            ),
          );
          if (newTokens.isExpiredAt(DateTime.now())) {
            throw const AuthSessionExpiredFailure();
          }
          await _guardedStorage(revision, () => _tokenStorage.save(newTokens));
          return (newTokens, user);
        },
      );
    } on AuthAccountDisabledFailure {
      await _guardedStorage(revision, _tokenStorage.clear);
      rethrow;
    } on AuthSessionExpiredFailure {
      await _guardedStorage(revision, _tokenStorage.clear);
      return null;
    } on AuthNotConfiguredFailure {
      await _guardedStorage(revision, _tokenStorage.clear);
      return null;
    }
  }

  void _requireCurrent(int revision) {
    if (revision != _sessionRevision) {
      throw const AuthOperationSupersededFailure();
    }
  }

  void _requireActive(User user) {
    if (!user.isActive) throw const AuthAccountDisabledFailure();
  }

  AuthTokens _tokensFromResponse(LoginResponseModel response) {
    final accessToken = response.accessToken;
    final refreshToken = response.refreshToken;
    if (accessToken.trim().isEmpty ||
        (refreshToken != null && refreshToken.trim().isEmpty)) {
      throw const DataParsingException('Login response contains empty tokens.');
    }
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: response.expiresAt?.toUtc(),
    );
  }

  Future<T> _api<T>(
    AuthApiOperation operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthNetworkFailure();
    } on ApiException catch (error) {
      throw mapAuthApiException(error, operation: operation);
    } catch (_) {
      throw const AuthUnexpectedFailure();
    }
  }

  Future<T> _withStorage<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      throw const AuthStorageFailure();
    }
  }

  Future<T> _guardedStorage<T>(int revision, Future<T> Function() action) {
    return _enqueueStorage<T>(() async {
      _requireCurrent(revision);
      final result = await _withStorage(action);
      _requireCurrent(revision);
      return result;
    });
  }

  Future<T> _enqueueStorage<T>(Future<T> Function() operation) {
    final result = _storageQueue.then<T>((_) => operation());
    _storageQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }
}
