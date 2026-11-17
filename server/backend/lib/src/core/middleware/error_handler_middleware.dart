import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';

typedef ErrorLogWriter = void Function(String message);

class ErrorHandlerMiddleware {
  ErrorHandlerMiddleware({
    required this.config,
    ErrorLogWriter? writer,
    DateTime Function()? clock,
  }) : _writer = writer ?? stderr.writeln,
       _clock = clock ?? DateTime.now;

  final LoggingConfig config;
  final ErrorLogWriter _writer;
  final DateTime Function() _clock;

  Middleware get middleware {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          return await innerHandler(request);
        } on ApiException catch (error) {
          return ApiResponse.error(
            statusCode: error.statusCode,
            code: error.code,
            message: error.message,
          );
        } catch (error, stackTrace) {
          _logException(request: request, error: error, stackTrace: stackTrace);

          return ApiResponse.error(
            statusCode: 500,
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Terjadi kesalahan internal pada server.',
          );
        }
      };
    };
  }

  void _logException({
    required Request request,
    required Object error,
    required StackTrace stackTrace,
  }) {
    const priorities = {'debug': 0, 'info': 1, 'warning': 2, 'error': 3};

    if (priorities['error']! < priorities[config.level]!) {
      return;
    }

    final timestamp = _clock();
    final exceptionType = error.runtimeType.toString();

    if (config.isJsonFormat) {
      final event = <String, Object?>{
        'timestamp': timestamp.toIso8601String(),
        'level': 'error',
        'method': request.method,
        'path': '/${request.url.path}',
        'status': 500,
        'exception_type': exceptionType,
      };

      if (config.includeStackTrace) {
        event['stack_trace'] = stackTrace.toString();
      }

      _writer(jsonEncode(event));
      return;
    }

    final message = StringBuffer()
      ..write(timestamp.toIso8601String())
      ..write(' ERROR ')
      ..write(request.method)
      ..write(' /${request.url.path}')
      ..write(' [500] exception=')
      ..write(exceptionType);

    if (config.includeStackTrace) {
      message
        ..write('\n')
        ..write(stackTrace);
    }

    _writer(message.toString());
  }
}
