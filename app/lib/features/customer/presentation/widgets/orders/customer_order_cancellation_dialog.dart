import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrderCancellationDialog extends StatelessWidget {
  const CustomerOrderCancellationDialog({
    super.key,
    required this.orderNumber,
    required this.stallName,
  });
  final String orderNumber;
  final String stallName;
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Batalkan pesanan?'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pesanan $orderNumber'),
          Text(stallName),
          const SizedBox(height: KcSpacing.md),
          const Text(
            'Pembatalan hanya dapat dilakukan selama pesanan belum diproses stan. '
            'Pesanan yang berhasil dibatalkan tidak dapat dilanjutkan kembali.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Tetap pesan'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Batalkan pesanan'),
      ),
    ],
  );
}
