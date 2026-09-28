import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String username;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
}