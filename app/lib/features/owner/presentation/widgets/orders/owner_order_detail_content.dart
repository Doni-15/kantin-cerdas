import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/presentation/mappers/order_labels.dart';
import 'package:kantin_cerdas/features/orders/presentation/widgets/order_record_card.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/orders/owner_order_actions.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderDetailContent extends StatelessWidget {
  const OwnerOrderDetailContent({super.key, required this.order});
  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final guidance = switch (order.status) {
      OrderStatus.waiting =>
        'Periksa menu, jumlah, dan catatan pelanggan sebelum menerima atau menolak pesanan.',
      OrderStatus.processing =>
        'Siapkan makanan sesuai rincian. Tandai siap diambil setelah seluruh pesanan siap.',
      OrderStatus.ready =>
        'Cocokkan nomor pesanan saat pengambilan. Selesaikan setelah uang diterima dan makanan diserahkan.',
      OrderStatus.completed =>
        'Pesanan sudah selesai. Status pembayaran tercantum pada rincian.',
      OrderStatus.rejected =>
        'Pesanan ditolak dan tidak ditagihkan. Alasan penolakan tercantum pada rincian.',
      OrderStatus.cancelled =>
        'Pesanan dibatalkan dan tidak ditagihkan. Tidak ada tindakan lanjutan untuk pesanan ini.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KcStatusPanel(
          title: orderStatusLabel(order.status),
          message: guidance,
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: KcSpacing.md),
        OrderRecordCard(
          key: ValueKey('${order.id}:${order.version}'),
          order: order,
          showCustomer: true,
          initiallyExpanded: true,
        ),
        const SizedBox(height: KcSpacing.md),
        const Text(
          'Rincian ini berasal dari pembacaan terakhir. '
          'Muat ulang untuk memeriksa perubahan pesanan.',
        ),
        const SizedBox(height: KcSpacing.md),
        OwnerOrderActions(order: order),
      ],
    );
  }
}
