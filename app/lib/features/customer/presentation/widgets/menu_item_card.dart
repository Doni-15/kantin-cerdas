import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart_quantity_button.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.menu,
    this.showStallName = true,
    this.onTap,
  });

  final MenuItem menu;
  final bool showStallName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme
                  .colorScheme
                  .outlineVariant,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // GAMBAR SEMENTARA
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Icon(
                Icons.restaurant,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: theme
                        .textTheme
                        .titleMedium,
                  ),

                  if (showStallName) ...[
                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      menu.stallName,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    menu.waitTime,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    formatRupiah(
                      menu.price,
                    ),
                    style: theme
                        .textTheme
                        .titleSmall,
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            CartQuantityButton(
              menu: menu,
            ),
          ],
        ),
      ),
    );
  }
}