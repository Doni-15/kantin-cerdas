import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class FoodPreferencesFields extends StatelessWidget {
  const FoodPreferencesFields({
    super.key,
    required this.budget,
    required this.ingredients,
    required this.vegetarian,
    required this.enabled,
    required this.onVegetarianChanged,
    required this.onChanged,
  });
  final TextEditingController budget;
  final TextEditingController ingredients;
  final bool vegetarian;
  final bool enabled;
  final ValueChanged<bool> onVegetarianChanged;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KcTextField(
        label: 'Anggaran maksimal per menu (Rp)',
        controller: budget,
        enabled: enabled,
        keyboardType: TextInputType.number,
        maxLength: 8,
        hint: 'Kosongkan jika tidak dibatasi',
        onChanged: (_) => onChanged(),
        validator: (value) {
          try {
            FoodPreferences.parseBudget(value ?? '');
            return null;
          } on ArgumentError {
            return 'Isi angka 1–10.000.000 tanpa titik, atau kosongkan.';
          }
        },
      ),
      const SizedBox(height: KcSpacing.sm),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Pilihan vegetarian'),
        subtitle: const Text('Utamakan menu vegetarian dalam rekomendasi.'),
        value: vegetarian,
        onChanged: enabled ? onVegetarianChanged : null,
      ),
      const SizedBox(height: KcSpacing.sm),
      KcTextField(
        label: 'Bahan yang ingin dihindari',
        controller: ingredients,
        enabled: enabled,
        maxLines: 4,
        maxLength: 1300,
        hint: 'Pisahkan dengan koma atau baris baru',
        onChanged: (_) => onChanged(),
        validator: (value) {
          try {
            FoodPreferences.parseIngredients(value ?? '');
            return null;
          } on ArgumentError {
            return 'Maksimal 20 bahan, masing-masing 60 karakter.';
          }
        },
      ),
      const SizedBox(height: KcSpacing.sm),
      const Text(
        'Preferensi membantu memilih menu. Pastikan bahan dan alergi langsung kepada stan.',
      ),
    ],
  );
}
