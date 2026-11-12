import 'package:characters/characters.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';

class AdminUserAccessChange {
  AdminUserAccessChange({
    required this.userId,
    required this.expectedVersion,
    required this.isActive,
    required String reason,
  }) : reason = reason.trim() {
    if (userId.trim().isEmpty ||
        expectedVersion < 1 ||
        !validReason(this.reason)) {
      throw ArgumentError('Perubahan akses pengguna tidak valid.');
    }
  }
  static const maxReasonLength = 300;
  static bool validReason(String? value) =>
      value != null &&
      value.trim().isNotEmpty &&
      value.trim().characters.length <= maxReasonLength;
  final String userId;
  final int expectedVersion;
  final bool isActive;
  final String reason;

  bool acceptsResult({
    required AdminUserRecord before,
    required AdminUserRecord after,
    required String actorId,
  }) =>
      canApplyTo(before, actorId: actorId) &&
      after.user.id == userId &&
      after.version > expectedVersion &&
      after.user.isActive == isActive &&
      after.user.role == before.user.role &&
      after.user.name == before.user.name &&
      after.user.username == before.user.username &&
      after.user.email == before.user.email;

  bool canApplyTo(AdminUserRecord record, {required String actorId}) =>
      record.canManage(actorId) &&
      record.user.id == userId &&
      record.version == expectedVersion &&
      record.user.isActive != isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminUserAccessChange &&
          other.userId == userId &&
          other.expectedVersion == expectedVersion &&
          other.isActive == isActive &&
          other.reason == reason);

  @override
  int get hashCode => Object.hash(userId, expectedVersion, isActive, reason);
}
