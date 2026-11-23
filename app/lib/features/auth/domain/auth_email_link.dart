const androidEmailVerificationCallback =
    'id.kantincerdas.oauth://auth/verify-email';

enum AuthEmailAction { signup, recovery, emailChange }

class AuthEmailLink {
  // Prefer non-const construction when emitting links so Riverpod StreamProvider
  // does not deduplicate a link reopened after the link screen was closed.
  // ignore: prefer_const_constructors_in_immutables
  AuthEmailLink(
    this.action,
    this.tokenHash, {
    this.isCallback = false,
    bool? isInvalid,
  }) : isInvalid = isInvalid ?? (!isCallback && tokenHash == null);

  // ignore: prefer_const_constructors_in_immutables
  AuthEmailLink.callback({this.isInvalid = false})
    : action = AuthEmailAction.signup,
      tokenHash = null,
      isCallback = true;

  final AuthEmailAction action;
  final String? tokenHash;
  final bool isCallback;
  final bool isInvalid;

  static AuthEmailLink? parse(Uri uri, {String allowedHost = ''}) {
    if (uri.scheme == 'id.kantincerdas.oauth') {
      if (uri.host != 'auth' ||
          uri.path != '/verify-email' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort) {
        return null;
      }
      return _hasValidCallbackParameters(uri)
          ? AuthEmailLink.callback()
          : AuthEmailLink.callback(isInvalid: true);
    }
    if (allowedHost.isEmpty ||
        uri.scheme != 'https' ||
        uri.host != allowedHost ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment) {
      return null;
    }
    final action = switch (uri.path) {
      '/auth/verify-email' => AuthEmailAction.signup,
      '/auth/reset-password' => AuthEmailAction.recovery,
      '/auth/change-email' => AuthEmailAction.emailChange,
      _ => null,
    };
    if (action == null) return null;
    final List<String>? tokens;
    try {
      tokens = uri.queryParametersAll['token_hash'];
    } on FormatException {
      return AuthEmailLink(action, null);
    }
    final token = tokens?.length == 1 ? tokens!.single : null;
    return AuthEmailLink(
      action,
      token != null && RegExp(r'^[A-Za-z0-9_-]{32,256}$').hasMatch(token)
          ? token
          : null,
    );
  }

  static bool _hasValidCallbackParameters(Uri uri) {
    var seenType = false;
    for (final section in [uri.query, uri.fragment]) {
      if (section.isEmpty) continue;
      for (final pair in section.split('&')) {
        if (pair.isEmpty) return false;
        final separator = pair.indexOf('=');
        final rawKey = separator < 0 ? pair : pair.substring(0, separator);
        final rawValue = separator < 0 ? '' : pair.substring(separator + 1);
        final String key;
        try {
          key = Uri.decodeQueryComponent(rawKey);
          if (_isRedactedTokenKey(key)) {
            if (RegExp(
              r'%(?:[89A-Fa-f][0-9A-Fa-f]|(?![0-9A-Fa-f]{2}))',
            ).hasMatch(rawValue)) {
              return false;
            }
          } else {
            Uri.decodeQueryComponent(rawValue);
          }
        } on FormatException {
          return false;
        }
        if (key.isEmpty ||
            key == 'error' ||
            key == 'error_code' ||
            key == 'error_description' ||
            key == 'token_hash') {
          return false;
        }
        if (key == 'type') {
          if (seenType || Uri.decodeQueryComponent(rawValue) != 'signup') {
            return false;
          }
          seenType = true;
        }
      }
    }
    return true;
  }

  static bool _isRedactedTokenKey(String key) =>
      key == 'access_token' ||
      key == 'refresh_token' ||
      key == 'provider_token' ||
      key == 'provider_refresh_token';

  @override
  String toString() =>
      'AuthEmailLink(action: $action, isCallback: $isCallback, isInvalid: $isInvalid)';
}
