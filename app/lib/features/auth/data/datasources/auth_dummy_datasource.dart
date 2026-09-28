import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';

class AuthDummyDataSource implements AuthDataSource {
  final List<UserModel> _users = [
    const UserModel(
      id: 3,
      username: 'customer',
      email: 'customer@kantincerdas.com',
      name: 'Andi (Customer)',
      role: 'customer',
      isActive: true,
    ),
    
    const UserModel(
      id: 2,
      username: 'owner',
      email: 'pemilik@kantincerdas.com',
      name: 'Budi (Pemilik Kantin)',
      role: 'owner',
      isActive: true,
    ),

    const UserModel(
      id: 1,
      username: 'admin',
      email: 'admin@kantincerdas.com',
      name: 'Doni (Admin)',
      role: 'admin',
      isActive: true,
    ),
  ];

  @override
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) async {
    // Simulasi jeda jaringan.
    await Future<void>.delayed(
      const Duration(seconds: 1),
    );

    // Password dummy dibuat sama untuk mempermudah testing.
    if (password != '123456') {
      throw Exception('Username atau password salah');
    }

    final user = _users.cast<UserModel?>().firstWhere(
      (user) => user?.username.toLowerCase() == username.toLowerCase(),
      orElse: () => null,
    );

    if (user == null || !user.isActive) {
      throw Exception('Username atau password salah');
    }

    return LoginResponseModel(
      accessToken: 'dummy-access-token-${user.username}',
      refreshToken: 'dummy-refresh-token-${user.username}',
      user: user,
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    // Simulasi jeda jaringan.
    await Future<void>.delayed(
      const Duration(seconds: 1),
    );

    // Cek username sudah digunakan atau belum.
    final usernameExists = _users.any(
      (user) => user.username.toLowerCase() == username.toLowerCase(),
    );

    if (usernameExists) {
      throw Exception('Username sudah digunakan');
    }

    // Cek email sudah terdaftar atau belum.
    final emailExists = _users.any(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
    );

    if (emailExists) {
      throw Exception('Email sudah terdaftar');
    }

    // User yang mendaftar secara publik otomatis menjadi customer.
    final user = UserModel(
      id: _generateUserId(),
      username: username,
      email: email,
      name: name,
      role: 'customer',
      isActive: true,
    );

    _users.add(user);

    return user;
  }

  int _generateUserId() {
    if (_users.isEmpty) {
      return 1;
    }

    return _users
      .map((user) => user.id)
      .reduce((current, next) => current > next ? current : next) 
      + 1;
  }
}