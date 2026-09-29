import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

extension UserModelMapper on UserModel {
  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      name: name,
      role: _mapRole(role),
      isActive: isActive,
    );
  }

  UserRole _mapRole(String value) {
    final normalized = value.trim().toLowerCase();

    for (final role in UserRole.values) {
      if (role.name == normalized) {
        return role;
      }
    }

    throw DataParsingException('Unknown user role: $value');
  }
}
