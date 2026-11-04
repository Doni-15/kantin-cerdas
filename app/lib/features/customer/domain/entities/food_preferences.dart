import 'package:characters/characters.dart';
import 'package:kantin_cerdas/core/utils/collection_equality.dart';

class FoodPreferences {
  FoodPreferences({
    required this.maxBudgetIdr,
    required this.vegetarian,
    required Iterable<String> avoidIngredients,
  }) : avoidIngredients = List.unmodifiable(_normalize(avoidIngredients)) {
    if (maxBudgetIdr != null &&
        (maxBudgetIdr! < 1 || maxBudgetIdr! > maxBudgetLimit)) {
      throw ArgumentError('Anggaran tidak valid.');
    }
  }
  static const maxBudgetLimit = 10000000;
  static const maxIngredients = 20;
  static const maxIngredientLength = 60;
  final int? maxBudgetIdr;
  final bool vegetarian;
  final List<String> avoidIngredients;

  static List<String> _normalize(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final text = value.trim();
      if (text.isEmpty ||
          text.characters.length > maxIngredientLength ||
          text.contains(RegExp(r'[,\n\r]'))) {
        throw ArgumentError('Bahan tidak valid.');
      }
      if (seen.add(text.toLowerCase())) {
        result.add(text);
      }
    }
    if (result.length > maxIngredients) {
      throw ArgumentError('Terlalu banyak bahan.');
    }
    return result;
  }

  static int? parseBudget(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    final amount = int.tryParse(text);
    if (!RegExp(r'^[0-9]+$').hasMatch(text) ||
        amount == null ||
        amount < 1 ||
        amount > maxBudgetLimit) {
      throw ArgumentError('Anggaran tidak valid.');
    }
    return amount;
  }

  static List<String> parseIngredients(String value) => _normalize(
    value
        .split(RegExp(r'[,\n]'))
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty),
  );

  bool sameAs(FoodPreferences other) {
    final ingredients = avoidIngredients
        .map((value) => value.toLowerCase())
        .toSet();
    return maxBudgetIdr == other.maxBudgetIdr &&
        vegetarian == other.vegetarian &&
        ingredients.length == other.avoidIngredients.length &&
        ingredients.containsAll(
          other.avoidIngredients.map((value) => value.toLowerCase()),
        );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodPreferences &&
          other.maxBudgetIdr == maxBudgetIdr &&
          other.vegetarian == vegetarian &&
          listEquals(other.avoidIngredients, avoidIngredients));

  @override
  int get hashCode =>
      Object.hash(maxBudgetIdr, vegetarian, Object.hashAll(avoidIngredients));
}
