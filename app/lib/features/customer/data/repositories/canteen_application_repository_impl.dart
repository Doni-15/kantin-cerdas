import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/canteen_application_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_repository.dart';

class CanteenApplicationRepositoryImpl implements CanteenApplicationRepository {
  const CanteenApplicationRepositoryImpl(this.dataSource);

  final CanteenApplicationDataSource dataSource;

  @override
  Future<CanteenApplication?> getMyApplication() {
    return _guard<CanteenApplication?>(() async {
      final model = await dataSource.getMyApplication();

      return model?.toEntity();
    });
  }

  @override
  Future<CanteenApplication> submit({
    required String name,
    required String description,
    required String address,
  }) {
    return _guard<CanteenApplication>(() async {
      final model = await dataSource.submit(
        name: name,
        description: description,
        address: address,
      );

      return model.toEntity();
    });
  }

  @override
  Future<CanteenApplication> updateStatus({
    required String id,
    required CanteenApplicationStatus status,
    String? rejectionReason,
  }) {
    return _guard<CanteenApplication>(() async {
      final model = await dataSource.updateStatus(
        id: id,
        status: CanteenApplicationModel.statusToJson(status),
        rejectionReason: rejectionReason,
      );

      return model.toEntity();
    });
  }

  @override
  Future<void> deleteMyApplication() {
    return _guard<void>(() => dataSource.deleteMyApplication());
  }

  /// Satu-satunya tempat error Data Layer dipetakan menjadi CanteenApplicationFailure.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw _mapApiException(error);
    } on DataParsingException {
      throw const CanteenApplicationUnknownFailure();
    } on FormatException {
      throw const CanteenApplicationUnknownFailure();
    } on TypeError {
      throw const CanteenApplicationUnknownFailure();
    }
  }

  CanteenApplicationFailure _mapApiException(ApiException error) {
    switch (error.code) {
      case ApiErrorCode.validationError:
        return CanteenApplicationValidationFailure(error.fieldErrors);
      case ApiErrorCode.tokenInvalid:
      case ApiErrorCode.tokenExpired:
        return const CanteenApplicationUnauthorizedFailure();
      case ApiErrorCode.network:
      case ApiErrorCode.timeout:
        return const CanteenApplicationNetworkFailure();
    }

    // Code belum dikenal: putuskan berdasarkan status code.
    return switch (error.statusCode) {
      0 => const CanteenApplicationNetworkFailure(),
      401 => const CanteenApplicationUnauthorizedFailure(),
      _ => const CanteenApplicationUnknownFailure(),
    };
  }
}
