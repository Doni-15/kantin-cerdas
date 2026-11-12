/// Identitas pengguna terautentikasi yang ditempelkan ke konteks request.
final class AuthenticatedActor {
  final String id;
  final String authUid;
  final String username;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final int sessionEpoch;
  final int version;
  final String? avatarUrl;

  const AuthenticatedActor({
    required this.id,
    required this.authUid,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.sessionEpoch,
    required this.version,
    required this.avatarUrl,
  });

  factory AuthenticatedActor.fromRow(Map<String, Object?> row) {
    return AuthenticatedActor(
      id: row['id'] as String,
      authUid: row['auth_uid'].toString(),
      username: row['username'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      role: row['role'] as String,
      isActive: row['is_active'] as bool,
      sessionEpoch: (row['session_epoch'] as num?)?.toInt() ?? 1,
      version: (row['version'] as num?)?.toInt() ?? 1,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  Map<String, Object?> toUserJson() => <String, Object?>{
    'id': id,
    'username': username,
    'email': email,
    'name': name,
    'role': role,
    'is_active': isActive,
    'avatar_url': avatarUrl,
  };
}