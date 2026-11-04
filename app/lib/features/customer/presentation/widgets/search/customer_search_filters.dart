import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerSearchFilters extends StatelessWidget {
  const CustomerSearchFilters({
    super.key,
    required this.controller,
    required this.maxPrice,
    required this.onlyAvailable,
    required this.onQueryChanged,
    required this.onClear,
    required this.onReset,
    required this.onPriceChanged,
    required this.onAvailabilityChanged,
  });
  final TextEditingController controller;
  final int? maxPrice;
  final bool onlyAvailable;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final VoidCallback onReset;
  final ValueChanged<int?> onPriceChanged;
  final ValueChanged<bool> onAvailabilityChanged;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KcTextField(
          label: 'Menu atau stan',
          hint: 'Masukkan nama menu atau stan',
          controller: controller,
          maxLength: CustomerInputLimits.maxSearchLength,
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          onChanged: onQueryChanged,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
        ),
        const SizedBox(height: KcSpacing.md),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: KcSpacing.xs,
          children: [
            Text('Batas harga', style: Theme.of(context).textTheme.titleSmall),
            TextButton(
              onPressed: maxPrice == null && !onlyAvailable ? null : onReset,
              child: const Text('Reset filter'),
            ),
          ],
        ),
        Wrap(
          spacing: KcSpacing.xs,
          runSpacing: KcSpacing.xs,
          children: [
            for (final price in const <int?>[null, 15000, 20000])
              ChoiceChip(
                label: Text(
                  price == null
                      ? 'Semua harga'
                      : 'Maks. ${formatRupiah(price)}',
                ),
                selected: maxPrice == price,
                onSelected: (selected) {
                  if (selected) {
                    onPriceChanged(price);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: KcSpacing.xs),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Hanya menu yang bisa dipesan'),
          value: onlyAvailable,
          onChanged: (value) => onAvailabilityChanged(value ?? false),
        ),
      ],
    );
  }
}
