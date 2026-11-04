import 'dart:convert';

import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';

final RegExp _explicitTimezonePattern = RegExp(
  r'(?:[Tt ])\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:[Zz]|[+-]\d{2}:?\d{2})$',
);

/// Memastikan nilai mentah adalah Map JSON dengan seluruh kunci bertipe String.
Map<String, Object?> asJsonMap(
  Object? raw, {
  String? fieldName,
  String? message,
}) {
  final effectiveMessage =
      message ??
      (fieldName != null
          ? 'Payload JSON "$fieldName" bukan objek yang valid.'
          : 'Payload JSON bukan objek yang valid.');
  if (raw is Map<String, Object?>) {
    return raw;
  }
  if (raw is! Map<Object?, Object?>) {
    throw DataParsingException(effectiveMessage);
  }
  final result = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String) {
      throw DataParsingException(effectiveMessage);
    }
    result[key] = entry.value;
  }
  return result;
}

/// Mencoba mengekstrak Map JSON dari objek atau string JSON tanpa melempar error.
Map<String, Object?>? tryAsJsonMap(Object? raw) {
  Object? candidate = raw;
  if (candidate is String) {
    final trimmed = candidate.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return null;
    }
    try {
      candidate = jsonDecode(trimmed);
    } on FormatException {
      return null;
    }
  }
  if (candidate is Map<String, Object?>) {
    return candidate;
  }
  if (candidate is! Map<Object?, Object?>) {
    return null;
  }
  final result = <String, Object?>{};
  for (final entry in candidate.entries) {
    final key = entry.key;
    if (key is! String) {
      return null;
    }
    result[key] = entry.value;
  }
  return result;
}

/// Menormalisasi teks opsional dari JSON: string kosong/whitespace menjadi null.
String? normalizeOptionalText(
  Object? raw, {
  String? fieldName,
  String? message,
}) {
  if (raw == null) {
    return null;
  }
  final effectiveMessage =
      message ??
      (fieldName != null
          ? 'Field teks opsional "$fieldName" tidak valid.'
          : 'Field teks opsional tidak valid.');
  if (raw is! String) {
    throw DataParsingException(effectiveMessage);
  }
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Mem-parse timestamp ISO-8601 yang wajib memiliki zona waktu eksplisit ke UTC.
DateTime parseStrictUtcDateTime(
  Object? raw, {
  String? fieldName,
  String? message,
}) {
  final effectiveMessage =
      message ??
      (fieldName != null
          ? 'Timestamp "$fieldName" wajib berformat ISO-8601 dengan zona waktu.'
          : 'Timestamp wajib berformat ISO-8601 dengan zona waktu.');
  if (raw is! String) {
    throw DataParsingException(effectiveMessage);
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty || !_explicitTimezonePattern.hasMatch(trimmed)) {
    throw DataParsingException(effectiveMessage);
  }
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    throw DataParsingException(effectiveMessage);
  }
  return parsed.toUtc();
}
