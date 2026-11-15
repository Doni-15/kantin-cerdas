/// Jenis kegagalan pada komunikasi API.
enum ApiExceptionType { connection, timeout, cancelled, response, unexpected }

final class ApiException implements Exception {
  ApiException({
    required this.type,
    this.statusCode,
    this.code,
    this.message,
    this.requestId,
    this.retryAfterSeconds,
    Map<String, String> fieldErrors = const {},
    Map<String, Object?> details = const {},
  }) : fieldErrors = Map<String, String>.unmodifiable(fieldErrors),
       details = Map<String, Object?>.unmodifiable(details);

  final ApiExceptionType type;
  final int? statusCode;
  final String? code;
  final String? message;
  final String? requestId;
  final int? retryAfterSeconds;
  final Map<String, String> fieldErrors;
  final Map<String, Object?> details;

  /// Menandakan apakah respons HTTP membawa envelope kode bisnis dari backend.
  bool get hasBackendErrorCode => code != null && code!.trim().isNotEmpty;

  @override
  String toString() {
    return 'ApiException('
        'type: ${type.name}, '
        'statusCode: $statusCode, '
        'code: $code'
        ')';
  }
}
