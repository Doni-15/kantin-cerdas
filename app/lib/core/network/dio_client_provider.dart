import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/network/auth_interceptor.dart';
import 'package:kantin_cerdas/core/session/auth_repository.dart';
import 'package:kantin_cerdas/core/session/auth_state_provider.dart';
import 'package:kantin_cerdas/core/session/token_storage.dart';

BaseOptions _createBaseOptions() {
  return BaseOptions(
    baseUrl: AppEnvironment.normalizedApiBaseUrl,
    connectTimeout: AppEnvironment.connectTimeout,
    receiveTimeout: AppEnvironment.receiveTimeout,
    sendTimeout: AppEnvironment.sendTimeout,
    headers: const <String, Object?>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );
}

/// Klien HTTP dasar tanpa AuthInterceptor untuk endpoint otentikasi langsung.
final baseDioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(_createBaseOptions());
  ref.onDispose(dio.close);
  return dio;
});

/// Klien HTTP utama dengan AuthInterceptor (single-flight refresh & 403 handler).
final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final tokenRefresher = ref.watch(authTokenRefresherProvider);

  final dio = Dio(_createBaseOptions());

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      onRefreshTokens: tokenRefresher,
      persistRefreshedTokens: false,
      onSessionInvalidated: ({required accountDisabled}) async {
        if (ref.mounted) {
          await ref
              .read(authStateProvider.notifier)
              .invalidateSession(accountDisabled: accountDisabled);
        }
      },
      retryDispatcher: dio.fetch<Object?>,
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});
