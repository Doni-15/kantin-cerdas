import 'dart:async';

import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/session/auth_failure.dart';
import 'package:kantin_cerdas/core/session/auth_tokens.dart';
import 'package:kantin_cerdas/core/session/token_storage.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';

typedef TokenRefreshCallback =
    Future<AuthTokens?> Function(String refreshToken);
typedef SessionInvalidatedCallback =
    Future<void> Function({required bool accountDisabled});
typedef RetryRequestCallback =
    Future<Response<Object?>> Function(RequestOptions requestOptions);

class _RefreshOutcome {
  const _RefreshOutcome({
    this.tokens,
    this.definitive = false,
    this.accountDisabled = false,
    this.superseded = false,
  });

  final AuthTokens? tokens;
  final bool definitive;
  final bool accountDisabled;
  final bool superseded;
}

/// Interceptor untuk menyisipkan Bearer token, mengantrekan token refresh,
/// serta menginvalidasi sesi global saat server mengembalikan 401 atau 403.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    this.onRefreshTokens,
    this.onSessionInvalidated,
    this.retryDispatcher,
    this.persistRefreshedTokens = true,
  });

  final TokenStorage tokenStorage;
  final TokenRefreshCallback? onRefreshTokens;
  final SessionInvalidatedCallback? onSessionInvalidated;
  final RetryRequestCallback? retryDispatcher;
  final bool persistRefreshedTokens;

  Future<_RefreshOutcome>? _activeRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true ||
        options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }

    try {
      var tokens = await tokenStorage.read();
      if (tokens != null && tokens.isExpiredAt(DateTime.now())) {
        final refreshToken = tokens.refreshToken;
        if (refreshToken != null &&
            refreshToken.trim().isNotEmpty &&
            onRefreshTokens != null) {
          final outcome = await _refreshLocked(refreshToken);
          if (outcome.tokens != null) {
            tokens = outcome.tokens;
          } else {
            if (outcome.definitive && !outcome.superseded) {
              await _invalidate(accountDisabled: outcome.accountDisabled);
            }
            tokens = null;
          }
        } else {
          await _invalidate(accountDisabled: false);
          tokens = null;
        }
      }

      if (tokens != null && tokens.accessToken.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    } catch (_) {
      // Biarkan request berlanjut tanpa token jika pembacaan storage gagal;
      // endpoint terproteksi akan menolak dengan 401 secara eksplisit.
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final skipAuth = err.requestOptions.extra['skipAuth'] == true;
    if (skipAuth) {
      handler.next(err);
      return;
    }

    final statusCode = err.response?.statusCode;
    final errorCode = _extractErrorCode(err.response?.data);

    if (statusCode == 403 && errorCode == 'ACCOUNT_DISABLED') {
      await _invalidate(accountDisabled: true);
      handler.next(err);
      return;
    }

    if (statusCode == 401) {
      if (errorCode == 'INVALID_CURRENT_PASSWORD' ||
          errorCode == 'INVALID_CREDENTIALS') {
        handler.next(err);
        return;
      }

      final alreadyRetried =
          err.requestOptions.extra['retriedAfterRefresh'] == true;
      final dispatcher = retryDispatcher;

      if (!alreadyRetried && onRefreshTokens != null) {
        AuthTokens? refreshedTokens;
        var shouldInvalidate = true;
        var accountDisabled = false;
        var superseded = false;

        try {
          final currentTokens = await tokenStorage.read();
          final sentToken = _extractBearerToken(
            err.requestOptions.headers['Authorization'],
          );
          if (currentTokens != null &&
              currentTokens.accessToken.trim().isNotEmpty &&
              !currentTokens.isExpiredAt(DateTime.now()) &&
              sentToken != null &&
              currentTokens.accessToken != sentToken) {
            refreshedTokens = currentTokens;
            shouldInvalidate = false;
          } else {
            final refreshToken = currentTokens?.refreshToken;
            if (refreshToken != null && refreshToken.trim().isNotEmpty) {
              final outcome = await _refreshLocked(refreshToken);
              refreshedTokens = outcome.tokens;
              shouldInvalidate = outcome.definitive;
              accountDisabled = outcome.accountDisabled;
              superseded = outcome.superseded;
            }
          }
        } catch (_) {
          shouldInvalidate = false;
        }

        if (refreshedTokens != null) {
          if (dispatcher != null && _isRetryableRequest(err.requestOptions)) {
            final retryOptions = err.requestOptions.copyWith(
              headers: <String, Object?>{
                ...err.requestOptions.headers,
                'Authorization': 'Bearer ${refreshedTokens.accessToken}',
              },
              extra: <String, Object?>{
                ...err.requestOptions.extra,
                'retriedAfterRefresh': true,
              },
            );
            try {
              final response = await dispatcher(retryOptions);
              handler.resolve(response);
              return;
            } on DioException catch (retryErr) {
              final retryStatus = retryErr.response?.statusCode;
              final retryCode = _extractErrorCode(retryErr.response?.data);
              if (retryStatus == 403 && retryCode == 'ACCOUNT_DISABLED') {
                await _invalidate(accountDisabled: true);
              } else if (retryStatus == 401 &&
                  retryCode != 'INVALID_CURRENT_PASSWORD' &&
                  retryCode != 'INVALID_CREDENTIALS') {
                await _invalidate(accountDisabled: false);
              }
              handler.next(retryErr);
              return;
            }
          }
          handler.next(err);
          return;
        }

        if (superseded || !shouldInvalidate) {
          handler.next(err);
          return;
        }

        await _invalidate(accountDisabled: accountDisabled);
        handler.next(err);
        return;
      }

      await _invalidate(accountDisabled: false);
    }

    handler.next(err);
  }

  Future<_RefreshOutcome> _refreshLocked(String refreshToken) {
    final existing = _activeRefresh;
    if (existing != null) {
      return existing;
    }

    final onRefresh = onRefreshTokens;
    if (onRefresh == null) {
      return Future<_RefreshOutcome>.value(
        const _RefreshOutcome(definitive: true),
      );
    }

    final future = () async {
      try {
        final refreshed = await onRefresh(refreshToken);
        if (refreshed != null) {
          if (persistRefreshedTokens) {
            await tokenStorage.save(refreshed);
          }
          return _RefreshOutcome(tokens: refreshed);
        }
        return const _RefreshOutcome(definitive: true);
      } on AuthOperationSupersededFailure {
        return const _RefreshOutcome(superseded: true);
      } on AuthAccountDisabledFailure {
        return const _RefreshOutcome(definitive: true, accountDisabled: true);
      } on AuthSessionExpiredFailure {
        return const _RefreshOutcome(definitive: true);
      } on AuthNetworkFailure {
        return const _RefreshOutcome(definitive: false);
      } on AuthServerFailure {
        return const _RefreshOutcome(definitive: false);
      } on AuthRateLimitedFailure {
        return const _RefreshOutcome(definitive: false);
      } on TimeoutException {
        return const _RefreshOutcome(definitive: false);
      } on ApiException catch (error) {
        return _classifyApiRefreshException(error);
      } on DioException catch (error) {
        return _classifyApiRefreshException(mapDioException(error));
      } catch (_) {
        return const _RefreshOutcome(definitive: false);
      } finally {
        _activeRefresh = null;
      }
    }();

    _activeRefresh = future;
    return future;
  }

  _RefreshOutcome _classifyApiRefreshException(ApiException error) {
    if (error.type == ApiExceptionType.timeout ||
        error.type == ApiExceptionType.connection ||
        error.type == ApiExceptionType.cancelled) {
      return const _RefreshOutcome(definitive: false);
    }
    if (error.type == ApiExceptionType.response) {
      final statusCode = error.statusCode;
      final code = error.code;
      if (statusCode == 403 && code == 'ACCOUNT_DISABLED') {
        return const _RefreshOutcome(definitive: true, accountDisabled: true);
      }
      if (statusCode == 401 ||
          code == 'UNAUTHENTICATED' ||
          code == 'TOKEN_EXPIRED' ||
          code == 'INVALID_TOKEN') {
        return const _RefreshOutcome(definitive: true);
      }
    }
    return const _RefreshOutcome(definitive: false);
  }

  bool _isRetryableRequest(RequestOptions options) {
    if (options.extra['retryableAfterRefresh'] == true) {
      return true;
    }
    if (options.extra['retryableAfterRefresh'] == false) {
      return false;
    }
    final method = options.method.trim().toUpperCase();
    return method == 'GET' || method == 'HEAD' || method == 'OPTIONS';
  }

  String? _extractBearerToken(Object? rawHeader) {
    if (rawHeader is! String) {
      return null;
    }
    final trimmed = rawHeader.trim();
    if (!trimmed.toLowerCase().startsWith('bearer ')) {
      return null;
    }
    final token = trimmed.substring(7).trim();
    return token.isEmpty ? null : token;
  }

  Future<void> _invalidate({required bool accountDisabled}) async {
    try {
      await tokenStorage.clear();
    } catch (_) {
      // Tetap lanjutkan notifikasi state meskipun clear gagal.
    }
    final callback = onSessionInvalidated;
    if (callback != null) {
      await callback(accountDisabled: accountDisabled);
    }
  }

  String? _extractErrorCode(Object? rawData) {
    final rootMap = tryAsJsonMap(rawData);
    if (rootMap == null) {
      return null;
    }
    final nested = tryAsJsonMap(rootMap['error']);
    final map = nested ?? rootMap;
    final Object? code = map['code'];
    return code is String && code.trim().isNotEmpty ? code.trim() : null;
  }
}
