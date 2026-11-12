import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/session_restore_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_catalog_reconciliation_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/customer_checkout_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/listen_customer_checkout_result.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/order_confirmation_header.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/order_confirmation_summary.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/order_review_item.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrderConfirmationPage extends ConsumerWidget {
  const CustomerOrderConfirmationPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.isLoading ? null : auth.asData?.value;
    if (user == null || !user.isActive || !user.role.canUseCustomerFeatures) {
      return const SessionRestorePage();
    }
    listenCustomerCheckoutResult(context, ref);
    final isSubmitting = ref.watch(
      customerOrderControllerProvider.select((s) => s.isLoading),
    );
    final locked = ref.watch(customerCheckoutLockedProvider);
    final cart = ref.watch(cartProvider);
    final reconciliation = ref.watch(cartCatalogReconciliationProvider);
    return PopScope<void>(
      canPop: !isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(locked ? 'Status pesanan' : 'Konfirmasi pesanan'),
          leading: BackButton(
            onPressed: isSubmitting
                ? null
                : () {
                    if (locked) {
                      context.go(Routes.customerHome);
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(Routes.customerCart);
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: locked
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.all(KcSpacing.pageHorizontal),
                      child: CustomerCheckoutPanel(),
                    )
                  : cart.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(KcSpacing.pageHorizontal),
                      child: KcStatusPanel(
                        title: 'Belum ada pilihan untuk dikonfirmasi',
                        message:
                            'Pilih menu terlebih dahulu dari stan yang kamu inginkan.',
                        icon: Icons.shopping_bag_outlined,
                        action: KcButton(
                          label: 'Pilih menu',
                          onPressed: () => context.go(Routes.customerHome),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(KcSpacing.pageHorizontal),
                      itemCount: cart.items.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return OrderConfirmationHeader(
                            cart: cart,
                            stall: reconciliation.currentStall,
                            loading: reconciliation.isLoadingCatalog,
                            hasError: reconciliation.hasCatalogError,
                            hasCatalogPricing:
                                reconciliation.hasCompleteCatalogPricing,
                            onRetry: () =>
                                ref.invalidate(customerCatalogProvider),
                            onEdit: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(Routes.customerCart);
                              }
                            },
                          );
                        }
                        if (index == cart.items.length + 1) {
                          return OrderConfirmationSummary(
                            cart: cart,
                            estimatedSubtotal:
                                reconciliation.confirmedSubtotalPriceIdr,
                            hasCatalogPricing:
                                reconciliation.hasCompleteCatalogPricing,
                          );
                        }
                        final item = cart.items[index - 1];
                        return OrderReviewItem(
                          key: ValueKey(item.menu.id),
                          item: item,
                          currentMenu: reconciliation.pricedMenus[item.menu.id],
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
