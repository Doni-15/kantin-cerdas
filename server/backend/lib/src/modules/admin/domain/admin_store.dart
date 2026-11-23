abstract interface class AdminStore {
  Future<Map<String, Object?>> getDashboard(String adminId);

  Future<Map<String, Object?>> listApplications(
    String adminId, {
    required String scope,
    required int limit,
    required int offset,
  });

  Future<Map<String, Object?>> getApplication(
    String adminId, {
    required String applicationId,
  });

  Future<Map<String, Object?>> reviewApplication(
    String adminId, {
    required String applicationId,
    required String decision,
    String? rejectionReason,
  });

  Future<Map<String, Object?>> listUsers(
    String adminId, {
    String? role,
    String? status,
    String? query,
    required int limit,
    required int offset,
  });

  Future<Map<String, Object?>> getUser(
    String adminId, {
    required String userId,
  });

  Future<Map<String, Object?>> setUserActiveStatus(
    String adminId, {
    required String targetUserId,
    required bool isActive,
    String? reason,
  });

  Future<Map<String, Object?>> listStalls(
    String adminId, {
    String? query,
    required int limit,
    required int offset,
  });

  Future<Map<String, Object?>> getStall(
    String adminId, {
    required String stallId,
  });

  Future<String?> getStallPhotoPath(String adminId, {required String stallId});

  Future<Map<String, Object?>> listActionLogs(
    String adminId, {
    String? targetUserId,
    required int limit,
    required int offset,
  });
}
