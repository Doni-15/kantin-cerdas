import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';

typedef LogWriter = void Function(String message);

class RequestLoggingMiddleware {
  RequestLoggingMiddleware({
    required this.config,
    LogWriter? writer,
    DateTime Function()? clock,
  }) : _writer = writer ?? stdout.writeln,
       _clock = clock ?? DateTime.now;

  final LoggingConfig config;
  final LogWriter _writer;
  final DateTime Function() _clock;

  Middleware get middleware {
    return (Handler innerHandler) {
      return (Request request) async {
        if (!config.requestEnabled) {
          return innerHandler(request);
        }

        final stopwatch = Stopwatch()..start();
        final timestamp = _clock();

        try {
          final response = await innerHandler(request);
          stopwatch.stop();

          _writeLog(
            timestamp: timestamp,
            level: _resolveLevel(response.statusCode),
            method: request.method,
            path: _normalizePath(request.url.path),
            status: response.statusCode,
            duration: stopwatch.elapsedMilliseconds,
          );

          return response;
        } catch (error, stackTrace) {
          stopwatch.stop();

          _writeLog(
            timestamp: timestamp,
            level: 'error',
            method: request.method,
            path: _normalizePath(request.url.path),
            status: 500,
            duration: stopwatch.elapsedMilliseconds,
            exceptionType: error.runtimeType.toString(),
            stackTrace: config.includeStackTrace ? stackTrace : null,
          );

          rethrow;
        }
      };
    };
  }

  String _normalizePath(String path) {
    return path.startsWith('/') ? path : '/$path';
  }

  String _resolveLevel(int statusCode) {
    if (statusCode >= 500) return 'error';
    if (statusCode >= 400) return 'warning';
    return 'info';
  }

  bool _shouldLog(String level) {
    const priorities = {'debug': 0, 'info': 1, 'warning': 2, 'error': 3};

    return priorities[level]! >= priorities[config.level]!;
  }

  void _writeLog({
    required DateTime timestamp,
    required String level,
    required String method,
    required String path,
    required int status,
    required int duration,
    String? exceptionType,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(level)) return;

    if (config.isJsonFormat) {
      final event = <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'level': level,
        'method': method,
        'path': path,
        'status': status,
        'duration_ms': duration,
      };

      if (exceptionType != null) {
        event['exception_type'] = exceptionType;
      }

      if (stackTrace != null) {
        event['stack_trace'] = stackTrace.toString();
      }

      _writer(jsonEncode(event));
      return;
    }

    final message = StringBuffer()
      ..write(timestamp.toIso8601String())
      ..write(' ')
      ..write(level.toUpperCase())
      ..write(' ')
      ..write(method)
      ..write(' ')
      ..write(path)
      ..write(' [$status] ')
      ..write('${duration}ms');

    if (exceptionType != null) {
      message
        ..write(' exception=')
        ..write(exceptionType);
    }

    if (stackTrace != null) {
      message
        ..write('\n')
        ..write(stackTrace);
    }

    _writer(message.toString());
  }
}
