import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_feature_error.dart';
import 'package:kantin_cerdas/features/orders/presentation/widgets/order_record_card.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrderFeed extends ConsumerStatefulWidget {
  const CustomerOrderFeed({super.key, required this.history});
  final bool history;
  @override
  ConsumerState<CustomerOrderFeed> createState() => _CustomerOrderFeedState();
}

class _CustomerOrderFeedState extends ConsumerState<CustomerOrderFeed> {
  final List<String?> _cursors = [null];
  @override
  void didUpdateWidget(covariant CustomerOrderFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _cursors
        ..clear()
        ..add(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = customerOrderFeedProvider((
      history: widget.history,
      cursor: _cursors.last,
    ));
    final state = ref.watch(provider);
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(KcSpacing.lg),
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.history ? 'Riwayat pesanan' : 'Pesanan aktif',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: KcSpacing.xs),
            Text(
              widget.history
                  ? 'Lihat pesanan yang selesai, ditolak, atau dibatalkan.'
                  : 'Pantau pesananmu sampai siap diambil.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        setState(() {
                          _cursors
                            ..clear()
                            ..add(null);
                        });
                        ref.invalidate(customerOrderFeedProvider);
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang'),
              ),
            ),
            const SizedBox(height: KcSpacing.sm),
            state.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const KcLoadingSkeleton(
                label: 'Memuat pesanan',
                layout: KcSkeletonLayout.list,
              ),
              error: (error, _) => CustomerFeatureError(
                error: error,
                onRetry: () => ref.invalidate(provider),
              ),
              data: (page) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (page.items.isEmpty)
                    KcStatusPanel(
                      title: widget.history
                          ? 'Belum ada riwayat di halaman ini'
                          : 'Belum ada pesanan aktif di halaman ini',
                      message: 'Pesanan yang sesuai akan muncul di sini.',
                      icon: Icons.receipt_long_outlined,
                      action: KcButton(
                        label: 'Lihat menu',
                        onPressed: () => context.go(Routes.customerHome),
                      ),
                    )
                  else
                    for (final order in page.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: KcSpacing.sm),
                        child: OrderRecordCard(
                          key: ValueKey(order.id),
                          order: order,
                          onOpenDetails: () => context.push(
                            Routes.customerOrderDetailLocation(order.id),
                          ),
                        ),
                      ),
                  Wrap(
                    spacing: KcSpacing.xs,
                    runSpacing: KcSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _cursors.length == 1
                            ? null
                            : () {
                                setState(() => _cursors.removeLast());
                              },
                        child: const Text('Sebelumnya'),
                      ),
                      Text('Halaman ${_cursors.length}'),
                      OutlinedButton(
                        onPressed:
                            page.nextCursor == null ||
                                _cursors.contains(page.nextCursor)
                            ? null
                            : () {
                                setState(() => _cursors.add(page.nextCursor));
                              },
                        child: const Text('Selanjutnya'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (state.hasError && _cursors.length > 1)
              TextButton(
                onPressed: () => setState(() => _cursors.removeLast()),
                child: const Text('Kembali ke halaman sebelumnya'),
              ),
          ],
        ),
      ),
    );
  }
}
