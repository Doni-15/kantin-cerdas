import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:supabase/supabase.dart';
import 'package:http/http.dart' as http;

class SupabaseAuthDataSource {
  const SupabaseAuthDataSource({
    required this._clientFactory,
    this._httpClient,
    this._requestTimeout = const Duration(seconds: 15),
  });

  final SupabaseClientFactory _clientFactory;
  final http.Client? _httpClient;
  final Duration _requestTimeout;

  Future<T> _withAuthClient<T>(
    Future<T> Function(SupabaseClient client) operation, {
    GotrueAsyncStorage? pkceStorage,
  }) async {
    final client = _clientFactory.createAuthClient(
      httpClient: _httpClient,
      pkceStorage: pkceStorage,
    );

    try {
      return await operation(client).timeout(_requestTimeout);
    } finally {
      await client.dispose();
    }
  }

  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
  }) {
    _validateIdentity(email: email, phone: phone);

    return _withAuthClient(
      (client) => client.auth.signUp(
        email: email,
        phone: phone,
        password: password,
        emailRedirectTo: emailRedirectTo,
        data: data,
        captchaToken: captchaToken,
      ),
    );
  }

  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) {
    _validateIdentity(email: email, phone: phone);

    return _withAuthClient(
      (client) => client.auth.signInWithPassword(
        email: email,
        phone: phone,
        password: password,
        captchaToken: captchaToken,
      ),
    );
  }

  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    required String googleAccessToken,
    String? nonce,
  }) {
    return _withAuthClient(
      (client) => client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAccessToken,
        nonce: nonce,
      ),
    );
  }

  Future<AuthResponse> exchangeGoogleCode(String code, String verifier) =>
      _withAuthClient((client) async {
        final result = await client.auth.exchangeCodeForSession(code);
        return AuthResponse(session: result.session);
      }, pkceStorage: _SingleExchangeStorage(verifier));

  Future<AuthResponse> verifyRegistration(String email, String code) {
    return _withAuthClient(
      (client) => client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.signup,
      ),
    );
  }

  Future<AuthResponse> verifyRegistrationLink(String tokenHash) =>
      _withAuthClient(
        (client) =>
            client.auth.verifyOTP(tokenHash: tokenHash, type: OtpType.signup),
      );

  Future<void> confirmEmailChange(String tokenHash) =>
      _withAuthClient((client) async {
        await client.auth.verifyOTP(
          tokenHash: tokenHash,
          type: OtpType.emailChange,
        );
        await _revokeTemporarySession(client);
      });

  Future<void> resendRegistration(
    String email, {
    String? emailRedirectTo,
  }) async {
    await _withAuthClient(
      (client) => client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: emailRedirectTo,
      ),
    );
  }

  Future<void> requestPasswordReset(String email) =>
      _withAuthClient((client) => client.auth.resetPasswordForEmail(email));

  Future<void> resetPassword({
    String? email,
    String? code,
    String? tokenHash,
    required String password,
    required Future<bool> Function(User) canRecover,
  }) {
    return _withAuthClient((client) async {
      final response = await client.auth.verifyOTP(
        email: email,
        token: code,
        tokenHash: tokenHash,
        type: OtpType.recovery,
      );
      try {
        final user = response.session?.user;
        if (user == null || !await canRecover(user)) {
          throw const AuthException(
            'Recovery is unavailable.',
            code: 'otp_expired',
          );
        }
        await client.auth.updateUser(UserAttributes(password: password));
      } finally {
        await _revokeTemporarySession(client);
      }
    });
  }

  Future<void> changeCredentials({
    required String userId,
    required String verifiedEmail,
    required String currentPassword,
    String? email,
    String? password,
  }) => _withAuthClient((client) async {
    final proof = await client.auth.signInWithPassword(
      email: verifiedEmail,
      password: currentPassword,
    );
    try {
      if (proof.session?.user.id != userId) {
        throw const AuthException(
          'Invalid credentials.',
          code: 'invalid_credentials',
        );
      }
      await client.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          currentPassword: password == null ? null : currentPassword,
        ),
      );
    } finally {
      await _revokeTemporarySession(client);
    }
  });

  Future<void> _revokeTemporarySession(SupabaseClient client) async {
    if (client.auth.currentSession == null) return;
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } on Exception {
      // This server-owned session was never returned to the client.
    }
  }

  Future<T> authRpc<T>(String name, Map<String, dynamic> parameters) async {
    final client = _clientFactory.createServerClient(httpClient: _httpClient);
    try {
      final result = await client
          .rpc<Object?>(name, params: parameters)
          .timeout(_requestTimeout);
      if (result is! T) {
        throw const FormatException('Invalid authentication RPC result.');
      }
      return result;
    } finally {
      await client.dispose();
    }
  }

  Future<UserResponse> setDisplayName(
    String verifiedUserId,
    String name,
  ) async {
    final client = _clientFactory.createServerClient(httpClient: _httpClient);
    try {
      return await client.auth.admin
          .updateUserById(
            verifiedUserId,
            attributes: AdminUserAttributes(
              userMetadata: {'display_name': name},
            ),
          )
          .timeout(_requestTimeout);
    } finally {
      await client.dispose();
    }
  }

  Future<AuthResponse> refreshSession({required String refreshToken}) {
    final token = refreshToken.trim();

    if (token.isEmpty) {
      throw ArgumentError.value(
        refreshToken,
        'refreshToken',
        'Refresh token tidak boleh kosong.',
      );
    }

    return _withAuthClient((client) => client.auth.refreshSession(token));
  }

  Future<UserResponse> getUser({required String accessToken}) {
    final token = accessToken.trim();

    if (token.isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Access token tidak boleh kosong.',
      );
    }

    return _withAuthClient((client) => client.auth.getUser(token));
  }

  Future<void> signOut({required String accessToken}) {
    final token = accessToken.trim();

    if (token.isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Access token tidak boleh kosong.',
      );
    }

    return _withAuthClient(
      (client) => client.auth.admin.signOut(token, scope: SignOutScope.local),
    );
  }

  void _validateIdentity({String? email, String? phone}) {
    final hasEmail = email != null && email.trim().isNotEmpty;
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    if (hasEmail == hasPhone) {
      throw ArgumentError('Tentukan tepat satu identitas: email atau phone.');
    }
  }
}

/// One SDK client owns one code exchange. The verifier is never shared.
class _SingleExchangeStorage extends GotrueAsyncStorage {
  _SingleExchangeStorage(this._verifier);

  String? _verifier;

  @override
  Future<String?> getItem({required String key}) async => _verifier;

  @override
  Future<void> removeItem({required String key}) async => _verifier = null;

  @override
  Future<void> setItem({required String key, required String value}) async {
    _verifier = value;
  }
}
