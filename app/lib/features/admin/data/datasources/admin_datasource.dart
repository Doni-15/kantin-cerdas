import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/admin/data/models/admin_models.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';

abstract interface class AdminDataSource {
  bool get isMutationConfigured;
  Future<AdminSummaryModel> getSummary();
  Future<AdminUserPageModel> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  });
  Future<AdminUserRecordModel?> getUser({required String userId});
  Future<AdminUserRecordModel> setUserAccess(
    AdminUserAccessChange change, {
    required String mutationId,
  });
  Future<AdminApplicationPageModel> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  });
  Future<CanteenApplicationModel?> getApplication({
    required String applicationId,
  });
  Future<CanteenApplicationModel> reviewApplication(
    AdminApplicationReview review, {
    required String mutationId,
  });
  Future<AdminMutationLookup> lookupMutation({required String mutationId});
}
