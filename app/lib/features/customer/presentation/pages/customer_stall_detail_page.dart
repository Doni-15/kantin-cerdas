import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_catalog_message.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart_summary_bar.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/stall/customer_stall_content.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Detail stan berdasarkan identitas dari router.
class CustomerStallDetailPage extends ConsumerWidget {
  const CustomerStallDetailPage({super.key, required this.stallId});

  final String stallId;

  void _goBack(BuildContext context) {
    FocusScope.of(context).unfocus();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.customerHome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(customerCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _goBack(context)),
        title: const Text('Detail stan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang katalog',
            icon: const Icon(Icons.refresh),
            onPressed: catalogState.isLoading
                ? null
                : () => ref.invalidate(customerCatalogProvider),
          ),
          IconButton(
            tooltip: 'Buka keranjang',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => context.push(Routes.customerCart),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: catalogState.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const SingleChildScrollView(
                padding: EdgeInsets.all(KcSpacing.pageHorizontal),
                child: KcLoadingSkeleton(
                  label: 'Memuat detail stan',
                  layout: KcSkeletonLayout.detail,
                ),
              ),
              error: (error, _) => SingleChildScrollView(
                padding: const EdgeInsets.all(KcSpacing.pageHorizontal),
                child: KcStatusPanel(
                  icon: Icons.cloud_off_outlined,
                  title: customerCatalogErrorTitle(error),
                  message: customerCatalogErrorMessage(error),
                  action: KcButton(
                    label: 'Coba lagi',
                    onPressed: () => ref.invalidate(customerCatalogProvider),
                  ),
                ),
              ),
              data: (catalog) {
                final selectedStall = catalog.stallById(stallId);

                if (selectedStall == null) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(KcSpacing.pageHorizontal),
                    child: KcStatusPanel(
                      icon: Icons.storefront_outlined,
                      title: 'Stan tidak ditemukan',
                      message: 'Stan ini tidak ada dalam katalog yang dimuat.',
                      action: KcButton(
                        label: 'Kembali ke beranda',
                        onPressed: () => context.go(Routes.customerHome),
                      ),
                    ),
                  );
                }

                return CustomerStallContent(
                  key: ValueKey(selectedStall.id),
                  stall: selectedStall,
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CartSummaryBar(),
    );
  }
}
