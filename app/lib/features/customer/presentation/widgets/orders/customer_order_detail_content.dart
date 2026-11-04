import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_order_cancellation_actions.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/presentation/mappers/order_labels.dart';
import 'package:kantin_cerdas/features/orders/presentation/widgets/order_record_card.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrderDetailContent extends StatelessWidget {
  const CustomerOrderDetailContent({super.key, required this.order});
  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KcStatusPanel(
          title: orderStatusLabel(order.status),
          message: orderNextStep(order.status),
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: KcSpacing.md),
        OrderRecordCard(
          key: ValueKey('order-card:${order.id}:${order.version}'),
          order: order,
          initiallyExpanded: true,
        ),
        const SizedBox(height: KcSpacing.md),
        Text('ID pesanan', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: KcSpacing.xs),
        SelectableText(order.id),
        const SizedBox(height: KcSpacing.sm),
        const Text(
          'Status dan pembayaran di atas berasal dari pembacaan terakhir. '
          'Gunakan Muat ulang untuk memeriksa perubahan.',
        ),
        const SizedBox(height: KcSpacing.md),
        CustomerOrderCancellationActions(
          key: ValueKey('order-cancellation:${order.id}:${order.version}'),
          order: order,
        ),
      ],
    );
  }
}
