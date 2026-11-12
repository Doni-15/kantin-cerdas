import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';

class FoodPreferencesSnapshotModel {
  const FoodPreferencesSnapshotModel({
    required this.customerId,
    required this.version,
    required this.maxBudgetIdr,
    required this.vegetarian,
    required this.avoidIngredients,
  });

  factory FoodPreferencesSnapshotModel.fromJson(Map<String, Object?> json) {
    final customerId = json['customer_id'] ?? json['customerId'];
    final version = json['version'];
    final rawPrefs = tryAsJsonMap(json['preferences']) ?? json;
    final maxBudget = rawPrefs['max_budget_idr'] ?? rawPrefs['maxBudgetIdr'];
    final vegetarian = rawPrefs['vegetarian'];
    final rawIngredients =
        rawPrefs['avoid_ingredients'] ?? rawPrefs['avoidIngredients'];

    if (customerId is! String ||
        version is! int ||
        (maxBudget != null && maxBudget is! int) ||
        vegetarian is! bool ||
        rawIngredients is! List<Object?>) {
      throw const DataParsingException(
        'Format snapshot preferensi makanan tidak valid.',
      );
    }

    final ingredients = <String>[];
    for (final item in rawIngredients) {
      if (item is! String) {
        throw const DataParsingException('Bahan dihindari harus berupa teks.');
      }
      ingredients.add(item);
    }

    return FoodPreferencesSnapshotModel(
      customerId: customerId,
      version: version,
      maxBudgetIdr: maxBudget as int?,
      vegetarian: vegetarian,
      avoidIngredients: ingredients,
    );
  }

  final String customerId;
  final int version;
  final int? maxBudgetIdr;
  final bool vegetarian;
  final List<String> avoidIngredients;

  FoodPreferencesSnapshot toEntity() {
    try {
      return FoodPreferencesSnapshot(
        customerId: customerId,
        version: version,
        preferences: FoodPreferences(
          maxBudgetIdr: maxBudgetIdr,
          vegetarian: vegetarian,
          avoidIngredients: avoidIngredients,
        ),
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Preferensi makanan tidak valid.',
      );
    }
  }
}

class FoodPreferencesLookupModel {
  const FoodPreferencesLookupModel({
    required this.customerId,
    required this.mutationId,
    required this.expectedVersion,
    required this.maxBudgetIdr,
    required this.vegetarian,
    required this.avoidIngredients,
    required this.outcome,
    this.snapshot,
  });

  factory FoodPreferencesLookupModel.fromJson(Map<String, Object?> json) {
    final req = tryAsJsonMap(json['request']) ?? json;
    final update = tryAsJsonMap(req['update']) ?? req;
    final prefs = tryAsJsonMap(update['preferences']) ?? update;

    final customerId =
        req['customer_id'] ??
        req['customerId'] ??
        json['customer_id'] ??
        json['customerId'];
    final mutationId =
        req['mutation_id'] ??
        req['mutationId'] ??
        json['mutation_id'] ??
        json['mutationId'];
    final expectedVersion =
        update['expected_version'] ?? update['expectedVersion'];
    final maxBudget = prefs['max_budget_idr'] ?? prefs['maxBudgetIdr'];
    final vegetarian = prefs['vegetarian'];
    final rawIngredients =
        prefs['avoid_ingredients'] ?? prefs['avoidIngredients'];
    final outcome = json['outcome'] ?? json['status'];
    final rawSnapshot = tryAsJsonMap(json['snapshot'] ?? json['saved']);

    if (customerId is! String ||
        mutationId is! String ||
        (expectedVersion != null && expectedVersion is! int) ||
        (maxBudget != null && maxBudget is! int) ||
        vegetarian is! bool ||
        rawIngredients is! List<Object?> ||
        outcome is! String) {
      throw const DataParsingException(
        'Format lookup preferensi makanan tidak valid.',
      );
    }

    final ingredients = <String>[];
    for (final item in rawIngredients) {
      if (item is! String) {
        throw const DataParsingException('Bahan dihindari harus berupa teks.');
      }
      ingredients.add(item);
    }

    return FoodPreferencesLookupModel(
      customerId: customerId,
      mutationId: mutationId,
      expectedVersion: expectedVersion as int?,
      maxBudgetIdr: maxBudget as int?,
      vegetarian: vegetarian,
      avoidIngredients: ingredients,
      outcome: outcome,
      snapshot: rawSnapshot == null
          ? null
          : FoodPreferencesSnapshotModel.fromJson(rawSnapshot),
    );
  }

  final String customerId;
  final String mutationId;
  final int? expectedVersion;
  final int? maxBudgetIdr;
  final bool vegetarian;
  final List<String> avoidIngredients;
  final String outcome;
  final FoodPreferencesSnapshotModel? snapshot;

  FoodPreferencesLookup toEntity() {
    final parsedOutcome = switch (outcome.trim().toLowerCase()) {
      'pending' => FoodPreferencesOutcome.pending,
      'applied' || 'saved' => FoodPreferencesOutcome.applied,
      'not_applied' ||
      'notapplied' ||
      'not_saved' ||
      'notsaved' => FoodPreferencesOutcome.notApplied,
      _ => throw const DataParsingException(
        'Outcome lookup preferensi makanan tidak dikenali.',
      ),
    };
    try {
      return FoodPreferencesLookup(
        request: PendingFoodPreferences(
          customerId: customerId,
          mutationId: mutationId,
          update: FoodPreferencesUpdate(
            expectedVersion: expectedVersion,
            preferences: FoodPreferences(
              maxBudgetIdr: maxBudgetIdr,
              vegetarian: vegetarian,
              avoidIngredients: avoidIngredients,
            ),
          ),
        ),
        outcome: parsedOutcome,
        snapshot: snapshot?.toEntity(),
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Data lookup preferensi makanan tidak valid.',
      );
    }
  }
}
