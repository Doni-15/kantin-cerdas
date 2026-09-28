import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';

abstract interface class AuthDataSource {
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });
}