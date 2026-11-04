import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/food_preferences_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/food_preferences_repository.dart';

final class FoodPreferencesRepositoryImpl implements FoodPreferencesRepository {
  const FoodPreferencesRepositoryImpl({required this._dataSource});

  final FoodPreferencesDataSource _dataSource;

  @override
  bool get isSaveConfigured => _dataSource.isSaveConfigured;

  @override
  Future<FoodPreferencesSnapshot?> getMyPreferences() async {
    try {
      final model = await _dataSource.getMyPreferences();
      return model?.toEntity();
    } on FoodPreferencesFailure {
      rethrow;
    } on DataParsingException {
      throw const FoodPreferencesInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapFoodPreferencesReadApiException(e);
    } catch (_) {
      throw const FoodPreferencesInvalidDataFailure();
    }
  }

  @override
  Future<FoodPreferencesSnapshot> saveMyPreferences(
    FoodPreferencesUpdate update, {
    required String mutationId,
  }) async {
    if (!isSaveConfigured) {
      throw const FoodPreferencesNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.saveMyPreferences(
        update,
        mutationId: mutationId,
      );
      return model.toEntity();
    } on FoodPreferencesFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapFoodPreferencesSaveApiException(e);
    } catch (_) {
      throw const FoodPreferencesUnknownFailure();
    }
  }

  @override
  Future<FoodPreferencesLookup> lookupSave({required String mutationId}) async {
    if (!isSaveConfigured) {
      throw const FoodPreferencesNotConfiguredFailure();
    }
    if (mutationId.trim().isEmpty) {
      throw const FoodPreferencesUnknownFailure();
    }
    try {
      final result = await _dataSource.lookupSave(mutationId: mutationId);
      if (result.request.mutationId != mutationId) {
        throw const FoodPreferencesUnknownFailure();
      }
      return result;
    } on FoodPreferencesFailure {
      rethrow;
    } catch (_) {
      throw const FoodPreferencesUnknownFailure();
    }
  }
}
