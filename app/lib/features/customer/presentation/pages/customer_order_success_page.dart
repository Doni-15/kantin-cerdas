import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/customer/presentation/utils/rupiah_formatter.dart';

class CustomerOrderSuccessPage extends StatelessWidget {
  const CustomerOrderSuccessPage({
    super.key,
    required this.orderNumber,
    required this.stallName,
    required this.block,
    required this.totalQuantity,
    required this.totalPrice,
  });

  final String orderNumber;
  final String stallName;
  final String block;

  final int totalQuantity;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = TimeOfDay.now();

    final time =
        '${now.hour.toString().padLeft(2, '0')}.'
        '${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // ICON BERHASIL
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: theme
                      .colorScheme
                      .onTertiaryContainer,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Pesanan berhasil dibuat',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Menunggu konfirmasi $stallName.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // NOMOR PESANAN
              Text(
                orderNumber,
                style:
                    theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Nomor pesananmu',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // DETAIL PESANAN
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainer,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: stallName,
                      value: block,
                    ),

                    const SizedBox(height: 16),

                    _SummaryRow(
                      label: 'Dibuat pukul',
                      value: time,
                    ),

                    const SizedBox(height: 16),

                    _SummaryRow(
                      label: '$totalQuantity porsi',
                      value: formatRupiah(
                        totalPrice,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const _SummaryRow(
                      label: 'Pembayaran',
                      value: 'Tunai di konter',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Tunggu status Siap diambil sebelum menuju konter.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Nanti diarahkan ke detail / pantau pesanan.
                  },
                  child: const Text(
                    'Pantau pesanan',
                  ),
                ),
              ),

              const SizedBox(height: 4),

              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  );
                },
                child: const Text(
                  'Kembali ke beranda',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),

        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}