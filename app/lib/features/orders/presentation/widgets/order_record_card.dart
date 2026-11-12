import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/utils/wib_date_formatter.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/features/orders/presentation/mappers/order_labels.dart';

/// Kartu snapshot pesanan dapat digunakan oleh customer dan owner.
class OrderRecordCard extends StatelessWidget {
  const OrderRecordCard({
    super.key,
    required this.order,
    this.showCustomer = false,
    this.initiallyExpanded = false,
    this.onOpenDetails,
  });
  final OrderRecord order;
  final bool showCustomer;
  final bool initiallyExpanded;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = orderStatusLabel(order.status);
    final payment = orderPaymentLabel(order.paymentStatus);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        key: PageStorageKey('order:${order.id}:${order.version}'),
        tilePadding: const EdgeInsets.all(KcSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          KcSpacing.md,
          0,
          KcSpacing.md,
          KcSpacing.md,
        ),
        title: Text(order.orderNumber, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KcSpacing.xs),
            Text(order.stallName),
            if (showCustomer) Text(order.customerName),
            Text(formatWib(order.createdAt)),
            const SizedBox(height: KcSpacing.xs),
            Text(status, style: theme.textTheme.labelLarge),
            Text(formatRupiah(order.totalPriceIdr)),
            if (onOpenDetails != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Buka detail'),
                ),
              ),
          ],
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Rincian pesanan', style: theme.textTheme.titleSmall),
              for (final item in order.items) ...[
                const SizedBox(height: KcSpacing.sm),
                Text('${item.quantity} × ${item.name}'),
                Text(
                  '${formatRupiah(item.unitPriceIdr)} / porsi · ${formatRupiah(item.subtotal)}',
                ),
                if (item.note.isNotEmpty) Text('Catatan: ${item.note}'),
              ],
              const Divider(height: KcSpacing.lg),
              Text(
                'Total: ${formatRupiah(order.totalPriceIdr)}',
                style: theme.textTheme.titleMedium,
              ),
              Text('Pembayaran: $payment'),
              if (order.note.isNotEmpty) Text('Catatan pesanan: ${order.note}'),
              if (order.rejectionReason?.trim().isNotEmpty ?? false)
                Text('Alasan: ${order.rejectionReason}'),
              if (order.status == OrderStatus.ready && !showCustomer)
                const Text(
                  'Tunjukkan nomor pesanan saat mengambil makanan di stan.',
                ),
              const SizedBox(height: KcSpacing.xs),
              Text(
                'Diperbarui ${formatWib(order.updatedAt)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
