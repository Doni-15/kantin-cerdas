import 'dart:typed_data';

import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

abstract interface class AdminRepository {
  Future<AdminDashboardSummary> fetchDashboard(AuthSession session);

  Future<List<AdminOwnerApplication>> listApplications(
    AuthSession session, {
    required String scope,
    int limit = 50,
    int offset = 0,
  });

  Future<AdminOwnerApplication> fetchApplication(
    AuthSession session, {
    required String applicationId,
  });

  Future<AdminOwnerApplication> reviewApplication(
    AuthSession session, {
    required String applicationId,
    required String decision,
    String? rejectionReason,
  });

  Future<List<AdminManagedUser>> listUsers(
    AuthSession session, {
    String? role,
    String? status,
    String query = '',
    int limit = 50,
    int offset = 0,
  });

  Future<AdminManagedUser> fetchUser(
    AuthSession session, {
    required String userId,
  });

  Future<AdminManagedUser> setUserActiveStatus(
    AuthSession session, {
    required String targetUserId,
    required bool isActive,
    String? reason,
  });

  Future<List<AdminStallSummary>> listStalls(
    AuthSession session, {
    String query = '',
    int limit = 50,
    int offset = 0,
  });

  Future<AdminStallSummary> fetchStall(
    AuthSession session, {
    required String stallId,
  });

  Future<Uint8List?> fetchStallPhoto(
    AuthSession session, {
    required String stallId,
  });

  Future<List<AdminActionLog>> listActionLogs(
    AuthSession session, {
    String? targetUserId,
    int limit = 50,
    int offset = 0,
  });
}
