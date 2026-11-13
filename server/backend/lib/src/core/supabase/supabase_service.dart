import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:supabase/supabase.dart';

final class SupabaseService {
  final SupabaseConfig config;
  final http.Client _sharedHttpClient;
  late final SupabaseClient adminClient;

  SupabaseService(
    this.config, {
    http.Client? httpClient,
  }) : 
  _sharedHttpClient = httpClient ?? http.Client() {
    adminClient = SupabaseClient(
      config.url,
      config.secretKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
      ),
      httpClient: _TimeoutHttpClient(
        _sharedHttpClient,
        Duration(seconds: config.requestTimeoutSeconds),
        config.maxRetries,
      ),
    );
  }

  /// Client berbasis publishable key untuk alur Auth atas nama pengguna
  /// (sign-in, refresh, reset password). Seluruh akses data memakai
  /// [adminClient] (service role) dengan otorisasi eksplisit di backend + RPC;
  /// tidak ada jalur PostgREST atas nama pengguna (RLS tidak memiliki policy).
  SupabaseClient createStatelessAuthClient() {
    return SupabaseClient(
      config.url,
      config.publishableKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
      ),
      httpClient: _TimeoutHttpClient(
        _sharedHttpClient,
        Duration(seconds: config.requestTimeoutSeconds),
        config.maxRetries,
      ),
    );
  }

  Future<void> dispose() async {
    await adminClient.dispose();
    _sharedHttpClient.close();
  }
}

final class _TimeoutHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Duration _timeout;
  final int _maxRetries;

  _TimeoutHttpClient(this._inner, this._timeout, this._maxRetries);
  static const _retryableStatus = {502, 503, 504};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final canRetry = _maxRetries > 0 &&
       request is http.Request &&
       (request.method == 'GET' || request.method == 'HEAD');

    var attempt = 0;
    while (true) {
      final toSend = attempt == 0 ? request : _copy(request as http.Request);
      try {
        final response = await _inner.send(toSend).timeout(_timeout);

        if (canRetry && attempt < _maxRetries && _retryableStatus.contains(response.statusCode)) {
          await response.stream.drain<void>();
          attempt++;
          await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
          continue;
        }

        return response;
      } 
      on TimeoutException {
        if (!canRetry || attempt >= _maxRetries) rethrow;
      } 
      on SocketException {
        if (!canRetry || attempt >= _maxRetries) rethrow;
      }
      attempt++;
      await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
    }
  }

  http.Request _copy(http.Request r) => http.Request(r.method, r.url)
    ..headers.addAll(r.headers)
    ..followRedirects = r.followRedirects
    ..maxRedirects = r.maxRedirects
    ..persistentConnection = r.persistentConnection;

  @override
  void close() {}
}