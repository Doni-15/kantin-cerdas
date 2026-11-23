import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/data/admin_api_repository.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_repository.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';

typedef AdminApplicationsQuery = ({String accountId, String scope});
typedef AdminApplicationKey = ({String accountId, String applicationId});
typedef AdminUsersQuery = ({
  String accountId,
  String? role,
  String? status,
  String query,
});
typedef AdminUserKey = ({String accountId, String userId});
typedef AdminStallsQuery = ({String accountId, String query});
typedef AdminStallKey = ({String accountId, String stallId});
typedef AdminActionLogsKey = ({String accountId, String? targetUserId});

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminApiRepository(ref.watch(authRepositoryProvider)),
);

final adminDashboardProvider = FutureProvider.autoDispose
    .family<AdminDashboardSummary, String>((ref, accountId) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      return ref.watch(adminRepositoryProvider).fetchDashboard(session);
    }, retry: (_, _) => null);

final adminApplicationsProvider = FutureProvider.autoDispose
    .family<List<AdminOwnerApplication>, AdminApplicationsQuery>((ref, query) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        query.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .listApplications(session, scope: query.scope);
    }, retry: (_, _) => null);

final adminApplicationDetailProvider = FutureProvider.autoDispose
    .family<AdminOwnerApplication, AdminApplicationKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .fetchApplication(session, applicationId: key.applicationId);
    }, retry: (_, _) => null);

final adminUsersProvider = FutureProvider.autoDispose
    .family<List<AdminManagedUser>, AdminUsersQuery>((ref, query) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        query.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .listUsers(
            session,
            role: query.role,
            status: query.status,
            query: query.query,
          );
    }, retry: (_, _) => null);

final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminManagedUser, AdminUserKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .fetchUser(session, userId: key.userId);
    }, retry: (_, _) => null);

final adminStallsProvider = FutureProvider.autoDispose
    .family<List<AdminStallSummary>, AdminStallsQuery>((ref, query) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        query.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .listStalls(session, query: query.query);
    }, retry: (_, _) => null);

final adminStallDetailProvider = FutureProvider.autoDispose
    .family<AdminStallSummary, AdminStallKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .fetchStall(session, stallId: key.stallId);
    }, retry: (_, _) => null);

final adminStallPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, AdminStallKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .fetchStallPhoto(session, stallId: key.stallId);
    }, retry: (_, _) => null);

final adminActionLogsProvider = FutureProvider.autoDispose
    .family<List<AdminActionLog>, AdminActionLogsKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(adminRepositoryProvider)
          .listActionLogs(session, targetUserId: key.targetUserId);
    }, retry: (_, _) => null);
