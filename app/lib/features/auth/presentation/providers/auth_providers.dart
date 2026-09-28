import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_dummy_datasource.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/login_usecase.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/register_usecase.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthDummyDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(
    ref.watch(authRepositoryProvider),
  );
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(
    ref.watch(authRepositoryProvider),
  );
});