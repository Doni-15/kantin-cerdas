import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_json.dart';

const _requestTimeout = Duration(seconds: 25);
const _maxPhotoResponseBytes = 2 * 1024 * 1024;

/// Sends Shelf requests and decodes the HTTP response before model mapping.
class AuthApiTransport {
  AuthApiTransport({
    required this._client,
    required String baseUrl,
    required bool allowLocalHttp,
  }) : _allowLocalHttp = allowLocalHttp,
       _baseUrl = _parseBaseUrl(baseUrl, allowLocalHttp: allowLocalHttp);

  final http.Client _client;
  final bool _allowLocalHttp;
  final Uri? _baseUrl;

  bool get allowLocalHttp => _allowLocalHttp;

  String normalizeClientUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (!_allowLocalHttp || _baseUrl?.host != '10.0.2.2') {
      return trimmed;
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !{'127.0.0.1', 'localhost'}.contains(parsed.host)) {
      return trimmed;
    }
    return parsed.replace(host: '10.0.2.2').toString();
  }

  Future<Object?> request(
    String method,
    String endpoint, {
    Map<String, String>? body,
    Object? jsonBody,
    String? bearer,
    bool authEndpoint = true,
    bool photo = false,
    Uint8List? photoBody,
    String? photoMediaType,
    AuthException Function(int statusCode, Map<String, dynamic> envelope)?
    onEnvelopeError,
  }) async {
    final base = _baseUrl;
    if (base == null) {
      throw authNotConfiguredException;
    }
    final abort = Completer<void>();
    final request =
        http.AbortableRequest(
            method,
            base.resolve(authEndpoint ? 'v1/auth/$endpoint' : 'v1/$endpoint'),
            abortTrigger: abort.future,
          )
          ..followRedirects = false
          ..headers['accept'] = photo
              ? 'image/jpeg, application/json'
              : 'application/json';
    if (bearer != null) request.headers['authorization'] = 'Bearer $bearer';
    final payload = jsonBody ?? body;
    if (payload != null) {
      request.headers['content-type'] = 'application/json';
      request.bodyBytes = utf8.encode(jsonEncode(payload));
    }
    if (photoBody != null) {
      request.headers['content-type'] = photoMediaType!;
      request.bodyBytes = photoBody;
    }

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(
            _requestTimeout,
            onTimeout: () {
              abort.complete();
              throw _timedOut;
            },
          );
      final statusError = mapAuthStatusError(
        response.statusCode,
        endpoint: endpoint,
        bodyBytes: response.bodyBytes,
      );
      if (statusError != null) throw statusError;
      if (photo && response.statusCode == 204) return null;
      if (photo && response.statusCode == 200) {
        if (response.headers['content-type']?.split(';').first !=
                'image/jpeg' ||
            response.bodyBytes.isEmpty ||
            response.bodyBytes.length > _maxPhotoResponseBytes) {
          throw _badResponse;
        }
        return response.bodyBytes;
      }
      final envelope = authJsonObject(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          envelope['success'] == true &&
          envelope.containsKey('data')) {
        return envelope['data'];
      }
      throw (onEnvelopeError ?? mapAuthEnvelopeError)(
        response.statusCode,
        envelope,
      );
    } on TimeoutException {
      throw _timedOut;
    } on http.ClientException {
      throw _connectionFailed;
    } on FormatException {
      throw _badResponse;
    }
  }

  Future<({Stream<List<int>> stream, void Function() abort})> openStream(
    String endpoint, {
    required String bearer,
    String accept = 'text/event-stream',
  }) async {
    final base = _baseUrl;
    if (base == null) {
      throw authNotConfiguredException;
    }
    final abort = Completer<void>();
    void triggerAbort() {
      if (!abort.isCompleted) abort.complete();
    }

    final request =
        http.AbortableRequest(
            'GET',
            base.resolve('v1/$endpoint'),
            abortTrigger: abort.future,
          )
          ..followRedirects = false
          ..headers['accept'] = accept
          ..headers['authorization'] = 'Bearer $bearer';

    try {
      final response = await _client
          .send(request)
          .timeout(
            _requestTimeout,
            onTimeout: () {
              triggerAbort();
              throw _timedOut;
            },
          );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (stream: response.stream, abort: triggerAbort);
      }
      final bodyBytes = await response.stream.toBytes();
      final statusError = mapAuthStatusError(
        response.statusCode,
        endpoint: endpoint,
        bodyBytes: bodyBytes,
      );
      if (statusError != null) throw statusError;
      if (response.statusCode == 404) {
        throw const AuthException('ROUTE_NOT_FOUND', 'Route tidak tersedia.');
      }
      final envelope = authJsonObject(jsonDecode(utf8.decode(bodyBytes)));
      throw mapAuthEnvelopeError(response.statusCode, envelope);
    } on TimeoutException {
      triggerAbort();
      throw _timedOut;
    } on http.ClientException {
      triggerAbort();
      throw _connectionFailed;
    } on FormatException {
      triggerAbort();
      throw _badResponse;
    }
  }
}

Uri? _parseBaseUrl(String source, {required bool allowLocalHttp}) {
  final uri = Uri.tryParse(source.trim());
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  final local = {
    'localhost',
    '127.0.0.1',
    '::1',
    '10.0.2.2',
  }.contains(uri.host);
  if (uri.scheme != 'https' &&
      !(allowLocalHttp && local && uri.scheme == 'http')) {
    return null;
  }
  return uri.replace(path: uri.path.endsWith('/') ? uri.path : '${uri.path}/');
}

const _timedOut = authTimedOutException;
const _connectionFailed = authConnectionFailedException;
const _badResponse = authBadResponseException;
