import 'dart:convert';

const _nameMaxLength = 80;
const _emailMaxBytes = 254;
const _passwordMinLength = 15;
const _passwordMaxBytes = 72;

String? validateAuthName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty ||
      name.runes.length > _nameMaxLength ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
    return 'Masukkan nama 1–80 karakter.';
  }
  return null;
}

String? validateAuthEmail(String? value) {
  final email = value?.trim() ?? '';
  if (utf8.encode(email).length <= _emailMaxBytes &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return null;
  }
  return 'Masukkan alamat email yang valid.';
}

String? validateAuthPassword(String? value, {bool isNew = false}) {
  if (value == null || value.isEmpty) return 'Masukkan password.';
  if (isNew && value.runes.length < _passwordMinLength) {
    return 'Gunakan minimal 15 karakter.';
  }
  if (utf8.encode(value).length > _passwordMaxBytes) {
    return 'Password melebihi 72 byte.';
  }
  return null;
}
