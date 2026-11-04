import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Ringkasan pilihan lokal pada halaman penjelajahan menu.
///
/// TODO(backend): Harga akhir pesanan menggunakan hasil validasi checkout.
/// Nilai yang ditampilkan di sini merupakan estimasi subtotal keranjang.
class CartSummaryBar extends ConsumerWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCustomerSession = ref.watch(
      authStateProvider.select((state) {
        final user = state.asData?.value;

        return !state.isLoading &&
            user != null &&
            user.isActive &&
            user.role.canUseCustomerFeatures;
      }),
    );

    if (!hasCustomerSession || MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stallName = cart.stallName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
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
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                child: OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  spacing: KcSpacing.md,
                  overflowSpacing: KcSpacing.sm,
                  overflowAlignment: OverflowBarAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.totalQuantity} item'
                            ' · ${formatRupiah(cart.totalPrice)}',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: KcSpacing.xs / 2),
                          Text(
                            'Estimasi subtotal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (stallName != null &&
                              stallName.trim().isNotEmpty) ...[
                            const SizedBox(height: KcSpacing.xs / 2),
                            Text(
                              stallName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    KcButton(
                      label: 'Lihat keranjang',
                      leading: const Icon(Icons.shopping_bag_outlined),
                      fullWidth: false,
                      onPressed: () => context.push(Routes.customerCart),
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
