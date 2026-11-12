import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';

/// TokenStorage di memori untuk test.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.stored]);

  AuthTokens? stored;
  int clearCount = 0;

  @override
  Future<AuthTokens?> read() async => stored;

  @override
  Future<void> save(AuthTokens tokens) async {
    stored = tokens;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    stored = null;
  }
}

/// Stub [AuthDataSource] berbasis [Fake].
///
/// Method yang tidak diberi callback otomatis melempar [UnimplementedError],
/// sehingga kalau interface [AuthDataSource] menambah method atau parameter
/// (misalnya `isEmailAvailable`, `avatarBytes`), file test tidak ikut gagal
/// dikompilasi. Hanya method yang benar-benar dipakai test yang ditulis di sini.
class StubAuthDataSource extends Fake implements AuthDataSource {
  StubAuthDataSource({
    this.onLogin,
    this.onRefreshSession,
    this.onIsEmailAvailable,
    this.onLogout,
    this.onChangePassword,
    this.onUpdateProfileAvatar,
  });

  final Future<LoginResponseModel> Function(String identifier, String password)?
  onLogin;
  final Future<LoginResponseModel> Function(String refreshToken)?
  onRefreshSession;
  final Future<bool> Function(String email)? onIsEmailAvailable;
  final Future<void> Function(String accessToken, String? refreshToken)?
  onLogout;
  final Future<void> Function(
    String accessToken,
    String currentPassword,
    String newPassword,
  )?
  onChangePassword;
  final Future<UserModel> Function(String accessToken, String? avatarUrl)?
  onUpdateProfileAvatar;

  @override
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  }) => onLogin!(identifier, password);

  @override
  Future<LoginResponseModel> refreshSession({required String refreshToken}) =>
      onRefreshSession!(refreshToken);

  @override
  Future<bool> isEmailAvailable({required String email}) =>
      onIsEmailAvailable!(email);

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) => onChangePassword!(accessToken, currentPassword, newPassword);

  @override
  Future<UserModel> updateProfileAvatar({
    required String accessToken,
    required String? avatarUrl,
  }) => onUpdateProfileAvatar!(accessToken, avatarUrl);

  @override
  Future<void> logout({required String accessToken, String? refreshToken}) =>
      onLogout?.call(accessToken, refreshToken) ?? Future<void>.value();
}
