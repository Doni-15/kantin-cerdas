import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<User> login({
    required String username,
    required String password,
  });

  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });
}