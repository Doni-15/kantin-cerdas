import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/models/admin_models.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';

final class AdminApiDataSource implements AdminDataSource {
  const AdminApiDataSource({this.dio});

  final Dio? dio;

  @override
  bool get isMutationConfigured =>
      dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<AdminSummaryModel> getSummary() async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>('/v1/admin/summary');
      return AdminSummaryModel.fromJson(
        asJsonMap(response.data, fieldName: 'summary'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AdminUserPageModel> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/admin/users',
        queryParameters: <String, Object?>{
          'search': search,
          'cursor': ?cursor,
          'limit': limit,
        },
      );
      return AdminUserPageModel.fromJson(
        asJsonMap(response.data, fieldName: 'users'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AdminUserRecordModel?> getUser({required String userId}) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/admin/users/${Uri.encodeComponent(userId)}',
      );
      return AdminUserRecordModel.fromJson(
        asJsonMap(response.data, fieldName: 'user'),
      );
    } on DioException catch (error) {
      final apiErr = mapDioException(error);
      if (apiErr.statusCode == 404 && apiErr.hasBackendErrorCode) {
        return null;
      }
      throw apiErr;
    }
  }

  @override
  Future<AdminUserRecordModel> setUserAccess(
    AdminUserAccessChange change, {
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/admin/users/${Uri.encodeComponent(change.userId)}/access',
        data: <String, Object?>{
          'mutation_id': mutationId,
          'expected_version': change.expectedVersion,
          'is_active': change.isActive,
          'reason': change.reason,
        },
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': mutationId},
        ),
      );
      return AdminUserRecordModel.fromJson(
        asJsonMap(response.data, fieldName: 'access'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AdminApplicationPageModel> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/admin/applications',
        queryParameters: <String, Object?>{
          if (status != null) 'status': status.name,
          'cursor': ?cursor,
          'limit': limit,
        },
      );
      return AdminApplicationPageModel.fromJson(
        asJsonMap(response.data, fieldName: 'applications'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<CanteenApplicationModel?> getApplication({
    required String applicationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/admin/applications/${Uri.encodeComponent(applicationId)}',
      );
      return CanteenApplicationModel.fromJson(
        asJsonMap(response.data, fieldName: 'application'),
      );
    } on DioException catch (error) {
      final apiErr = mapDioException(error);
      if (apiErr.statusCode == 404 && apiErr.hasBackendErrorCode) {
        return null;
      }
      throw apiErr;
    }
  }

  @override
  Future<CanteenApplicationModel> reviewApplication(
    AdminApplicationReview review, {
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/admin/applications/${Uri.encodeComponent(review.applicationId)}/review',
        data: <String, Object?>{
          'mutation_id': mutationId,
          'expected_version': review.expectedVersion,
          'status': review.status.name,
          'reason': review.reason,
        },
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': mutationId},
        ),
      );
      return CanteenApplicationModel.fromJson(
        asJsonMap(response.data, fieldName: 'review'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<AdminMutationLookup> lookupMutation({
    required String mutationId,
  }) async {
    final client = dio;
    if (!isMutationConfigured || client == null) {
      throw const AdminNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/operations/admin-mutations/${Uri.encodeComponent(mutationId)}',
      );
      return AdminMutationLookupModel.fromJson(
        asJsonMap(response.data, fieldName: 'admin_mutation_lookup'),
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
