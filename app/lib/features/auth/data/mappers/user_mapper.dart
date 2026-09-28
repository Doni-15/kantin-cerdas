import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

extension UserModelMapper on UserModel {
  User toEntity() {
    return User(
      id: id.toString(),
      username: username,
      email: email,
      name: name,
      role: _mapRole(role),
      isActive: isActive,
    );
  }

  UserRole _mapRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;

      case 'owner':
        return UserRole.owner;

      case 'customer':
        return UserRole.customer;

      default:
        throw Exception('Unknown user role: $role');
    }
  }
}