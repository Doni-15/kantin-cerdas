import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/rupiah_formatter.dart';

class OwnerMenuCard extends StatelessWidget {
  const OwnerMenuCard({
    super.key,
    required this.menu,
    required this.onAvailabilityChanged,
  });

  final OwnerMenuItem menu;

  final ValueChanged<bool>
      onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const availableColor =
        Color(0xFF1F7A4D);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =======================================================
          // GAMBAR MENU
          // =======================================================

          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: theme.colorScheme
                  .surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restaurant,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(width: 14),

          // =======================================================
          // INFORMASI MENU
          // =======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style:
                      theme.textTheme.titleMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  formatRupiah(menu.price),
                  style:
                      theme.textTheme.titleSmall,
                ),

                const SizedBox(height: 18),

                Text(
                  menu.available
                      ? 'Tersedia'
                      : 'Habis',
                  style:
                      theme.textTheme.bodySmall
                          ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =======================================================
          // SWITCH KETERSEDIAAN
          // =======================================================

          Padding(
            padding:
                const EdgeInsets.only(top: 48),
            child: Switch(
              value: menu.available,

              activeTrackColor:
                  availableColor,

              activeThumbColor:
                  Colors.white,

              onChanged:
                  onAvailabilityChanged,
            ),
          ),
        ],
      ),
    );
  }
}