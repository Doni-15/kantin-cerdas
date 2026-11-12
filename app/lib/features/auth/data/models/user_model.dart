import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final username = json['username'];
    final email = json['email'];
    final name = json['name'] ?? json['full_name'] ?? json['fullName'];
    final role = json['role'];
    final isActive = json['is_active'] ?? json['isActive'];
    final rawAvatarUrl = normalizeOptionalText(
      json['avatar_url'] ?? json['avatarUrl'],
      fieldName: 'avatar_url',
    );

    if (id is! String ||
        username is! String ||
        email is! String ||
        name is! String ||
        role is! String ||
        isActive is! bool) {
      throw const DataParsingException('Format data pengguna tidak valid.');
    }

    final String? safeAvatarUrl;
    try {
      safeAvatarUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        rawAvatarUrl,
        fieldName: 'avatar_url',
      );
    } on FormatException catch (error) {
      throw DataParsingException(error.message);
    }

    return UserModel(
      id: id,
      username: username,
      email: email,
      name: name,
      role: role,
      isActive: isActive,
      avatarUrl: safeAvatarUrl,
    );
  }

  final String id;
  final String username;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final String? avatarUrl;
}
