import 'package:kantin_cerdas/core/session/user_role.dart';

class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
  final String? avatarUrl;

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    UserRole? role,
    bool? isActive,
    String? avatarUrl,
    bool clearAvatarUrl = false,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.username == username &&
          other.email == email &&
          other.name == name &&
          other.role == role &&
          other.isActive == isActive &&
          other.avatarUrl == avatarUrl);

  @override
  int get hashCode =>
      Object.hash(id, username, email, name, role, isActive, avatarUrl);
}
