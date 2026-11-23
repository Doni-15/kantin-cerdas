import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:shelf/shelf.dart';

String requireCustomerUuid(String raw) {
  final value = tryNormalizeUuid(raw);
  if (value == null) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  return value;
}

String? optionalCustomerUuid(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  return requireCustomerUuid(raw);
}

Future<Map<String, Object?>> readCustomerJsonBody(Request request) =>
    readJsonObjectBody(
      request,
      onUnsupportedMediaType: () =>
          const CustomerFailure(CustomerFailureCode.unsupportedMediaType),
      onTooLarge: () =>
          const CustomerFailure(CustomerFailureCode.payloadTooLarge),
      onInvalidJson: () =>
          const CustomerFailure(CustomerFailureCode.invalidInput),
    );

String readCustomerRequiredText(
  Map<String, Object?> body,
  String field, {
  required int maxLength,
  bool allowNewlines = false,
}) {
  final value = body[field];
  if (value is! String) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  final trimmed = value.trim();
  final hasUnsafeControl = allowNewlines
      ? hasMultilineUnsafeControlChars(trimmed)
      : hasStrictControlChars(trimmed);
  if (trimmed.isEmpty || trimmed.runes.length > maxLength || hasUnsafeControl) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  return trimmed;
}

String readCustomerOptionalText(
  Map<String, Object?> body,
  String field, {
  required int maxLength,
}) {
  final value = body[field];
  if (value == null) return '';
  if (value is! String) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  final trimmed = value.trim();
  if (trimmed.runes.length > maxLength ||
      hasMultilineUnsafeControlChars(trimmed)) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  return trimmed;
}

String? readCustomerPatchOptionalText(
  Map<String, Object?> body,
  String field, {
  required int maxLength,
}) {
  if (!body.containsKey(field) || body[field] == null) return null;
  return readCustomerOptionalText(body, field, maxLength: maxLength);
}

int readCustomerIntField(
  Map<String, Object?> body,
  String field, {
  required int min,
  required int max,
  int? defaultValue,
}) {
  final value = body[field];
  if (value == null && defaultValue != null) return defaultValue;
  if (value is! int || value < min || value > max) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  return value;
}

bool readCustomerBoolField(
  Map<String, Object?> body,
  String field, {
  bool? defaultValue,
}) {
  final value = body[field];
  if (value == null && defaultValue != null) return defaultValue;
  if (value is! bool) {
    throw const CustomerFailure(CustomerFailureCode.invalidInput);
  }
  return value;
}
