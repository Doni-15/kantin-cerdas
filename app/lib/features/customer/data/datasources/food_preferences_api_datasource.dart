import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/food_preferences_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/food_preferences_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';

final class FoodPreferencesApiDataSource implements FoodPreferencesDataSource {
  const FoodPreferencesApiDataSource({this.dio});

  final Dio? dio;

  @override
  bool get isSaveConfigured => dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<FoodPreferencesSnapshotModel?> getMyPreferences() async {
    final client = dio;
    if (!isSaveConfigured || client == null) {
      throw const FoodPreferencesNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/customer/food-preferences',
      );
      return FoodPreferencesSnapshotModel.fromJson(
        asJsonMap(response.data, fieldName: 'food_preferences'),
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
  Future<FoodPreferencesSnapshotModel> saveMyPreferences(
    FoodPreferencesUpdate update, {
    required String mutationId,
  }) async {
    final client = dio;
    if (!isSaveConfigured || client == null) {
      throw const FoodPreferencesNotConfiguredFailure();
    }
    try {
      final response = await client.put<Object?>(
        '/v1/customer/food-preferences',
        data: <String, Object?>{
          'mutation_id': mutationId,
          'expected_version': update.expectedVersion,
          'max_budget_idr': update.preferences.maxBudgetIdr,
          'vegetarian': update.preferences.vegetarian,
          'avoid_ingredients': update.preferences.avoidIngredients,
        },
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': mutationId},
        ),
      );
      return FoodPreferencesSnapshotModel.fromJson(
        asJsonMap(response.data, fieldName: 'food_preferences'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<FoodPreferencesLookup> lookupSave({required String mutationId}) async {
    final client = dio;
    if (!isSaveConfigured || client == null) {
      throw const FoodPreferencesNotConfiguredFailure();
    }
    try {
      final response = await client.get<Object?>(
        '/v1/operations/food-preferences/${Uri.encodeComponent(mutationId)}',
      );
      return FoodPreferencesLookupModel.fromJson(
        asJsonMap(response.data, fieldName: 'food_preferences_lookup'),
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
