import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/pagination_validator.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/mappers/admin_failure_mapper.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_page.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_summary.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_page.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/domain/repositories/admin_repository.dart';

final class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl({required this._dataSource});

  final AdminDataSource _dataSource;

  @override
  bool get isMutationConfigured => _dataSource.isMutationConfigured;

  @override
  Future<AdminSummary> getSummary() async {
    try {
      final model = await _dataSource.getSummary();
      return model.toEntity();
    } on AdminFailure {
      rethrow;
    } on DataParsingException {
      throw const AdminInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapAdminReadApiException(e);
    } catch (_) {
      throw const AdminInvalidDataFailure();
    }
  }

  @override
  Future<AdminUserPage> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final page = await _dataSource.listUsers(
        search: search,
        cursor: cursor,
        limit: limit,
      );
      final entity = page.toEntity();
      validateCursorPageBounds(
        limit: limit,
        requestCursor: cursor,
        itemCount: entity.users.length,
        nextCursor: entity.nextCursor,
      );
      return entity;
    } on AdminFailure {
      rethrow;
    } on DataParsingException {
      throw const AdminInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapAdminReadApiException(e);
    } catch (_) {
      throw const AdminInvalidDataFailure();
    }
  }

  @override
  Future<AdminUserRecord?> getUser({required String userId}) async {
    try {
      final model = await _dataSource.getUser(userId: userId);
      return model?.toEntity();
    } on AdminFailure {
      rethrow;
    } on DataParsingException {
      throw const AdminInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapAdminReadApiException(e);
    } catch (_) {
      throw const AdminInvalidDataFailure();
    }
  }

  @override
  Future<AdminUserRecord> setUserAccess(
    AdminUserAccessChange change, {
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.setUserAccess(
        change,
        mutationId: mutationId,
      );
      return model.toEntity();
    } on AdminFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapAdminUserAccessApiException(e);
    } catch (_) {
      throw const AdminUserAccessUnknownFailure();
    }
  }

  @override
  Future<AdminApplicationPage> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final page = await _dataSource.listApplications(
        status: status,
        cursor: cursor,
        limit: limit,
      );
      final entity = page.toEntity();
      validateCursorPageBounds(
        limit: limit,
        requestCursor: cursor,
        itemCount: entity.items.length,
        nextCursor: entity.nextCursor,
      );
      return entity;
    } on AdminFailure {
      rethrow;
    } on DataParsingException {
      throw const AdminInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapAdminReadApiException(e);
    } catch (_) {
      throw const AdminInvalidDataFailure();
    }
  }

  @override
  Future<CanteenApplication?> getApplication({
    required String applicationId,
  }) async {
    try {
      final model = await _dataSource.getApplication(
        applicationId: applicationId,
      );
      return model?.toEntity();
    } on AdminFailure {
      rethrow;
    } on DataParsingException {
      throw const AdminInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapAdminReadApiException(e);
    } catch (_) {
      throw const AdminInvalidDataFailure();
    }
  }

  @override
  Future<CanteenApplication> reviewApplication(
    AdminApplicationReview review, {
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.reviewApplication(
        review,
        mutationId: mutationId,
      );
      return model.toEntity();
    } on AdminFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapAdminReviewApiException(e);
    } catch (_) {
      throw const AdminReviewUnknownFailure();
    }
  }

  @override
  Future<AdminMutationLookup> lookupMutation({
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const AdminNotConfiguredFailure();
    }
    if (mutationId.trim().isEmpty) {
      throw const AdminReviewUnknownFailure();
    }
    try {
      final result = await _dataSource.lookupMutation(mutationId: mutationId);
      if (result.request.mutationId != mutationId) {
        throw const AdminReviewUnknownFailure();
      }
      return result;
    } on AdminFailure {
      rethrow;
    } catch (_) {
      throw const AdminReviewUnknownFailure();
    }
  }
}
