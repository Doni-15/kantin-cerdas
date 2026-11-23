import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/data/session/auth_session_store.dart';
import 'package:kantin_cerdas/features/auth/data/session/web_session_lock_stub.dart'
    if (dart.library.js_interop) 'package:kantin_cerdas/features/auth/data/session/web_session_lock.dart'
    as browser;

const _apiBase = String.fromEnvironment('API_BASE_URL');

String resolvedAuthApiBaseUrl() {
  final configured = _apiBase.trim();
  if (configured.isNotEmpty) return configured;
  if (!kDebugMode || kIsWeb) return '';
  return defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8080'
      : 'http://127.0.0.1:8080';
}

final sessionStoreProvider = Provider<SessionStore>((ref) {
  if (kIsWeb) return MemorySessionStore();
  return SecureSessionStore(
    const FlutterSecureStorage(),
    authSessionStorageKey(resolvedAuthApiBaseUrl()),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return AuthRepository(
    client: client,
    store: ref.watch(sessionStoreProvider),
    baseUrl: kIsWeb ? _sameOriginApiBase() : resolvedAuthApiBaseUrl(),
    allowLocalHttp: kDebugMode,
    cookieSessions: kIsWeb,
    cookieLock: kIsWeb ? browser.runWebSessionLock : null,
  );
});

String _sameOriginApiBase() {
  final page = Uri.base;
  if (page.scheme != 'https' && page.scheme != 'http') return '';
  if (_apiBase.trim().isEmpty) return page.origin;

  final configured = Uri.tryParse(_apiBase.trim());

  if (configured == null ||
      configured.scheme != page.scheme ||
      configured.host != page.host ||
      configured.port != page.port ||
      configured.userInfo.isNotEmpty ||
      (configured.path.isNotEmpty && configured.path != '/') ||
      configured.hasQuery ||
      configured.hasFragment) {
    return '';
  }
  return configured.origin;
}
