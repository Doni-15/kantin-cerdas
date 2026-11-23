import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_api_transport.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_json.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/data/session/auth_session_coordinator.dart';
import 'package:kantin_cerdas/features/auth/data/session/session_store.dart';

export 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart'
    show AuthException;
export 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
export 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
export 'package:kantin_cerdas/features/auth/data/session/session_store.dart';

class AuthRepository {
  AuthRepository({
    required http.Client client,
    required SessionStore store,
    required String baseUrl,
    bool allowLocalHttp = false,
    bool cookieSessions = false,
    SessionLock? cookieLock,
    DateTime Function()? clock,
  }) : this._(
         AuthApiTransport(
           client: client,
           baseUrl: baseUrl,
           allowLocalHttp: allowLocalHttp,
         ),
         store: store,
         cookieSessions: cookieSessions,
         cookieLock: cookieLock,
         clock: clock ?? DateTime.now,
       );

  AuthRepository._(
    this._api, {
    required SessionStore store,
    required bool cookieSessions,
    required SessionLock? cookieLock,
    required DateTime Function() clock,
  }) : _sessions = AuthSessionCoordinator(
         api: _api,
         store: store,
         cookieSessions: cookieSessions,
         cookieLock: cookieLock,
         clock: clock,
       );

  final AuthApiTransport _api;
  final AuthSessionCoordinator _sessions;

  // Use the repository's clearSession so overrides still apply during restore
  // and logout.
  Future<AuthSession?> restore() =>
      _sessions.restore(clearSession: clearSession);

  Future<void> register(String email, String password, String name) async {
    await _api.request(
      'POST',
      'register',
      body: {'email': email, 'password': password, 'display_name': name},
    );
  }

  Future<void> resendCode(String email) async {
    await _api.request('POST', 'verify-email/resend', body: {'email': email});
  }

  Future<AuthSession> verifyEmailLink(String hash) =>
      _sessions.start('verify-email/link', {'token_hash': hash});

  Future<void> confirmEmailChange(String hash) async {
    await _api.request(
      'POST',
      'account/email/confirm',
      body: {'token_hash': hash},
    );
  }

  Future<AuthSession> login(String email, String password) =>
      _sessions.start('login', {'email': email, 'password': password});

  Future<String> resolveGoogleSupabaseUrl({String configuredUrl = ''}) async {
    final allowLocal = _api.allowLocalHttp;
    final trimmedConfigured = configuredUrl.trim();
    Uri? configuredUri;
    if (trimmedConfigured.isNotEmpty) {
      configuredUri = parseGoogleProjectUrl(
        _api.normalizeClientUrl(trimmedConfigured),
        allowLocalHttp: allowLocal,
      );
      if (configuredUri == null) {
        throw authGoogleConfigException;
      }
    }

    try {
      final data = authJsonObject(await _api.request('GET', 'google/config'));
      if (data['google_enabled'] == false) {
        throw authGoogleDisabledException;
      }
      final rawServerUrl = data['supabase_url'];
      if (rawServerUrl is! String || rawServerUrl.trim().isEmpty) {
        throw _badResponse;
      }
      final normalizedServerUrl = _api.normalizeClientUrl(rawServerUrl);
      final serverUri = parseGoogleProjectUrl(
        normalizedServerUrl,
        allowLocalHttp: allowLocal,
      );
      if (serverUri == null) {
        throw authGoogleConfigException;
      }
      if (configuredUri != null &&
          !sameGoogleSupabaseOrigin(
            configuredUri,
            serverUri,
            allowLocalHttp: allowLocal,
          )) {
        throw authGoogleConfigMismatchException;
      }
      return serverUri.toString();
    } on FormatException {
      throw _badResponse;
    }
  }

