import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_catalog_message.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/search/customer_search_filters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/search/customer_search_results_sliver.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Pencarian pada snapshot katalog dari provider.
class CustomerSearchPage extends ConsumerStatefulWidget {
  const CustomerSearchPage({super.key});

  @override
  ConsumerState<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends ConsumerState<CustomerSearchPage> {
  final _searchController = TextEditingController();

  int? _maxPrice = 20000;
  bool _onlyAvailable = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _maxPrice = null;
      _onlyAvailable = false;
    });
  }

  void _goBack() {
    FocusScope.of(context).unfocus();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.customerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(customerCatalogProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: const Text('Cari menu'),
        actions: [
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
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KcSpacing.pageHorizontal,
                    vertical: KcSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: CustomerSearchFilters(
                      controller: _searchController,
                      maxPrice: _maxPrice,
                      onlyAvailable: _onlyAvailable,
                      onQueryChanged: (_) => setState(() {}),
                      onClear: _clearSearch,
                      onReset: _resetFilters,
                      onPriceChanged: (value) =>
                          setState(() => _maxPrice = value),
                      onAvailabilityChanged: (value) =>
                          setState(() => _onlyAvailable = value),
                    ),
                  ),
                ),
                catalogState.when<Widget>(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: KcSpacing.pageHorizontal,
                      ),
                      child: KcLoadingSkeleton(
                        label: 'Memuat katalog',
                        layout: KcSkeletonLayout.catalog,
                      ),
                    ),
                  ),
                  error: (error, _) => SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KcSpacing.pageHorizontal,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: KcStatusPanel(
                        icon: Icons.cloud_off_outlined,
                        title: customerCatalogErrorTitle(error),
                        message: customerCatalogErrorMessage(error),
                        action: KcButton(
                          label: 'Coba lagi',
                          onPressed: () =>
                              ref.invalidate(customerCatalogProvider),
                        ),
                      ),
                    ),
                  ),
                  data: (catalog) => CustomerSearchResultsSliver(
                    catalog: catalog,
                    query: query,
                    maxPrice: _maxPrice,
                    onlyAvailable: _onlyAvailable,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: KcSpacing.lg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
