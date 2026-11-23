import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

typedef GoogleBrowser =
    Future<Uri> Function({
      required Uri Function(Uri) authorize,
      required String state,
      required Future<void> cancelled,
    });

const mobileGoogleRedirect = 'id.kantincerdas.oauth://auth/google';
const googleCallbackState = 'kc_state';
const googleRedirectTimeout = Duration(minutes: 3);

bool matchesGoogleRedirect(Uri expected, Uri received, String state) {
  final List<String>? returnedState;
  try {
    returnedState = received.queryParametersAll[googleCallbackState];
  } on FormatException {
    return false;
  }
  return received.scheme == expected.scheme &&
      received.host == expected.host &&
      received.port == expected.port &&
      received.path == expected.path &&
      received.userInfo.isEmpty &&
      returnedState != null &&
      returnedState.length == 1 &&
      returnedState.single == state;
}

const googleCancelled = AuthException(
  'GOOGLE_CANCELLED',
  'Masuk dengan Google dibatalkan.',
);
const googleTimedOut = AuthException(
  'GOOGLE_TIMEOUT',
  'Waktu masuk Google habis. Coba lagi.',
);
const googleBrowserUnavailable = AuthException(
  'GOOGLE_BROWSER_UNAVAILABLE',
  'Browser tidak bisa dibuka. Periksa pengaturan browser lalu coba lagi.',
);
