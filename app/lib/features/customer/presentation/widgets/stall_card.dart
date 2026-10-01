import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';

class StallCard extends StatelessWidget {
  const StallCard({
    super.key,
    required this.stall,
    required this.onTap,
  });

  final Stall stall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
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
          children: [
            Container(
              width: 54,
              height: 54,
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
                Icons
                    .storefront_outlined,
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
                    stall.name,
                    style: theme
                        .textTheme
                        .titleSmall,
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: stall.isOpen
                            ? theme
                                .colorScheme
                                .tertiary
                            : theme
                                .colorScheme
                                .error,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Text(
                        '${stall.isOpen ? 'Buka' : 'Tutup'}'
                        ' · ${stall.block}',
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
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }
}