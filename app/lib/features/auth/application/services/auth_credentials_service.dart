import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/google_oauth_provider.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

final authCredentialsServiceProvider = Provider<AuthCredentialsService>(
  AuthCredentialsService.new,
);

/// Coordinates pre-session credential workflows: Google OAuth PKCE browser
/// authorization + session exchange, registration step 1, verification email
/// resend, and password reset request.
class AuthCredentialsService {
  const AuthCredentialsService(this._ref);

  final Ref _ref;

  Future<void> signInWithGoogle({
    required void Function(VoidCallback? cancel) onCancelChanged,
    required bool Function() isMounted,
  }) async {
    final flow = _ref.read(googleOAuthProvider);
    if (flow == null) {
      throw authGoogleClientDisabledException;
    }
    String? resolvedSupabaseUrl;
    if (!flow.hasConfiguredUrl || flow.verifyBackendProject) {
      resolvedSupabaseUrl = await _ref
          .read(authRepositoryProvider)
          .resolveGoogleSupabaseUrl(configuredUrl: flow.configuredUrl);
      if (!isMounted()) return;
    }
    onCancelChanged(flow.cancel);
    final ({String code, String verifier}) result;
    try {
      result = await flow.requestCode(supabaseUrl: resolvedSupabaseUrl);
    } on AuthException catch (error) {
      if (error.code != 'GOOGLE_CANCELLED') rethrow;
      return;
    } finally {
      onCancelChanged(null);
    }
    if (!isMounted()) return;
    await _ref
        .read(authControllerProvider.notifier)
        .loginWithGoogle(result.code, result.verifier);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _ref.read(authRepositoryProvider).register(email, password, displayName);

  Future<void> resendVerificationEmail(String email) =>
      _ref.read(authRepositoryProvider).resendCode(email);

  Future<void> requestPasswordReset(String email) =>
      _ref.read(authRepositoryProvider).requestPasswordReset(email);
}
