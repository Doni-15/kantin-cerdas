import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

extension UserModelMapper on UserModel {
  User toEntity() {
    final requiredFields = <String, String>{
      'id': id,
      'username': username,
      'email': email,
      'name': name,
    };

    for (final field in requiredFields.entries) {
      if (field.value.trim().isEmpty) {
        throw DataParsingException(
          'Required user field is empty: ${field.key}.',
        );
      }
    }

    final String? safeAvatarUrl;
    try {
      safeAvatarUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        avatarUrl,
        fieldName: 'avatar_url',
      );
    } on FormatException catch (error) {
      throw DataParsingException(error.message);
    }

    return User(
      id: id,
      username: username,
      email: email,
      name: name,
      role: _mapUserRole(role),
      isActive: isActive,
      avatarUrl: safeAvatarUrl,
    );
  }
}

UserRole _mapUserRole(String value) {
  final parsed = UserRole.tryFromRaw(value);
  if (parsed == null) {
    throw const DataParsingException('Unsupported user role.');
  }
  return parsed;
}