  Future<AuthSession> loginWithGoogle(String code, String verifier) async {
    try {
      return await _sessions.start('google/exchange', {
        'code': code,
        'code_verifier': verifier,
      });
    } on AuthException catch (error) {
      if (error.code != 'INVALID_CODE') rethrow;
      throw const AuthException(
        'GOOGLE_CODE_EXPIRED',
        'Verifikasi Google sudah kedaluwarsa. Mulai lagi untuk masuk.',
      );
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.request('POST', 'password-reset', body: {'email': email});
  }

  Future<void> checkPasswordResetLink(String hash) async {
    await _api.request(
      'POST',
      'password-reset/check',
      body: {'token_hash': hash},
    );
  }

  Future<void> resetPasswordLink(String hash, String password) async {
    await _api.request(
      'POST',
      'password-reset/confirm',
      body: {'token_hash': hash, 'password': password},
    );
  }

  Future<void> changeCredentials(
    AuthSession session,
    String currentPassword, {
    String? email,
    String? password,
  }) async {
    await _sessions.authorize(
      session,
      (token) => _api.request(
        'POST',
        email == null ? 'account/password' : 'account/email',
        bearer: token,
        body: {
          'password': currentPassword,
          'email': ?email,
          'new_password': ?password,
        },
      ),
    );
  }

  Future<AuthSession> completeProfile(AuthSession session, String name) async {
    try {
      final (tokens, data) = await _sessions.authorize(
        session,
        (bearer) => _api.request(
          'PUT',
          'profile',
          bearer: bearer,
          body: {'display_name': name},
        ),
      );
      final account = AuthAccount.fromJson(authJsonObject(data));
      if (account.id != session.account.id) throw _badResponse;
      return AuthSession(tokens, account);
    } on FormatException {
      throw _badResponse;
    }
  }

  Future<Uint8List?> loadAvatar(AuthSession session) async {
    final (_, data) = await _sessions.authorize(
      session,
      (token) =>
          _api.request('GET', 'profile/photo', bearer: token, photo: true),
    );
    return data as Uint8List?;
  }

  Future<Uint8List> saveAvatar(
    AuthSession session,
    Uint8List bytes,
    String mediaType,
  ) async {
    final (_, data) = await _sessions.authorize(
      session,
      (token) => _api.request(
        'PUT',
        'profile/photo',
        bearer: token,
        photo: true,
        photoBody: bytes,
        photoMediaType: mediaType,
      ),
    );
    if (data is! Uint8List) throw _badResponse;
    return data;
  }

  Future<void> useGoogleAvatar(AuthSession session) async {
    await _sessions.authorize(
      session,
      (token) => _api.request(
        'POST',
        'profile/photo/google',
        bearer: token,
        photo: true,
      ),
    );
  }

  Future<Object?> readAuthenticated(
    AuthSession session,
    List<String> path, {
    Map<String, String>? query,
  }) async {
    final endpoint = Uri(pathSegments: path, queryParameters: query);
    final (_, data) = await _sessions.authorize(
      session,
      (bearer) => _api.request(
        'GET',
        endpoint.toString(),
        bearer: bearer,
        authEndpoint: false,
      ),
    );
    return data;
  }

  Future<Object?> sendAuthenticated(
    AuthSession session,
    String method,
    List<String> path, {
    Map<String, String>? query,
    Object? body,
    AuthException Function(int statusCode, Map<String, dynamic> envelope)?
    onEnvelopeError,
  }) async {
    final endpoint = Uri(pathSegments: path, queryParameters: query);
    final (_, data) = await _sessions.authorize(
      session,
      (bearer) => _api.request(
        method,
        endpoint.toString(),
        bearer: bearer,
        authEndpoint: false,
        jsonBody: body,
        onEnvelopeError: onEnvelopeError,
      ),
    );
    return data;
  }

  Future<Uint8List?> sendAuthenticatedMedia(
    AuthSession session,
    String method,
    List<String> path, {
    Uint8List? bytes,
    String? mediaType,
    AuthException Function(int statusCode, Map<String, dynamic> envelope)?
    onEnvelopeError,
  }) async {
    final endpoint = Uri(pathSegments: path);
    final (_, data) = await _sessions.authorize(
      session,
      (bearer) => _api.request(
        method,
        endpoint.toString(),
        bearer: bearer,
        authEndpoint: false,
        photo: true,
        photoBody: bytes,
        photoMediaType: mediaType,
        onEnvelopeError: onEnvelopeError,
      ),
    );
    return data as Uint8List?;
  }

  Future<({Stream<List<int>> stream, void Function() abort})>
  openAuthenticatedStream(
    AuthSession session,
    List<String> path, {
    Map<String, String>? query,
    String accept = 'text/event-stream',
  }) async {
    final endpoint = Uri(pathSegments: path, queryParameters: query);
    final (_, opened) = await _sessions.authorize(
      session,
      (bearer) =>
          _api.openStream(endpoint.toString(), bearer: bearer, accept: accept),
    );
    return opened;
  }

  Future<void> clearSession() => _sessions.clearSession();

  Future<void> logout(AuthSession? session) =>
      _sessions.logout(session, clearSession: clearSession);
}

const _badResponse = authBadResponseException;
