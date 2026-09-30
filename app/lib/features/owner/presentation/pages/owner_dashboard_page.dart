import 'package:flutter/material.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({
    super.key,
    required this.ownerName,
  });

  final String ownerName;

  @override
  State<OwnerDashboardPage> createState() =>
      _OwnerDashboardPageState();
}

class _OwnerDashboardPageState
    extends State<OwnerDashboardPage> {
  bool _isStallOpen = true;

  final List<_DashboardOrder> _latestOrders = const [
    _DashboardOrder(
      number: 'KC-027',
      customerName: 'Doni',
      time: '12.05',
      totalPortion: 2,
      totalPrice: 'Rp30.000',
    ),
    _DashboardOrder(
      number: 'KC-028',
      customerName: 'Ayu',
      time: '12.05',
      totalPortion: 1,
      totalPrice: 'Rp18.000',
    ),
    _DashboardOrder(
      number: 'KC-029',
      customerName: 'Raka',
      time: '12.10',
      totalPortion: 3,
      totalPrice: 'Rp42.000',
    ),
  ];

  Future<void> _changeStallStatus(bool value) async {
    // Jika stan ingin dibuka kembali,
    // tidak perlu konfirmasi.
    if (value) {
      setState(() {
        _isStallOpen = true;
      });

      return;
    }

    // Jika ingin menutup stan,
    // tampilkan dialog konfirmasi.
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Tutup stan sementara?',
          ),
          content: const Text(
            'Pesanan baru akan dinonaktifkan. '
            'Enam pesanan yang sudah masuk tetap perlu ditangani.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            24,
            0,
            24,
            20,
          ),
          actions: [
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                        true,
                      );
                    },
                    child: const Text(
                      'Tutup stan',
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Tetap buka',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _isStallOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          24,
        ),
        children: [
          // =======================================================
          // HEADER
          // =======================================================

          Text(
            'Dapur Bu Rina',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Selamat siang, ${widget.ownerName}',
            style: theme.textTheme.headlineLarge,
          ),

          const SizedBox(height: 16),

          // =======================================================
          // STATUS STAN
          // =======================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isStallOpen
                            ? 'Stan buka'
                            : 'Stan tutup',
                        style: theme.textTheme.titleSmall,
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _isStallOpen
                            ? 'Menerima pesanan baru'
                            : 'Pesanan baru dinonaktifkan',
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: _isStallOpen,
                  activeTrackColor:
                      theme.colorScheme.tertiary,
                  activeThumbColor:
                      theme.colorScheme.onTertiary,
                  onChanged: _changeStallStatus,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =======================================================
          // PESANAN PERLU DIKONFIRMASI
          // =======================================================

          InkWell(
            onTap: () {
              // Nanti dapat diarahkan ke halaman Pesanan.
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3 pesanan perlu dikonfirmasi',
                          style:
                              theme.textTheme.titleMedium,
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _isStallOpen
                              ? 'Tangani dari yang paling lama menunggu.'
                              : 'Pesanan yang masuk tetap perlu diproses.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // =======================================================
          // HARI INI
          // =======================================================

          Text(
            'Hari ini',
            style: theme.textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatisticCard(
                  value: '24',
                  label: 'Total pesanan',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _StatisticCard(
                  value: '18',
                  label: 'Selesai',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _StatisticCard(
                  value: '2',
                  label: 'Diproses',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _StatisticCard(
                  value: '1',
                  label: 'Siap diambil',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // =======================================================
          // ANTREAN TERBARU
          // =======================================================

          Row(
            children: [
              Expanded(
                child: Text(
                  'Antrean terbaru',
                  style: theme.textTheme.titleLarge,
                ),
              ),

              TextButton(
                onPressed: () {
                  // Nanti diarahkan ke halaman Pesanan.
                },
                child: const Text(
                  'Lihat semua',
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ...List.generate(
            _latestOrders.length,
            (index) {
              final order = _latestOrders[index];

              return _OrderQueueItem(
                queueNumber: index + 1,
                order: order,
                onDetail: () {
                  // Nanti diarahkan ke detail pesanan.
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// =================================================================
// KARTU STATISTIK
// =================================================================

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 88,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 26,
            ),
          ),

          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// ITEM ANTREAN
// =================================================================

class _OrderQueueItem extends StatelessWidget {
  const _OrderQueueItem({
    required this.queueNumber,
    required this.order,
    required this.onDetail,
  });

  final int queueNumber;
  final _DashboardOrder order;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // NOMOR ANTREAN
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$queueNumber',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // NOMOR PESANAN + NAMA CUSTOMER
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.number,
                      style: theme.textTheme.titleMedium,
                    ),

                    const SizedBox(height: 2),

                    Text(
                      order.customerName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // WAKTU
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.time,
                  style:
                      theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF805500),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.totalPortion} porsi · ${order.totalPrice}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              TextButton(
                onPressed: onDetail,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat detail →',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// DATA DUMMY DASHBOARD
// =================================================================

class _DashboardOrder {
  const _DashboardOrder({
    required this.number,
    required this.customerName,
    required this.time,
    required this.totalPortion,
    required this.totalPrice,
  });

  final String number;
  final String customerName;
  final String time;
  final int totalPortion;
  final String totalPrice;
}