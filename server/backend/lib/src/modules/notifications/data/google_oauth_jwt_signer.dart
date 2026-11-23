import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/modules/notifications/data/rsa_sha256_crypto.dart';

export 'package:kantin_cerdas_backend/src/modules/notifications/data/rsa_sha256_crypto.dart'
    show RsaPrivateKeyMaterial, sha256Digest;

/// Pure-Dart RSASSA-PKCS1-v1_5 + SHA-256 JWT assertion signer for Google OAuth2 / FCM HTTP v1.
class GoogleServiceAccountJwtSigner {
  const GoogleServiceAccountJwtSigner({
    required this.clientEmail,
    required this.privateKey,
    required this.tokenUri,
    this.scope = 'https://www.googleapis.com/auth/firebase.messaging',
  });

  final String clientEmail;
  final RsaPrivateKeyMaterial privateKey;
  final String tokenUri;
  final String scope;

  String createSignedAssertion({DateTime? now}) {
    final issuedAt =
        (now ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final expiresAt = issuedAt + 3600;
    final header = _base64UrlNoPad(
      utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'})),
    );
    final claims = _base64UrlNoPad(
      utf8.encode(
        jsonEncode({
          'iss': clientEmail,
          'scope': scope,
          'aud': tokenUri,
          'iat': issuedAt,
          'exp': expiresAt,
        }),
      ),
    );
    final signingInput = '$header.$claims';
    final signature = signRs256(
      Uint8List.fromList(utf8.encode(signingInput)),
      privateKey,
    );
    return '$signingInput.${_base64UrlNoPad(signature)}';
  }

  static Uint8List signRs256(Uint8List message, RsaPrivateKeyMaterial key) =>
      signRs256Bytes(message, key);
}

/// Exchanges a signed RS256 service-account JWT for a short-lived Google OAuth2 bearer token.
class GoogleOAuth2TokenProvider {
  GoogleOAuth2TokenProvider({
    required this.clientEmail,
    required this.privateKeyPem,
    required this.tokenUri,
    required this._httpClient,
    this.timeout = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? _utcNow;

  final String clientEmail;
  final String privateKeyPem;
  final String tokenUri;
  final http.Client _httpClient;
  final Duration timeout;
  final DateTime Function() _clock;

  RsaPrivateKeyMaterial? _parsedKey;
  String? _cachedToken;
  DateTime? _cachedExpiresAt;

  Future<String> getAccessToken() async {
    final now = _clock();
    final existing = _cachedToken;
    final expiresAt = _cachedExpiresAt;
    if (existing != null &&
        expiresAt != null &&
        now.isBefore(expiresAt.subtract(const Duration(seconds: 60)))) {
      return existing;
    }

    final key = _parsedKey ??= RsaPrivateKeyMaterial.fromPem(privateKeyPem);
    final signer = GoogleServiceAccountJwtSigner(
      clientEmail: clientEmail,
      privateKey: key,
      tokenUri: tokenUri,
    );
    final assertion = signer.createSignedAssertion(now: now);

    final response = await _httpClient
        .post(
          Uri.parse(tokenUri),
          headers: const {'content-type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion': assertion,
          },
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw StateError('OAUTH_TOKEN_HTTP_${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid OAuth2 token response.');
    }
    final accessToken = (decoded['access_token'] as String?)?.trim() ?? '';
    final expiresIn = (decoded['expires_in'] as num?)?.toInt() ?? 3600;
    if (accessToken.isEmpty) {
      throw const FormatException('Missing access_token in OAuth2 response.');
    }
    _cachedToken = accessToken;
    _cachedExpiresAt = now.add(Duration(seconds: expiresIn));
    return accessToken;
  }

  void invalidateCache() {
    _cachedToken = null;
    _cachedExpiresAt = null;
  }
}

DateTime _utcNow() => DateTime.now().toUtc();

String _base64UrlNoPad(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');
