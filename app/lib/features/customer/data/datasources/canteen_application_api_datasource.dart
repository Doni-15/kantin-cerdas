import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';

final class CanteenApplicationApiDataSource
    implements CanteenApplicationDataSource {
  const CanteenApplicationApiDataSource({this.dio});

  final Dio? dio;

  @override
  bool get isSubmissionConfigured =>
      dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<CanteenApplicationModel?> getMyApplication() async {
    final client = dio;
    if (!isSubmissionConfigured || client == null) {
      throw const CustomerFeatureNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/customer/canteen-applications/me',
      );
      return CanteenApplicationModel.fromJson(
        asJsonMap(response.data, fieldName: 'canteen_application'),
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
  Future<CanteenApplicationModel> submit(
    PendingCanteenApplication submission,
  ) async {
    final client = dio;
    if (!isSubmissionConfigured || client == null) {
      throw const CanteenApplicationNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/customer/canteen-applications',
        data: <String, Object?>{
          'submission_id': submission.submissionId,
          'name': submission.draft.name,
          'description': submission.draft.description,
          'location': submission.draft.location,
          'phone': submission.draft.phone,
          'previous_id': submission.previousId,
          'previous_version': submission.previousVersion,
        },
        options: Options(
          headers: <String, Object?>{
            'Idempotency-Key': submission.submissionId,
          },
        ),
      );
      return CanteenApplicationModel.fromJson(
        asJsonMap(response.data, fieldName: 'canteen_application'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  }) async {
    final client = dio;
    if (!isSubmissionConfigured || client == null) {
      throw const CanteenApplicationNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/operations/canteen-applications/${Uri.encodeComponent(submissionId)}',
      );
      return CanteenApplicationLookupModel.fromJson(
        asJsonMap(response.data, fieldName: 'canteen_application_lookup'),
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
