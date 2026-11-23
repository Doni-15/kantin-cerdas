import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_api_transport.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_json.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/data/session/session_store.dart';

/// An access token that expires within this window is treated as expired.
const _accessTokenExpiryLeeway = Duration(seconds: 30);

/// Owns the in-flight refresh and the storage and cookie queues for a repository.
class AuthSessionCoordinator {
  AuthSessionCoordinator({
    required this._api,
    required this._store,
    required this._cookieSessions,
    required this._cookieLock,
    required this._clock,
  });

  final AuthApiTransport _api;
  final SessionStore _store;
  final bool _cookieSessions;
  final SessionLock? _cookieLock;
  final DateTime Function() _clock;
  Future<AuthSession?>? _refreshInFlight;
  var _generation = 0;
  Future<void> _storageTail = Future.value();
  Future<void> _cookieTail = Future.value();

  Future<AuthSession?> restore({
    required Future<void> Function() clearSession,
  }) async {
    final tokens = await _store.read();
    if (tokens == null) return _cookieSessions ? _refresh(null) : null;

    try {
      if (tokens.expiresAt.isAfter(_clock().add(_accessTokenExpiryLeeway))) {
        try {
          final data = authJsonObject(
            await _api.request('GET', 'me', bearer: tokens.accessToken),
          );
          final account = AuthAccount.fromJson(data);
          if (tokens.ownerId != null && account.id != tokens.ownerId) {
            throw _badResponse;
          }
          return AuthSession(tokens, account);
        } on AuthException catch (error) {
          if (error.code != 'INVALID_SESSION') rethrow;
        }
      }
      return await _refresh(tokens, expectedAccountId: tokens.ownerId);
    } on AuthException catch (error) {
      if (error.code != 'INVALID_SESSION' &&
          error.code != 'EMAIL_NOT_VERIFIED') {
        rethrow;
      }
      if (_cookieSessions) {
        _generation++;
        await _writeStorage(_store.clear);
      } else {
        await clearSession();
      }
      return null;
    } on FormatException {
      throw _badResponse;
    }
  }

  Future<(SessionTokens, T)> authorize<T>(
    AuthSession session,
    Future<T> Function(String bearer) operation,
  ) async {
    final current = await _store.read();
    if (current == null) throw _invalidSession;
    final accountId = session.account.id;
    if (current.ownerId != null && current.ownerId != accountId) {
      throw _invalidSession;
    }
    if (current.ownerId == null &&
        current.accessToken != session.tokens.accessToken) {
      throw _invalidSession;
    }

    if (current.expiresAt.isAfter(_clock().add(_accessTokenExpiryLeeway))) {
      try {
        return (current, await operation(current.accessToken));
      } on AuthException catch (error) {
        if (error.code != 'INVALID_SESSION') rethrow;
      }
    }
    final rotated = await _refresh(current, expectedAccountId: accountId);
    if (rotated == null) throw _invalidSession;
    return (rotated.tokens, await operation(rotated.tokens.accessToken));
  }

  Future<void> clearSession() {
    _generation++;
    if (_cookieSessions) {
      return _cookieTransition(() async {
        final ownerId = (await _store.read())?.ownerId;
        await _api.request(
          'POST',
          'web/logout',
          body: {'account_id': ?ownerId},
        );
        await _writeStorage(_store.clear);
      });
    }
    return _writeStorage(_store.clear);
  }

  Future<void> logout(
    AuthSession? session, {
    required Future<void> Function() clearSession,
  }) async {
    if (_cookieSessions || session == null) return clearSession();
    try {
      await authorize(
        session,
        (bearer) => _api.request('POST', 'logout', bearer: bearer),
      );
    } on AuthException catch (error) {
      if (error.code != 'INVALID_SESSION' && error.code != 'ACCOUNT_INACTIVE') {
        rethrow;
      }
    }
    await clearSession();
  }

  Future<AuthSession?> _refresh(
    SessionTokens? previous, {
    String? expectedAccountId,
  }) async {
    final existing = _refreshInFlight;
    if (existing != null) {
      final session = await existing;
      if (session != null &&
          expectedAccountId != null &&
          session.account.id != expectedAccountId) {
        throw _badResponse;
      }
      return session;
    }
    final String? refreshToken = previous?.refreshToken;
    if (!_cookieSessions && refreshToken == null) throw _invalidSession;
    final operation = _exchange(
      'refresh',
      _cookieSessions ? const {} : {'refresh_token': refreshToken!},
      expectedAccountId: expectedAccountId,
      allowEmpty: _cookieSessions,
    );
    _refreshInFlight = operation;
    try {
      return await operation;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<AuthSession> start(
    String endpoint,
    Map<String, String> input, {
    String? expectedAccountId,
  }) async {
    final session = await _exchange(
      endpoint,
      input,
      expectedAccountId: expectedAccountId,
    );
    if (session == null) throw _badResponse;
    return session;
  }

  Future<AuthSession?> _exchange(
    String endpoint,
    Map<String, String> input, {
    String? expectedAccountId,
    bool allowEmpty = false,
  }) {
    final generation = _generation;
    Future<AuthSession?> exchange() async {
      try {
        if (generation != _generation) throw _invalidSession;
        final response = await _api.request(
          'POST',
          _cookieSessions ? 'web/$endpoint' : endpoint,
          body: input,
        );
        if (response == null && allowEmpty) {
          await _writeStorage(() async {
            if (generation != _generation) throw _invalidSession;
            await _store.clear();
          });
          return null;
        }
        final data = authJsonObject(response);
        final account = AuthAccount.fromJson(authJsonObject(data['account']));
        if (expectedAccountId != null && expectedAccountId != account.id) {
          throw _invalidSession;
        }
        final tokens = SessionTokens.fromJson(
          data,
          ownerId: account.id,
          cookieSession: _cookieSessions,
        );
        await _writeStorage(() async {
          if (generation != _generation) throw _invalidSession;
          await _store.write(tokens);
        });
        return AuthSession(tokens, account);
      } on FormatException {
        throw _badResponse;
      }
    }

    return _cookieSessions ? _cookieTransition(exchange) : exchange();
  }

  Future<T> _cookieTransition<T>(Future<T> Function() operation) {
    final lock = _cookieLock;
    if (lock != null) return lock(operation);
    final next = _cookieTail.then((_) => operation());
    _cookieTail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _writeStorage(Future<void> Function() operation) {
    final next = _storageTail.then((_) => operation());
    _storageTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }
}

const _invalidSession = authInvalidSessionException;
const _badResponse = authBadResponseException;
