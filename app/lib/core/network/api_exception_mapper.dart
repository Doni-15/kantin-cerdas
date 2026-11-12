import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';

/// Menerjemahkan DioException menjadi ApiException terstandar untuk lapisan data.
ApiException mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return ApiException(type: ApiExceptionType.timeout);
    case DioExceptionType.connectionError:
      return ApiException(type: ApiExceptionType.connection);
    case DioExceptionType.cancel:
      return ApiException(type: ApiExceptionType.cancelled);
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final Object? rawData = error.response?.data;
      final headers = error.response?.headers;
      final parsed = _extractErrorPayload(rawData);
      final headerRequestId = headers?.value('x-request-id')?.trim();
      final retryAfterRaw = headers?.value('retry-after')?.trim();
      final retryAfterSeconds = retryAfterRaw != null
          ? int.tryParse(retryAfterRaw)
          : null;
      return ApiException(
        type: ApiExceptionType.response,
        statusCode: statusCode,
        code: parsed.code,
        message: parsed.message,
        requestId:
            parsed.requestId ??
            (headerRequestId != null && headerRequestId.isNotEmpty
                ? headerRequestId
                : null),
        retryAfterSeconds: retryAfterSeconds != null && retryAfterSeconds >= 0
            ? retryAfterSeconds
            : null,
        fieldErrors: parsed.fieldErrors,
        details: parsed.details,
      );
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return ApiException(type: ApiExceptionType.unexpected);
  }
}

({
  String? code,
  String? message,
  String? requestId,
  Map<String, String> fieldErrors,
  Map<String, Object?> details,
})
_extractErrorPayload(Object? rawData) {
  final rootMap = tryAsJsonMap(rawData);
  if (rootMap == null) {
    return (
      code: null,
      message: null,
      requestId: null,
      fieldErrors: const {},
      details: const {},
    );
  }

  final nestedError = tryAsJsonMap(rootMap['error']);
  final Map<String, Object?> source = nestedError ?? rootMap;

  final Object? rawCode = source['code'];
  final String? code = rawCode is String && rawCode.trim().isNotEmpty
      ? rawCode.trim()
      : null;

  final Object? rawMessage = source['message'];
  final String? message = rawMessage is String && rawMessage.trim().isNotEmpty
      ? rawMessage.trim()
      : null;

  final Object? rawRequestId =
      source['request_id'] ??
      source['requestId'] ??
      rootMap['request_id'] ??
      rootMap['requestId'];
  final String? requestId =
      rawRequestId is String && rawRequestId.trim().isNotEmpty
      ? rawRequestId.trim()
      : null;

  final Object? rawDetails = source['details'] ?? rootMap['details'];
  final Map<String, Object?> details = tryAsJsonMap(rawDetails) ?? const {};

  final Object? rawFields =
      source['field_errors'] ??
      source['fieldErrors'] ??
      details['field_errors'] ??
      details['fieldErrors'];
  final fieldErrors = <String, String>{};
  if (rawFields is Map<Object?, Object?>) {
    for (final entry in rawFields.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key is String && val is String && key.trim().isNotEmpty) {
        fieldErrors[key] = val;
      } else if (key is String && val is List<Object?> && val.isNotEmpty) {
        final first = val.first;
        if (first is String) {
          fieldErrors[key] = first;
        }
      }
    }
  }

  return (
    code: code,
    message: message,
    requestId: requestId,
    fieldErrors: fieldErrors,
    details: details,
  );
}
