import 'dart:io';
import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';

Middleware allowedHostsMiddleware(AppConfig config) {
  final allowed = config.security.allowedHosts;
  if (allowed.contains('*')) return (inner) => inner;

  final trustProxy = config.security.trustProxy;

  return (Handler inner) {
    return (Request request) {
      final raw = (trustProxy ? request.headers['x-forwarded-host'] : null) 
        ?? request.headers['host'] 
        ?? '';

      final first = raw.split(',').first.trim();
      final host = Uri.tryParse('http://$first')?.host ?? '';

      if (!_hostAllowed(host, allowed)) {
        return const ApiException(
          statusCode: 400,
          code: 'HOST_NOT_ALLOWED',
          message: 'Host permintaan tidak diizinkan.',
        ).toResponse();
      }
      return inner(request);
    };
  };
}

bool _hostAllowed(String host, List<String> allowed) {
  final h = host.toLowerCase();
  for (final raw in allowed) {
    final rule = raw.toLowerCase();
    if (rule == h) return true;
    if (rule.startsWith('*.') && h.endsWith(rule.substring(1))) return true;
  }
  return false;
}

Middleware rateLimitMiddleware(AppConfig config) {
  final cfg = config.rateLimit;
  if (!cfg.enabled) return (inner) => inner;

  final prefix = config.server.apiPrefix;
  final healthPath = '$prefix/health';
  final authPath = '$prefix/auth';

  final general = _FixedWindowLimiter(
    Duration(seconds: cfg.windowSeconds),
    cfg.maxRequests,
  );
  final auth = _FixedWindowLimiter(
    Duration(seconds: cfg.authWindowSeconds),
    cfg.authMaxRequests,
  );

  return (Handler inner) {
    return (Request request) {
      final path = '/${request.url.path}';
      if (path == healthPath) return inner(request);

      final isAuth = path == authPath || path.startsWith('$authPath/');
      final limiter = isAuth ? auth : general;
      final ip = _clientIp(request, cfg.trustProxy);
      final retryAfter = limiter.hit(ip);

      if (retryAfter > 0) {
        return ApiException.rateLimited()
            .toResponse()
            .change(headers: {'retry-after': '$retryAfter'});
      }
      return inner(request);
    };
  };
}

 String _clientIp(Request request, bool trustProxy) {
   if (trustProxy) {
     final forwarded = request.headers['x-forwarded-for'];
     
     if (forwarded != null && forwarded.trim().isNotEmpty) {
      final candidate = forwarded.split(',').last.trim();
      if (InternetAddress.tryParse(candidate) != null) return candidate;
     }
   }

  final info = request.context['shelf.io.connection_info'];
  if (info is HttpConnectionInfo) return info.remoteAddress.address;
  return 'unknown';
}

final class _Bucket {
  final DateTime start;
  int count = 1;
  _Bucket(this.start);
}

final class _FixedWindowLimiter {
  final Duration window;
  final int max;
  final Map<String, _Bucket> _hits = {};
  DateTime _lastSweep = DateTime.now();

  _FixedWindowLimiter(this.window, this.max);

  int hit(String key) {
    final now = DateTime.now();
    _sweep(now);

    final bucket = _hits[key];
    if (bucket == null || now.difference(bucket.start) >= window) {
      _hits[key] = _Bucket(now);
      return 0;
    }

    if (bucket.count >= max) {
      final remaining = window - now.difference(bucket.start);
      final seconds = (remaining.inMilliseconds / 1000).ceil();
      return seconds < 1 ? 1 : seconds;
    }

    bucket.count++;
    return 0;
  }

  void _sweep(DateTime now) {
    if (now.difference(_lastSweep) < window) return;
    _lastSweep = now;
    _hits.removeWhere((_, b) => now.difference(b.start) >= window);
  }
}

Middleware bodyLimitMiddleware(AppConfig config) {
  final max = config.server.maxRequestBodyBytes;

  return (Handler inner) {
    return (Request request) {
      final declared = request.contentLength;
      if (declared != null && declared > max) {
        return _payloadTooLarge(max).toResponse();
      }
      return inner(request.change(body: _limitBody(request.read(), max)));
    };
  };
}

Stream<List<int>> _limitBody(Stream<List<int>> source, int max) async* {
  var total = 0;
  await for (final chunk in source) {
    total += chunk.length;
    if (total > max) throw _payloadTooLarge(max);
    yield chunk;
  }
}

ApiException _payloadTooLarge(int max) {
  final limit = max >= 1048576
      ? '${(max / 1048576).toStringAsFixed(max % 1048576 == 0 ? 0 : 1)} MB'
      : '${(max / 1024).toStringAsFixed(0)} KB';

  return ApiException(
    statusCode: 413,
    code: 'PAYLOAD_TOO_LARGE',
    message: 'Ukuran data yang dikirim melebihi batas $limit.',
  );
}

Middleware requestTimeoutMiddleware(AppConfig config) {
  final timeout = Duration(seconds: config.server.requestTimeoutSeconds);

  return (Handler inner) {
    return (Request request) async {
      return Future.sync(() => inner(request)).timeout(
        timeout,
        onTimeout: () => const ApiException(
          statusCode: 504,
          code: 'REQUEST_TIMEOUT',
          message: 'Permintaan memakan waktu terlalu lama. Silakan coba lagi.',
        ).toResponse(),
      );
    };
  };
}