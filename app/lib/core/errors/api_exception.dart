/// Error level HTTP yang dilempar DataSource (Dummy maupun API).
///
/// Repository yang memetakannya menjadi AuthFailure untuk Domain.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    this.fieldErrors = const {},
  });

  final int statusCode;

  /// Kode error dari Backend, lihat [ApiErrorCode].
  final String code;

  /// Error per field (untuk 422 Validation Error). Key = nama field.
  final Map<String, String> fieldErrors;

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

/// Kode error yang dikenal Data Layer.
abstract final class ApiErrorCode {
  static const invalidCredentials = 'invalid_credentials';
  static const accountDisabled = 'account_disabled';
  static const usernameTaken = 'username_taken';
  static const emailTaken = 'email_taken';
  static const wrongPassword = 'wrong_password';
  static const validationError = 'validation_error';
  static const tokenInvalid = 'token_invalid';
  static const tokenExpired = 'token_expired';
  static const network = 'network_error';
  static const timeout = 'timeout';
  static const serverError = 'server_error';
}
