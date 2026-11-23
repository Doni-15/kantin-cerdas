import 'package:kantin_cerdas_backend/src/core/config/auth_config.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/auth_jwt_claims.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/supabase_auth_account_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/data/supabase_auth_error_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:supabase/supabase.dart';

export 'package:kantin_cerdas_backend/src/modules/auth/data/supabase_auth_error_mapper.dart'
    show SignupFailureReporter;

/// Keeps provider responses, exception messages, and SDK objects inside data.
class SupabaseAuthGateway implements AuthGateway {
  const SupabaseAuthGateway(
    this._source, {
    required this.config,
    this._onSignupFailure,
  });

  final SupabaseAuthDataSource _source;
  final AuthConfig config;
  final SignupFailureReporter? _onSignupFailure;

  @override
  Future<void> register(
    String email,
    String password, {
    String? name,
    bool androidRedirect = true,
  }) async {
    await _invoke(() async {
      try {
        await _source.signUp(
          email: email,
          password: password,
          emailRedirectTo: androidRedirect
              ? androidEmailVerificationRedirect
              : null,
          data: name == null ? null : {'registration_name': name},
        );
      } on AuthException catch (error) {
        if (error.code == 'user_already_exists' ||
            error.code == 'email_exists') {
          return;
        }
        if (couldBeConcurrentRegistration(error) &&
            await _source.authRpc<bool>('kc_auth_registration_exists', {
              'p_email': email,
            })) {
          return;
        }
        rethrow;
      }
    }, isSignup: true);
  }

  @override
  Future<void> resendRegistration(
    String email, {
    bool androidRedirect = true,
  }) => _invoke(() async {
    try {
      await _source.resendRegistration(
        email,
        emailRedirectTo: androidRedirect
            ? androidEmailVerificationRedirect
            : null,
      );
    } on AuthException catch (error) {
      if (error.code != 'user_not_found' &&
          error.code != 'user_already_exists' &&
          error.code != 'email_exists') {
        rethrow;
      }
    }
  });

  @override
  Future<AuthSession> verifyRegistration(String email, String code) => _invoke(
    () async => _session(await _source.verifyRegistration(email, code)),
    rejected: AuthFailure.invalidCode,
  );

  @override
  Future<AuthSession> verifyRegistrationLink(String tokenHash) => _invoke(
    () async => _session(await _source.verifyRegistrationLink(tokenHash)),
    rejected: AuthFailure.invalidCode,
  );

  @override
  Future<AuthSession> login(String email, String password) => _invoke(
    () async => _session(
      await _source.signInWithPassword(email: email, password: password),
    ),
    rejected: AuthFailure.invalidCredentials,
  );

  @override
  Future<AuthSession> loginWithGoogle({
    required String idToken,
    required String googleAccessToken,
    String? nonce,
  }) => _invoke(
    () async => _googleSession(
      await _source.signInWithGoogle(
        idToken: idToken,
        googleAccessToken: googleAccessToken,
        nonce: nonce,
      ),
      rejected: AuthFailure.invalidCredentials,
    ),
    rejected: AuthFailure.invalidCredentials,
  );

  @override
  Future<AuthSession> exchangeGoogleCode(String code, String verifier) =>
      _invoke(
        () async => _googleSession(
          await _source.exchangeGoogleCode(code, verifier),
          rejected: AuthFailure.invalidCode,
        ),
        rejected: AuthFailure.invalidCode,
      );

  Future<AuthSession> _googleSession(
    AuthResponse response, {
    required AuthFailure rejected,
  }) {
    // Supabase owns identity linking. Accept its principal with a Google
    // identity, including one that already has a verified password method.
    final identities = response.session?.user.identities;
    if (identities?.any((identity) => identity.provider == 'google') != true) {
      throw rejected;
    }
    return _session(response);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) => _invoke(
    () async =>
        _session(await _source.refreshSession(refreshToken: refreshToken)),
    rejected: AuthFailure.invalidSession,
  );

  @override
  Future<AuthAccount> account(String accessToken) => _invoke(() async {
    final claims = readVerifiedJwtClaims(accessToken, config);
    final response = await _source.getUser(accessToken: accessToken);
    final user = response.user;
    if (user == null) throw AuthFailure.invalidSession;
    await _checkSession(user.id, claims);
    return mapSupabaseUserToAccount(user);
  }, rejected: AuthFailure.invalidSession);

