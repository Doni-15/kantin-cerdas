import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/user_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.dataSource);
  final AuthDataSource dataSource;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await dataSource.login(
      username: username,
      password: password,
    );

    return response.user.toEntity();
  }

  @override
  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await dataSource.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );

    return response.toEntity();
  }
}