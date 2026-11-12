import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.expiresAt,
  });

  factory LoginResponseModel.fromJson(Map<String, Object?> json) {
    final rawToken =
        json['access_token'] ?? json['accessToken'] ?? json['token'];
    if (rawToken is! String || rawToken.trim().isEmpty) {
      throw const DataParsingException(
        'Token akses tidak ditemukan atau kosong pada respons login.',
      );
    }

    final rawRefresh = json['refresh_token'] ?? json['refreshToken'];
    if (rawRefresh != null &&
        (rawRefresh is! String || rawRefresh.trim().isEmpty)) {
      throw const DataParsingException('Format refresh token tidak valid.');
    }

    final expiresAtRaw = json['expires_at'] ?? json['expiresAt'];
    DateTime? expiresAt;
    if (expiresAtRaw != null) {
      expiresAt = parseStrictUtcDateTime(expiresAtRaw, fieldName: 'expires_at');
    }

    final rawUser = asJsonMap(json['user'], fieldName: 'user');

    return LoginResponseModel(
      accessToken: rawToken.trim(),
      refreshToken: (rawRefresh as String?)?.trim(),
      expiresAt: expiresAt,
      user: UserModel.fromJson(rawUser),
    );
  }

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final UserModel user;
}
