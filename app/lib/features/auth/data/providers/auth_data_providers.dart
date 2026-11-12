import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/network/dio_client_provider.dart';
import 'package:kantin_cerdas/core/session/token_storage.dart';
import 'package:kantin_cerdas/core/storage/secure_storage_provider.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/secure_token_storage.dart';

export 'package:kantin_cerdas/core/session/auth_repository.dart'
    show authRepositoryProvider, authTokenRefresherProvider;
export 'package:kantin_cerdas/core/session/token_storage.dart'
    show tokenStorageProvider;

final secureTokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage(storage: ref.watch(secureStorageProvider));
});

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthApiDataSource(dio: ref.watch(baseDioClientProvider));
});

final authRepositoryImplProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(authDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
