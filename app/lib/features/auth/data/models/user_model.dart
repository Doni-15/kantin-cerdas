class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
  });

  /// String agar tahan terhadap Backend yang memakai int maupun UUID.
  final String id;
  final String username;
  final String email;
  final String name;
  final String role;
  final bool isActive;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // `as Object` melempar TypeError jika id null/hilang, lalu ditangani Repository.
      id: (json['id'] as Object).toString(),
      username: json['username'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
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
