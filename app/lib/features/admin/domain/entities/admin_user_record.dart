import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

/// Snapshot khusus administrasi. Versi wajib berasal dari server,
/// bukan nilai default pada entitas sesi login.
class AdminUserRecord {
  AdminUserRecord({required this.user, required this.version}) {
    if (version < 1 ||
        [
          user.id,
          user.name,
          user.username,
          user.email,
        ].any((value) => value.trim().isEmpty)) {
      throw ArgumentError('Data pengguna tidak valid.');
    }
  }
  final User user;
  final int version;

  bool canManage(String actorId) =>
      actorId.trim().isNotEmpty &&
      actorId != user.id &&
      user.role != UserRole.admin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminUserRecord &&
          other.user == user &&
          other.version == version);

  @override
  int get hashCode => Object.hash(user, version);
}
