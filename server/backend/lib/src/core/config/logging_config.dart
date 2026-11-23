import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parsers.dart';

class LoggingConfig {
  const LoggingConfig._({
    required this.level,
    required this.format,
    required this.requestEnabled,
    required this.includeStackTrace,
  });

  final String level;
  final String format;
  final bool requestEnabled;
  final bool includeStackTrace;

  bool get isJsonFormat => format == 'json';

  bool get isTextFormat => format == 'text';

  factory LoggingConfig.fromEnv(EnvConfig env) {
    final level = readEnvString(
      env,
      'LOG_LEVEL',
      defaultValue: 'info',
    ).toLowerCase();

    const allowedLevels = {'debug', 'info', 'warning', 'error'};

    if (!allowedLevels.contains(level)) {
      throw FormatException(
        'LOG_LEVEL tidak valid: $level. '
        'Gunakan debug, info, warning, atau error.',
      );
    }

    final format = readEnvString(
      env,
      'LOG_FORMAT',
      defaultValue: 'text',
    ).toLowerCase();

    const allowedFormats = {'text', 'json'};

    if (!allowedFormats.contains(format)) {
      throw FormatException(
        'LOG_FORMAT tidak valid: $format. '
        'Gunakan text atau json.',
      );
    }

    return LoggingConfig._(
      level: level,
      format: format,
      requestEnabled: readEnvBool(
        env,
        'LOG_REQUEST_ENABLED',
        defaultValue: true,
      ),
      includeStackTrace: readEnvBool(
        env,
        'LOG_INCLUDE_STACK_TRACE',
        defaultValue: false,
      ),
    );
  }
}
