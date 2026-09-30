import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/customer/presentation/pages/customer_cart_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/rupiah_formatter.dart';

class CartSummaryBar extends ConsumerWidget {
  const CartSummaryBar({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final cart =
        ref.watch(cartProvider);

    final theme =
        Theme.of(context);

    if (cart.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: theme
            .colorScheme
            .primaryContainer,
        border: Border(
          top: BorderSide(
            color: theme
                .colorScheme
                .outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.totalQuantity} porsi'
                  ' · ${formatRupiah(cart.totalPrice)}',
                  style: theme
                      .textTheme
                      .titleSmall,
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  cart.stallName ?? '',
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
          ),

          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const CustomerCartPage();
                  },
                ),
              );
            },
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  'Keranjang',
                ),
                SizedBox(
                  width: 4,
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}