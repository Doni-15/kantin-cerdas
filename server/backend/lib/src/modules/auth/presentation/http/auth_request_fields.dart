import 'dart:convert';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';

String readAuthText(
  Map<String, Object?> body,
  String field, {
  required int maxLength,
}) {
  final value = body[field];
  if (value is! String || value.isEmpty || value.length > maxLength) {
    throw invalidAuthInput('Kolom $field tidak valid.');
  }
  return value;
}

String readAuthEmail(Map<String, Object?> body) {
  final value = readAuthText(
    body,
    'email',
    maxLength: 254,
  ).trim().toLowerCase();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ||
      utf8.encode(value).length > 254) {
    throw invalidAuthInput('Alamat email tidak valid.');
  }
  return value;
}

String readAuthDisplayName(Map<String, Object?> body) {
  final name = readAuthText(body, 'display_name', maxLength: 240).trim();
  if (name.isEmpty ||
      name.runes.length > 80 ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
    throw invalidAuthInput('Nama lengkap harus berisi 1–80 karakter.');
  }
  return name;
}

String readAuthPassword(
  Map<String, Object?> body, {
  bool newPassword = false,
  String field = 'password',
}) {
  final value = readAuthText(body, field, maxLength: 72);
  if (utf8.encode(value).length > 72) {
    throw invalidAuthInput('Kata sandi melebihi panjang yang didukung.');
  }
  if (newPassword && value.runes.length < 15) {
    throw invalidAuthInput('Gunakan kata sandi minimal 15 karakter.');
  }
  return value;
}

String readAuthLinkToken(Map<String, Object?> body) {
  final value = readAuthText(body, 'token_hash', maxLength: 256);
  if (!RegExp(r'^[A-Za-z0-9_-]{32,256}$').hasMatch(value)) {
    throw AuthFailure.invalidCode;
  }
  return value;
}

String readAuthOtp(Map<String, Object?> body) {
  final value = readAuthText(body, 'code', maxLength: 10);
  if (!RegExp(r'^[0-9]{6,10}$').hasMatch(value)) {
    throw invalidAuthInput('Kode verifikasi tidak valid.');
  }
  return value;
}

String readAuthToken(
  Map<String, Object?> body,
  String field, {
  int maxLength = 8192,
}) {
  final value = readAuthText(body, field, maxLength: maxLength);
  if (!RegExp(r'^[\x21-\x7e]+$').hasMatch(value)) {
    throw invalidAuthInput('Format token tidak valid.');
  }
  return value;
}

bool matchesServerSupabaseOrigin(String rawClientUrl, Uri serverUrl) {
  final clientUri = Uri.tryParse(rawClientUrl);
  if (clientUri == null ||
      !{'http', 'https'}.contains(clientUri.scheme) ||
      clientUri.host.isEmpty ||
      clientUri.userInfo.isNotEmpty ||
      (clientUri.path.isNotEmpty && clientUri.path != '/') ||
      clientUri.hasQuery ||
      clientUri.hasFragment) {
    return false;
  }
  if (clientUri.origin == serverUrl.origin) return true;
  const loopbackHosts = {'127.0.0.1', 'localhost', '::1', '10.0.2.2'};
  if (serverUrl.scheme == 'http' &&
      clientUri.scheme == 'http' &&
      loopbackHosts.contains(serverUrl.host) &&
      loopbackHosts.contains(clientUri.host) &&
      clientUri.port == serverUrl.port) {
    return true;
  }
  return false;
}

ApiException invalidAuthInput(String message) =>
    ApiException(statusCode: 400, code: 'INVALID_INPUT', message: message);
