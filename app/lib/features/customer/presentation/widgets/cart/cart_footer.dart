import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CartFooter extends StatelessWidget {
  const CartFooter({
    super.key,
    required this.cart,
    required this.onContinue,
    this.reconciledTotalPriceIdr,
  });

  final CartState cart;
  final VoidCallback? onContinue;
  final int? reconciledTotalPriceIdr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedTotal = reconciledTotalPriceIdr ?? cart.totalPrice;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.symmetric(
            horizontal: KcSpacing.pageHorizontal,
            vertical: KcSpacing.sm,
          ),
          child: Align(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                child: OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  spacing: KcSpacing.md,
                  overflowSpacing: KcSpacing.sm,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.totalQuantity} item',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Estimasi subtotal',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            formatRupiah(displayedTotal),
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    KcButton(
                      label: 'Lanjut konfirmasi',
                      fullWidth: false,
                      onPressed: onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
