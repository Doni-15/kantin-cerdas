import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:kantin_cerdas_backend/src/core/config/proxy_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/rate_limit_config.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';

const _connectionInfoKey = 'shelf.io.connection_info';

class _RateLimitEntry {
  _RateLimitEntry({required this.windowStartedAt, required this.window});

  DateTime windowStartedAt;
  final Duration window;
  int requestCount = 0;
}

class RateLimitMiddleware {
  RateLimitMiddleware({
    required this.config,
    required this.proxyConfig,
    required this.apiPrefix,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RateLimitConfig config;
  final ProxyConfig proxyConfig;
  final String apiPrefix;
  final DateTime Function() _clock;

  final Map<String, _RateLimitEntry> _clients = {};

  static const Duration _cleanupInterval = Duration(seconds: 60);
  DateTime? _nextCleanupAt;

  Middleware get middleware {
    return (Handler innerHandler) {
      return (Request request) async {
        if (!config.enabled) {
          return innerHandler(request);
        }

        final clientIp = _getClientIp(request);

        if (clientIp == null) {
          return ApiResponse.error(
            statusCode: 500,
            code: 'CLIENT_IP_UNAVAILABLE',
            message: 'Informasi koneksi client tidak dapat diidentifikasi.',
          );
        }

        final isAuthRequest = _isAuthRequest(request.url.path);
        final window = isAuthRequest ? config.authWindow : config.window;
        final maxRequests = isAuthRequest
            ? config.authMaxRequests
            : config.maxRequests;

        final now = _clock();
        final key = '$clientIp:${isAuthRequest ? 'auth' : 'general'}';

        _cleanupExpiredEntriesIfDue(now);

        var entry = _clients[key];

        if (entry == null) {
          if (_clients.length >= config.maxEntries) {
            // Lakukan cleanup lebih awal ketika kapasitas penuh.
            _cleanupExpiredEntries(now);

            if (_clients.length >= config.maxEntries) {
              return ApiResponse.error(
                statusCode: 503,
                code: 'RATE_LIMIT_CAPACITY_EXHAUSTED',
                message: 'Kapasitas rate limit sedang penuh. Coba lagi nanti.',
                headers: {'Retry-After': '1'},
              );
            }
          }

          entry = _RateLimitEntry(windowStartedAt: now, window: window);
          _clients[key] = entry;
        } else if (!now.isBefore(entry.windowStartedAt.add(window))) {
          // Reset entry yang sama tanpa mengubah kapasitas map.
          entry.windowStartedAt = now;
          entry.requestCount = 0;
        }

        if (entry.requestCount >= maxRequests) {
          final resetAt = entry.windowStartedAt.add(window);
          final remaining = resetAt.difference(now).inSeconds;
          final retryAfter = remaining > 0 ? remaining : 1;

          return ApiResponse.error(
            statusCode: 429,
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Terlalu banyak request. Silakan coba lagi nanti.',
            headers: {
              'Retry-After': '$retryAfter',
              'X-RateLimit-Limit': '$maxRequests',
              'X-RateLimit-Remaining': '0',
              'X-RateLimit-Reset': '${resetAt.millisecondsSinceEpoch ~/ 1000}',
            },
          );
        }

        entry.requestCount++;

        final response = await innerHandler(request);
        final remaining = maxRequests - entry.requestCount;
        final resetAt = entry.windowStartedAt.add(window);

        return response.change(
          headers: {
            'X-RateLimit-Limit': '$maxRequests',
            'X-RateLimit-Remaining': '$remaining',
            'X-RateLimit-Reset': '${resetAt.millisecondsSinceEpoch ~/ 1000}',
          },
        );
      };
    };
  }

  String? _getClientIp(Request request) {
    final connectionInfo = request.context[_connectionInfoKey];

    if (connectionInfo is! HttpConnectionInfo) {
      return null;
    }

    final remoteIp = connectionInfo.remoteAddress.address;

    // Koneksi langsung bukan dari proxy tepercaya.
    // Jangan pernah mempercayai X-Forwarded-For dalam kondisi ini.
    if (!proxyConfig.trustedProxyIps.contains(remoteIp)) {
      return remoteIp;
    }

    final forwardedFor = request.headers['x-forwarded-for'];

    // Jika header tidak tersedia, gunakan IP koneksi langsung.
    if (forwardedFor == null || forwardedFor.trim().isEmpty) {
      return remoteIp;
    }

    // Batasi ukuran header sebelum melakukan parsing.
    if (forwardedFor.length > 1024) {
      return remoteIp;
    }

    final entries = forwardedFor.split(',');

    // Batasi jumlah hop dalam rantai proxy.
    if (entries.length > 10) {
      return remoteIp;
    }

    final forwardedIps = <String>[];

    // Seluruh entri harus berupa alamat IP yang valid.
    // Jika ada satu yang tidak valid, abaikan seluruh header.
    for (final entry in entries) {
      final address = InternetAddress.tryParse(entry.trim());

      if (address == null) {
        return remoteIp;
      }

      forwardedIps.add(address.address);
    }

    // Telusuri rantai dari kanan ke kiri.
    // Setiap hop yang dipercaya boleh menunjuk ke hop sebelumnya.
    var currentIp = remoteIp;

    for (var i = forwardedIps.length - 1; i >= 0; i--) {
      if (!proxyConfig.trustedProxyIps.contains(currentIp)) {
        break;
      }

      currentIp = forwardedIps[i];
    }

    // Jika seluruh rantai hanya berisi proxy tepercaya,
    // gunakan IP koneksi langsung sebagai fallback.
    if (proxyConfig.trustedProxyIps.contains(currentIp)) {
      return remoteIp;
    }

    return currentIp;
  }

  bool _isAuthRequest(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final normalizedPrefix = apiPrefix.replaceFirst(RegExp(r'/+$'), '');
    final authPrefix = '$normalizedPrefix/auth';

    return normalizedPath == authPrefix ||
        normalizedPath.startsWith('$authPrefix/');
  }

  void _cleanupExpiredEntriesIfDue(DateTime now) {
    final nextCleanupAt = _nextCleanupAt;

    if (nextCleanupAt != null && now.isBefore(nextCleanupAt)) {
      return;
    }

    _cleanupExpiredEntries(now);
    _nextCleanupAt = now.add(_cleanupInterval);
  }

  void _cleanupExpiredEntries(DateTime now) {
    _clients.removeWhere((key, entry) {
      return !now.isBefore(entry.windowStartedAt.add(entry.window));
    });
  }
}
