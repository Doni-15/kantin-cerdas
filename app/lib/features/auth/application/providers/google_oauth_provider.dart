import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_browser_io.dart'
    if (dart.library.js_interop) 'package:kantin_cerdas/features/auth/data/oauth/google_browser_web.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth.dart';

final googleOAuthProvider = Provider<GoogleOAuthFlow?>((ref) {
  const enabled = bool.fromEnvironment(
    'AUTH_GOOGLE_ENABLED',
    defaultValue: true,
  );
  const configured = String.fromEnvironment('SUPABASE_URL');

  if (!enabled) return null;

  final flow = GoogleOAuthFlow(
    supabaseUrl: configured,
    browser: openGoogleBrowser,
    allowLocalHttp: kDebugMode,
    verifyBackendProject: true,
  );

  ref.onDispose(flow.cancel);
  return flow;
});
