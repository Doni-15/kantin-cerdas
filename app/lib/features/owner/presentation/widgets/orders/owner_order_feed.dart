import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/presentation/widgets/order_record_card.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_load_error.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_mutation_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderFeed extends ConsumerStatefulWidget {
  const OwnerOrderFeed({super.key, this.preview = false});
  final bool preview;
  @override
  ConsumerState<OwnerOrderFeed> createState() => _OwnerOrderFeedState();
}

class _OwnerOrderFeedState extends ConsumerState<OwnerOrderFeed> {
  OrderStatus? _status;
  final List<String?> _cursors = [null];
  @override
  Widget build(BuildContext context) {
    final provider = ownerOrdersProvider((
      status: _status,
      cursor: _cursors.last,
      limit: widget.preview ? 5 : 30,
    ));
    final state = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.preview)
          Wrap(
            spacing: KcSpacing.xs,
            runSpacing: KcSpacing.xs,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _status == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _status = null;
                      _cursors
                        ..clear()
                        ..add(null);
                    });
                  }
                },
              ),
              for (final status in OrderStatus.values)
                ChoiceChip(
                  label: Text(ownerOrderLabel(status)),
                  selected: _status == status,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _status = status;
                        _cursors
                          ..clear()
                          ..add(null);
                      });
                    }
                  },
                ),
            ],
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
                    ref.invalidate(ownerOrdersProvider);
                  },
            icon: const Icon(Icons.refresh),
            label: const Text('Muat ulang'),
          ),
        ),
        if (!widget.preview)
          const OwnerMutationNotice(operationPrefix: 'order:'),
        state.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const KcLoadingSkeleton(
            label: 'Memuat pesanan',
            layout: KcSkeletonLayout.list,
          ),
          error: (error, _) => OwnerLoadError(
            error: error,
            onRetry: () => ref.invalidate(provider),
          ),
          data: (page) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (page.items.isEmpty)
                const KcStatusPanel(
                  title: 'Belum ada pesanan yang sesuai',
                  message:
                      'Pesanan akan muncul di sini setelah diterima layanan.',
                  icon: Icons.receipt_long_outlined,
                ),
              for (final order in page.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: KcSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OrderRecordCard(
                        key: ValueKey(order.id),
                        order: order,
                        showCustomer: true,
                        onOpenDetails: () => context.push(
                          Routes.ownerOrderDetailLocation(order.id),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!widget.preview)
                Wrap(
                  spacing: KcSpacing.xs,
                  runSpacing: KcSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _cursors.length == 1
                          ? null
                          : () => setState(() => _cursors.removeLast()),
                      child: const Text('Sebelumnya'),
                    ),
                    Text('Halaman ${_cursors.length}'),
                    OutlinedButton(
                      onPressed:
                          page.nextCursor == null ||
                              _cursors.contains(page.nextCursor)
                          ? null
                          : () => setState(() => _cursors.add(page.nextCursor)),
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
            child: const Text('Halaman sebelumnya'),
          ),
      ],
    );
  }
}
