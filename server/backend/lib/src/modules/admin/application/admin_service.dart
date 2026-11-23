import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_store.dart';

typedef AdminMediaReader = Future<Uint8List?> Function(String objectPath);

class AdminService {
  const AdminService({required this.store, required this.readMedia});

  final AdminStore store;
  final AdminMediaReader readMedia;

  Future<Map<String, Object?>> getDashboard(String adminId) =>
      store.getDashboard(adminId);

  Future<Map<String, Object?>> listApplications(
    String adminId, {
    String scope = 'pending',
    int limit = 30,
    int offset = 0,
  }) => store.listApplications(
    adminId,
    scope: scope,
    limit: limit,
    offset: offset,
  );

  Future<Map<String, Object?>> getApplication(
    String adminId, {
    required String applicationId,
  }) => store.getApplication(adminId, applicationId: applicationId);

  Future<Map<String, Object?>> reviewApplication(
    String adminId, {
    required String applicationId,
    required String decision,
    String? rejectionReason,
  }) {
    final normalized = decision.trim().toLowerCase();
    if (normalized != 'disetujui' && normalized != 'ditolak') {
      throw const AdminFailure(AdminFailureCode.invalidInput);
    }
    final trimmedReason = rejectionReason?.trim();
    if (normalized == 'ditolak' &&
        (trimmedReason == null || trimmedReason.isEmpty)) {
      throw const AdminFailure(AdminFailureCode.reasonRequired);
    }
    return store.reviewApplication(
      adminId,
      applicationId: applicationId,
      decision: normalized,
      rejectionReason: trimmedReason,
    );
  }

  Future<Map<String, Object?>> listUsers(
    String adminId, {
    String? role,
    String? status,
    String? query,
    int limit = 30,
    int offset = 0,
  }) => store.listUsers(
    adminId,
    role: role,
    status: status,
    query: query,
    limit: limit,
    offset: offset,
  );

  Future<Map<String, Object?>> getUser(
    String adminId, {
    required String userId,
  }) => store.getUser(adminId, userId: userId);

  Future<Map<String, Object?>> setUserActiveStatus(
    String adminId, {
    required String targetUserId,
    required bool isActive,
    String? reason,
  }) {
    final trimmedReason = reason?.trim();
    if (!isActive) {
      if (trimmedReason == null || trimmedReason.isEmpty) {
        throw const AdminFailure(AdminFailureCode.reasonRequired);
      }
      if (adminId == targetUserId) {
        throw const AdminFailure(AdminFailureCode.selfDeactivationNotAllowed);
      }
    }
    return store.setUserActiveStatus(
      adminId,
      targetUserId: targetUserId,
      isActive: isActive,
      reason: trimmedReason,
    );
  }

  Future<Map<String, Object?>> listStalls(
    String adminId, {
    String? query,
    int limit = 30,
    int offset = 0,
  }) => store.listStalls(adminId, query: query, limit: limit, offset: offset);

  Future<Map<String, Object?>> getStall(
    String adminId, {
    required String stallId,
  }) => store.getStall(adminId, stallId: stallId);

  Future<Uint8List?> readStallPhoto(
    String adminId, {
    required String stallId,
  }) async {
    final path = await store.getStallPhotoPath(adminId, stallId: stallId);
    if (path == null || path.trim().isEmpty) return null;
    return readMedia(path);
  }

  Future<Map<String, Object?>> listActionLogs(
    String adminId, {
    String? targetUserId,
    int limit = 30,
    int offset = 0,
  }) => store.listActionLogs(
    adminId,
    targetUserId: targetUserId,
    limit: limit,
    offset: offset,
  );
}
