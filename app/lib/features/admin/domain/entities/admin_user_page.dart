import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';

class AdminUserPage {
  AdminUserPage({required List<User> users, this.nextCursor})
    : users = List<User>.unmodifiable(users) {
    if (nextCursor != null && nextCursor!.trim().isEmpty) {
      throw ArgumentError('Cursor halaman tidak valid.');
    }
    if (this.users.map((user) => user.id).toSet().length != this.users.length) {
      throw ArgumentError('Daftar pengguna memuat ID duplikat.');
    }
  }

  final List<User> users;
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminUserPage &&
          other.nextCursor == nextCursor &&
          listEquals(other.users, users));

  @override
  int get hashCode => Object.hash(nextCursor, Object.hashAll(users));
}
