import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

String readEnvString(EnvConfig env, String key, {String defaultValue = ''}) {
  final value = env[key]?.trim();
  if (value == null || value.isEmpty) {
    return defaultValue;
  }
  return value;
}

bool readEnvBool(EnvConfig env, String key, {required bool defaultValue}) {
  final rawValue = env[key];
  if (rawValue == null || rawValue.trim().isEmpty) {
    return defaultValue;
  }
  return switch (rawValue.trim().toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => throw FormatException('$key harus bernilai true atau false.'),
  };
}

int readEnvInt(
  EnvConfig env,
  String key, {
  required int defaultValue,
  required int min,
  required int max,
  String? errorMessage,
}) {
  final rawValue = env[key];
  if (rawValue == null || rawValue.trim().isEmpty) {
    return defaultValue;
  }
  final value = int.tryParse(rawValue.trim());
  if (value == null || value < min || value > max) {
    throw FormatException(
      errorMessage ?? '$key harus berupa angka antara $min dan $max.',
    );
  }
  return value;
}
