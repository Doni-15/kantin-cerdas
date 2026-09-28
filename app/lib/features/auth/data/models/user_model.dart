class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
  });

  final int id;
  final String username;
  final String email;
  final String name;
  final String role;
  final bool isActive;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role,
      'is_active': isActive,
    };
  }
}