import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;

  /// Masa berlaku access token dalam detik.
  final int expiresIn;
  final UserModel user;

  factory LoginResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoginResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
    );
  }
}
