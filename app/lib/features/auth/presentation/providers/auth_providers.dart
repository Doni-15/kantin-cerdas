import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_dummy_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/persistent_token_storage.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/login_usecase.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/register_usecase.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/restore_session_usecase.dart';

/// Pilih sumber data tanpa mengubah kode:
///   flutter run                                  -> dummy (default)
///   flutter run --dart-define=USE_DUMMY=false    -> API (setelah AuthApiDataSource dibuat)
const _useDummy = bool.fromEnvironment('USE_DUMMY', defaultValue: true);

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  if (_useDummy) {
    return AuthDummyDataSource(storage: ref.watch(localStorageProvider));
  }

  throw UnimplementedError(
    'AuthApiDataSource belum dibuat. Jalankan dengan USE_DUMMY=true '
    'atau buat AuthApiDataSource lalu daftarkan di sini.',
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return PersistentTokenStorage(ref.watch(localStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(authDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});
