import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';

enum AuthApiOperation {
  login,
  register,
  restoreSession,
  refreshSession,
  changePassword,
  updateProfileAvatar,
  logout,
}

/// Menerjemahkan kegagalan API menjadi kegagalan domain autentikasi.
AuthFailure mapAuthApiException(
  ApiException error, {
  required AuthApiOperation operation,
}) {
  return switch (error.type) {
    ApiExceptionType.connection ||
    ApiExceptionType.timeout => const AuthNetworkFailure(),
    ApiExceptionType.response => _mapResponseFailure(error, operation),
    ApiExceptionType.cancelled ||
    ApiExceptionType.unexpected => const AuthUnexpectedFailure(),
  };
}

AuthFailure _mapResponseFailure(
  ApiException error,
  AuthApiOperation operation,
) {
  final statusCode = error.statusCode;
  final code = error.code;

  if (statusCode != null && statusCode >= 500 && statusCode <= 599) {
    return const AuthServerFailure();
  }

  if (statusCode == 429 ||
      code == 'RATE_LIMITED' ||
      code == 'TOO_MANY_REQUESTS') {
    return const AuthRateLimitedFailure();
  }

  if (code == 'ACCOUNT_DISABLED') {
    return const AuthAccountDisabledFailure();
  }

  if (code == 'USERNAME_TAKEN') {
    return const AuthUsernameTakenFailure();
  }

  if (code == 'EMAIL_TAKEN') {
    return const AuthEmailTakenFailure();
  }

  if (statusCode == 409) {
    if (error.fieldErrors.containsKey('username')) {
      return const AuthUsernameTakenFailure();
    }
    if (error.fieldErrors.containsKey('email')) {
      return const AuthEmailTakenFailure();
    }
  }

  if (code == 'INVALID_CURRENT_PASSWORD') {
    return const AuthInvalidCurrentPasswordFailure();
  }

  if (code == 'INVALID_CREDENTIALS') {
    return const AuthInvalidCredentialsFailure();
  }

  if (code == 'UNAUTHENTICATED' ||
      code == 'TOKEN_EXPIRED' ||
      code == 'INVALID_TOKEN') {
    return switch (operation) {
      AuthApiOperation.login => const AuthInvalidCredentialsFailure(),
      AuthApiOperation.restoreSession ||
      AuthApiOperation.refreshSession ||
      AuthApiOperation.changePassword ||
      AuthApiOperation.updateProfileAvatar ||
      AuthApiOperation.logout => const AuthSessionExpiredFailure(),
      AuthApiOperation.register => const AuthUnexpectedFailure(),
    };
  }

  if (operation == AuthApiOperation.changePassword &&
      error.fieldErrors.isNotEmpty) {
    return AuthValidationFailure(error.fieldErrors);
  }

  if (statusCode == 401) {
    return switch (operation) {
      AuthApiOperation.login => const AuthInvalidCredentialsFailure(),
      AuthApiOperation.restoreSession ||
      AuthApiOperation.refreshSession ||
      AuthApiOperation.changePassword ||
      AuthApiOperation.updateProfileAvatar ||
      AuthApiOperation.logout => const AuthSessionExpiredFailure(),
      AuthApiOperation.register => const AuthUnexpectedFailure(),
    };
  }

  if (error.fieldErrors.isNotEmpty) {
    return AuthValidationFailure(error.fieldErrors);
  }

  return const AuthUnexpectedFailure();
}
