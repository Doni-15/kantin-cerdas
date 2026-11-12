import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_repository.dart';

final class CanteenApplicationRepositoryImpl
    implements CanteenApplicationRepository {
  const CanteenApplicationRepositoryImpl({required this._dataSource});

  final CanteenApplicationDataSource _dataSource;

  @override
  bool get isSubmissionConfigured => _dataSource.isSubmissionConfigured;

  @override
  Future<CanteenApplication?> getMyApplication() async {
    try {
      final model = await _dataSource.getMyApplication();
      return model?.toEntity();
    } on CustomerFeatureFailure {
      rethrow;
    } on DataParsingException {
      throw const CustomerFeatureInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapCustomerReadApiException(e);
    } catch (_) {
      throw const CustomerFeatureInvalidDataFailure();
    }
  }

  @override
  Future<CanteenApplication> submit(
    PendingCanteenApplication submission,
  ) async {
    if (!isSubmissionConfigured) {
      throw const CanteenApplicationNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.submit(submission);
      return model.toEntity();
    } on CanteenApplicationFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapCanteenApplicationSubmitApiException(e);
    } catch (_) {
      throw const CanteenApplicationUnconfirmedFailure();
    }
  }

  @override
  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  }) async {
    if (!isSubmissionConfigured) {
      throw const CanteenApplicationNotConfiguredFailure();
    }
    if (submissionId.trim().isEmpty) {
      throw const CanteenApplicationUnconfirmedFailure();
    }
    try {
      final result = await _dataSource.lookupSubmission(
        submissionId: submissionId,
      );
      if (result.submissionId != submissionId) {
        throw const CanteenApplicationUnconfirmedFailure();
      }
      return result;
    } on CanteenApplicationFailure {
      rethrow;
    } catch (_) {
      throw const CanteenApplicationUnconfirmedFailure();
    }
  }
}