  @override
  Future<AuthAccount> setDisplayName(
    AuthAccount actor,
    String displayName,
  ) async {
    return _invoke(() async {
      final response = await _source.setDisplayName(actor.id, displayName);
      final user = response.user;
      if (user == null || user.id != actor.id) throw AuthFailure.unavailable;
      return mapSupabaseUserToAccount(user);
    });
  }

  @override
  Future<void> logout(String accessToken) => _invoke(
    () => _source.signOut(accessToken: accessToken),
    rejected: AuthFailure.invalidSession,
  );

  @override
  Future<void> requestPasswordReset(String email) => _invoke(() async {
    if (!await _canRecover(email)) return;
    try {
      await _source.requestPasswordReset(email);
    } on AuthException catch (error) {
      if (error.code != 'user_not_found') rethrow;
    }
  });

  @override
  Future<void> checkPasswordResetLink(String tokenHash) => _invoke(() async {
    final pending = await _source.authRpc<bool>(
      'kc_auth_recovery_link_pending',
      {
        'p_token_hash': tokenHash,
        'p_ttl_seconds': config.recoveryLinkTtlSeconds,
      },
    );
    if (!pending) throw AuthFailure.invalidCode;
  });

  @override
  Future<void> resetPassword(String email, String code, String password) =>
      _invoke(
        () => _source.resetPassword(
          email: email,
          code: code,
          password: password,
          canRecover: _canRecoverUser,
        ),
        rejected: AuthFailure.invalidCode,
      );

  @override
  Future<void> resetPasswordLink(String tokenHash, String password) => _invoke(
    () => _source.resetPassword(
      tokenHash: tokenHash,
      password: password,
      canRecover: _canRecoverUser,
    ),
    rejected: AuthFailure.invalidCode,
  );

  @override
  Future<void> changeCredentials(
    String accessToken,
    String currentPassword, {
    String? email,
    String? password,
  }) async {
    final actor = await account(accessToken);
    if (!actor.canManageCredentials ||
        !await _invoke(() => _canRecover(actor.email))) {
      throw AuthFailure.providerManaged;
    }
    await _invoke(
      () => _source.changeCredentials(
        userId: actor.id,
        verifiedEmail: actor.email,
        currentPassword: currentPassword,
        email: email,
        password: password,
      ),
      rejected: AuthFailure.invalidCredentials,
    );
  }

  @override
  Future<void> confirmEmailChange(String tokenHash) => _invoke(
    () => _source.confirmEmailChange(tokenHash),
    rejected: AuthFailure.invalidCode,
  );

  Future<bool> _canRecover(String email) =>
      _source.authRpc<bool>('kc_auth_can_recover_password', {'p_email': email});

  Future<bool> _canRecoverUser(User user) async {
    final email = user.email;
    return email != null && await _canRecover(email.toLowerCase());
  }

  Future<AuthSession> _session(AuthResponse response) async {
    final session = response.session;
    final refreshToken = session?.refreshToken;
    final expiresAt = session?.expiresAt;
    if (session == null ||
        session.accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        expiresAt == null) {
      throw AuthFailure.unavailable;
    }
    await _checkSession(
      session.user.id,
      readVerifiedJwtClaims(session.accessToken, config),
    );
    return AuthSession(
      accessToken: session.accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
        isUtc: true,
      ),
      account: mapSupabaseUserToAccount(session.user),
    );
  }

  Future<void> _checkSession(
    String userId,
    ({String user, String session}) claims,
  ) async {
    if (claims.user != userId) throw AuthFailure.invalidSession;
    final status = await _source.authRpc<String>('kc_auth_session_status', {
      'p_user_id': userId,
      'p_session_id': claims.session,
    });
    switch (status) {
      case 'active':
        return;
      case 'inactive':
        throw AuthFailure.inactiveAccount;
      case 'invalid':
        throw AuthFailure.invalidSession;
      default:
        throw AuthFailure.unavailable;
    }
  }

  Future<T> _invoke<T>(
    Future<T> Function() operation, {
    AuthFailure? rejected,
    bool isSignup = false,
  }) => invokeSupabaseAuth(
    operation,
    rejected: rejected,
    isSignup: isSignup,
    onSignupFailure: _onSignupFailure,
  );
}
