import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Menjadikan pemulihan dapat ditemukan setelah login ulang/restart,
/// termasuk ketika keranjang lokal sudah kosong.
class CustomerCheckoutBanner extends ConsumerWidget {
  const CustomerCheckoutBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.isLoading ? null : auth.asData?.value;
    if (user == null || !user.isActive || !user.role.canUseCustomerFeatures) {
      return const SizedBox.shrink();
    }
    final persisted = ref.watch(customerCheckoutJournalProvider(user.id));
    if (persisted.isLoading ||
        (!persisted.hasError && persisted.asData?.value == null)) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KcSpacing.pageHorizontal,
          vertical: KcSpacing.xs,
        ),
        child: KcButton(
          label: persisted.hasError
              ? 'Periksa status pengiriman lokal'
              : 'Pulihkan hasil pesanan',
          variant: KcButtonVariant.outlined,
          leading: const Icon(Icons.pending_actions),
          onPressed: () => context.push(Routes.customerOrderConfirmation),
        ),
      ),
    );
  }
}
