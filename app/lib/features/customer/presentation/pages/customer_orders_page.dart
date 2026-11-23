import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/application/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_order_list_widgets.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrdersPage extends ConsumerStatefulWidget {
  const CustomerOrdersPage({
    super.key,
    required this.accountId,
    required this.onExploreCatalog,
  });

  final String accountId;
  final VoidCallback onExploreCatalog;

  @override
  ConsumerState<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends ConsumerState<CustomerOrdersPage> {
  var _activeTab = true;

  @override
  Widget build(BuildContext context) {
    final key = (accountId: widget.accountId, activeOnly: _activeTab);
    final ordersAsync = ref.watch(customerOrdersProvider(key));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KcSpacing.md),
              child: Text(
                'Pantau pesanan berjalan atau lihat riwayat pesanan Anda.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: KcSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KcSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: CustomerOrderScopeTab(
                      label: 'Aktif',
                      selected: _activeTab,
                      onTap: () => setState(() => _activeTab = true),
                    ),
                  ),
                  Expanded(
                    child: CustomerOrderScopeTab(
                      label: 'Riwayat',
                      selected: !_activeTab,
                      onTap: () => setState(() => _activeTab = false),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => CustomerErrorView(
                  error: error,
                  fallback: 'Daftar pesanan tidak dapat dimuat.',
                  onRetry: () => ref.invalidate(customerOrdersProvider(key)),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref
                            .read(customerOrderControllerProvider)
                            .refreshOrders(widget.accountId);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 360,
                            child: _activeTab
                                ? CustomerEmptyView(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Belum ada pesanan aktif',
                                    subtitle:
                                        'Pilih menu dari kantin untuk membuat pesanan baru.',
                                    action: FilledButton(
                                      onPressed: widget.onExploreCatalog,
                                      child: const Text('Jelajahi Kantin'),
                                    ),
                                  )
                                : const CustomerEmptyView(
                                    icon: Icons.history,
                                    title: 'Belum ada riwayat pesanan',
                                    subtitle:
                                        'Pesanan yang selesai atau berakhir akan tersimpan di sini.',
                                  ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref
                          .read(customerOrderControllerProvider)
                          .refreshOrders(widget.accountId);
                      await ref.read(customerOrdersProvider(key).future);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        KcSpacing.md,
                        KcSpacing.sm,
                        KcSpacing.md,
                        KcSpacing.lg * 2,
                      ),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: KcSpacing.xs),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return CustomerOrderListCard(
                          order: order,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CustomerOrderDetailPage(
                                  accountId: widget.accountId,
                                  orderId: order.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
