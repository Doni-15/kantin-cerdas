import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth_protocol.dart';

// Number of random bytes behind the PKCE verifier and the callback state.
const _pkceVerifierLength = 32;
const _callbackStateLength = 32;

const _loopbackHosts = {'localhost', '127.0.0.1', '::1', '10.0.2.2'};

Uri? parseGoogleProjectUrl(String supabaseUrl, {bool allowLocalHttp = false}) {
  final project = Uri.tryParse(supabaseUrl.trim());
  if (project == null ||
      project.host.isEmpty ||
      project.userInfo.isNotEmpty ||
      (project.path.isNotEmpty && project.path != '/') ||
      project.hasQuery ||
      project.hasFragment) {
    return null;
  }
  final isCloud =
      project.scheme == 'https' &&
      RegExp(r'^[a-z0-9]{20}\.supabase\.co$').hasMatch(project.host) &&
      !project.hasPort;
  if (isCloud) return project;

  final isLocal =
      allowLocalHttp &&
      {'http', 'https'}.contains(project.scheme) &&
      _loopbackHosts.contains(project.host);
  if (isLocal) return project;

  return null;
}

bool sameGoogleSupabaseOrigin(
  Uri first,
  Uri second, {
  bool allowLocalHttp = false,
}) {
  if (first.origin == second.origin) return true;
  if (allowLocalHttp &&
      first.scheme == second.scheme &&
      _loopbackHosts.contains(first.host) &&
      _loopbackHosts.contains(second.host) &&
      first.port == second.port) {
    return true;
  }
  return false;
}

class GoogleOAuthFlow {
  GoogleOAuthFlow({
    required String supabaseUrl,
    required this._browser,
    this.allowLocalHttp = false,
    this.verifyBackendProject = false,
  }) : _configuredUrl = supabaseUrl.trim(),
       _project = parseGoogleProjectUrl(
         supabaseUrl,
         allowLocalHttp: allowLocalHttp,
       );

  final String _configuredUrl;
  final Uri? _project;
  final GoogleBrowser _browser;
  final bool allowLocalHttp;
  final bool verifyBackendProject;
  Completer<void>? _cancel;

  String get configuredUrl => _configuredUrl;
  bool get hasConfiguredUrl => _configuredUrl.isNotEmpty;
  Uri? get projectUrl => _project;

  void cancel() {
    final active = _cancel;
    if (active != null && !active.isCompleted) active.complete();
  }

  Future<({String code, String verifier})> requestCode({
    String? supabaseUrl,
  }) async {
    final project = supabaseUrl != null
        ? parseGoogleProjectUrl(supabaseUrl, allowLocalHttp: allowLocalHttp)
        : _project;
    if (project == null) {
      throw authGoogleConfigException;
    }
    if (_cancel != null) {
      throw const AuthException(
        'GOOGLE_BUSY',
        'Masuk dengan Google sedang berlangsung.',
      );
    }

    final operation = Completer<void>();
    _cancel = operation;
    final random = Random.secure();
    final verifier = _randomParameter(random, _pkceVerifierLength);
    final state = _randomParameter(random, _callbackStateLength);
    final challenge = _base64Url(sha256.convert(ascii.encode(verifier)).bytes);
    Uri? expected;
    try {
      final returned = await _browser(
        authorize: (callback) {
          expected = callback;
          return project.replace(
            path: '/auth/v1/authorize',
            queryParameters: {
              'provider': 'google',
              'redirect_to': callback
                  .replace(queryParameters: {googleCallbackState: state})
                  .toString(),
              'code_challenge': challenge,
              'code_challenge_method': 's256',
            },
          );
        },
        state: state,
        cancelled: operation.future,
      );
      if (operation.isCompleted) throw googleCancelled;
      final redirect = expected;
      if (redirect == null ||
          !matchesGoogleRedirect(redirect, returned, state)) {
        throw const AuthException(
          'GOOGLE_CALLBACK',
          'Balasan Google tidak dapat diverifikasi. Coba lagi.',
        );
      }
      final parameters = returned.queryParametersAll;
      final errors = returned.hasFragment && returned.fragment.isNotEmpty
          ? Uri.splitQueryString(returned.fragment)
          : const <String, String>{};
      if (parameters['error']?.contains('access_denied') == true ||
          errors['error'] == 'access_denied') {
        throw googleCancelled;
      }
      final hasDisallowedFragment = errors.keys.any((key) => key != 'sb');
      final codes = parameters['code'];
      if (hasDisallowedFragment ||
          parameters.containsKey('error') ||
          parameters.containsKey('error_code') ||
          parameters.containsKey('error_description') ||
          codes == null ||
          codes.length != 1 ||
          !RegExp(r'^[!-~]{1,512}$').hasMatch(codes.single)) {
        throw const AuthException(
          'GOOGLE_CALLBACK',
          'Google belum menyelesaikan proses masuk. Coba lagi.',
        );
      }
      return (code: codes.single, verifier: verifier);
    } on TimeoutException {
      throw googleTimedOut;
    } on FormatException {
      throw const AuthException(
        'GOOGLE_CALLBACK',
        'Balasan Google tidak dapat dibaca. Coba lagi.',
      );
    } finally {
      _cancel = null;
    }
  }
}

String _randomParameter(Random random, int length) =>
    _base64Url(List.generate(length, (_) => random.nextInt(256)));

String _base64Url(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');
