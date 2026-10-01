import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';

class CartQuantityButton extends ConsumerWidget {
  const CartQuantityButton({
    super.key,
    required this.menu,
  });

  final MenuItem menu;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    final quantity =
        cart.quantityOf(menu.id);

    if (!menu.available) {
      return Padding(
        padding:
            const EdgeInsets.only(top: 10),
        child: Text(
          'Habis',
          style: theme.textTheme.bodyMedium
              ?.copyWith(
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      );
    }

    if (quantity == 0) {
      return OutlinedButton(
        onPressed: () {
          _addItem(
            context,
            ref,
          );
        },
        child: const Text(
          'Tambah',
        ),
      );
    }

    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          IconButton(
            constraints:
                const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding:
                EdgeInsets.zero,
            onPressed: () {
              ref
                  .read(
                    cartProvider.notifier,
                  )
                  .decreaseItem(menu.id);
            },
            icon: const Icon(
              Icons.remove,
              size: 18,
            ),
          ),

          SizedBox(
            width: 22,
            child: Text(
              '$quantity',
              textAlign:
                  TextAlign.center,
            ),
          ),

          IconButton(
            constraints:
                const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding:
                EdgeInsets.zero,
            onPressed: () {
              _addItem(
                context,
                ref,
              );
            },
            icon: const Icon(
              Icons.add,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final added = ref
        .read(cartProvider.notifier)
        .addItem(menu);

    if (added) {
      return;
    }

    final currentCart =
        ref.read(cartProvider);

    final replace =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Ganti isi keranjang?',
          ),
          content: Text(
            'Keranjangmu berisi pesanan dari '
            '${currentCart.stallName}. '
            'Untuk menambah menu dari '
            '${menu.stallName}, isi keranjang '
            'saat ini akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Ganti keranjang',
              ),
            ),
          ],
        );
      },
    );

    if (replace == true) {
      ref
          .read(cartProvider.notifier)
          .replaceCart(menu);
    }
  }
}