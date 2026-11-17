class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  }) {
    if (statusCode < 400 || statusCode > 599) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'Status code ApiException harus berada antara 400 dan 599.',
      );
    }
  }

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
