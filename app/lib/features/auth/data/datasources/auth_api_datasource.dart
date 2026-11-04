import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';

class AuthApiDataSource implements AuthDataSource {
  const AuthApiDataSource({this.dio});

  final Dio? dio;

  bool get isConfigured => dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/auth/login',
        data: <String, Object?>{'identifier': identifier, 'password': password},
      );
      return LoginResponseModel.fromJson(
        asJsonMap(response.data, fieldName: 'login'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/auth/register',
        data: <String, Object?>{
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return UserModel.fromJson(
        asJsonMap(response.data, fieldName: 'register'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      await client.post<Object?>(
        '/v1/auth/password-reset',
        data: <String, Object?>{'email': email},
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<UserModel> getCurrentUser({required String accessToken}) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/auth/me',
        options: Options(
          headers: <String, Object?>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      return UserModel.fromJson(asJsonMap(response.data, fieldName: 'me'));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<LoginResponseModel> refreshSession({
    required String refreshToken,
  }) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/auth/refresh',
        data: <String, Object?>{'refresh_token': refreshToken},
      );
      return LoginResponseModel.fromJson(
        asJsonMap(response.data, fieldName: 'refresh'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      await client.post<Object?>(
        '/v1/auth/change-password',
        data: <String, Object?>{
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(
          headers: <String, Object?>{'Authorization': 'Bearer $accessToken'},
        ),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<UserModel> updateProfileAvatar({
    required String accessToken,
    required String? avatarUrl,
  }) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      final response = await client.put<Object?>(
        '/v1/auth/profile/avatar',
        data: <String, Object?>{'avatar_url': avatarUrl},
        options: Options(
          headers: <String, Object?>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      return UserModel.fromJson(
        asJsonMap(response.data, fieldName: 'profile_avatar'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> logout({
    required String accessToken,
    String? refreshToken,
  }) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const AuthNotConfiguredFailure();
    }
    try {
      await client.post<Object?>(
        '/v1/auth/logout',
        data: <String, Object?>{'refresh_token': ?refreshToken},
        options: Options(
          headers: <String, Object?>{'Authorization': 'Bearer $accessToken'},
        ),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
