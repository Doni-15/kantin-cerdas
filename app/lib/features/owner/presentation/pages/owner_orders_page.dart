import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrdersPage extends StatefulWidget {
  const OwnerOrdersPage({super.key});

  @override
  State<OwnerOrdersPage> createState() => _OwnerOrdersPageState();
}

class _OwnerOrdersPageState extends State<OwnerOrdersPage> {
  _OrderQueue _selectedQueue = _OrderQueue.baru;
  final List<_OwnerOrder> _orders = List.of(_sampleOrders);

  List<_OwnerOrder> get _visibleOrders =>
      _orders.where((order) => order.queue == _selectedQueue).toList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColors = KcStatusColors.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          KcSpacing.pageHorizontal,
          KcSpacing.lg,
          KcSpacing.pageHorizontal,
          KcSpacing.lg,
        ),
        children: [
          Text(
            'Pesanan masuk',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: KcSpacing.xs),
          Text(
            'Kelola antrean dan siapkan pesanan pelanggan.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: KcSpacing.lg),
          Container(
            padding: const EdgeInsets.all(KcSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: colors.primary),
                const SizedBox(width: KcSpacing.sm),
                Expanded(
                  child: Text(
                    '${_orders.length} pesanan dalam antrean',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'Hari ini',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KcSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _OrderQueue.values.map((queue) {
                final count = _orders
                    .where((order) => order.queue == queue)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(right: KcSpacing.xs),
                  child: ChoiceChip(
                    label: Text('${queue.label} · $count'),
                    selected: _selectedQueue == queue,
                    onSelected: (_) => setState(() => _selectedQueue = queue),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: KcSpacing.sm),
          Text(
            '${_selectedQueue.label} (${_visibleOrders.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: KcSpacing.sm),
          for (final order in _visibleOrders) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(KcSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.id,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          order.time,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: KcSpacing.sm),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.secondaryContainer,
                          foregroundColor: colors.onSecondaryContainer,
                          child: Text(order.customer[0]),
                        ),
                        const SizedBox(width: KcSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customer,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${order.portions} porsi · Tunai saat mengambil',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KcSpacing.md),
                    Divider(color: colors.outlineVariant),
                    const SizedBox(height: KcSpacing.sm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KcSpacing.sm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: order.queue.containerColor(statusColors),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            order.queue.statusLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: order.queue.foregroundColor(
                                    statusColors,
                                  ),
                                ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          order.total,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: KcSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showOrderSummary(context, order),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Lihat ringkasan'),
                      ),
                    ),
                    const SizedBox(height: KcSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _editOrderStatus(order),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Ubah status'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KcSpacing.sm),
          ],
        ],
      ),
    );
  }

  Future<void> _editOrderStatus(_OwnerOrder order) async {
    final newQueue = await showModalBottomSheet<_OrderQueue>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KcSpacing.lg,
              KcSpacing.sm,
              KcSpacing.lg,
              KcSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah status pesanan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: KcSpacing.xs),
                Text(
                  order.id,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KcSpacing.sm),
                for (final queue in _OrderQueue.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(queue.statusLabel),
                    trailing: order.queue == queue
                        ? Icon(Icons.check, color: colors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(queue),
                  ),
                const SizedBox(height: KcSpacing.xs),
                Text(
                  'Perubahan demo ini hanya tersimpan selama aplikasi berjalan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newQueue == null || newQueue == order.queue || !mounted) return;

    setState(() {
      final orderIndex = _orders.indexWhere((item) => item.id == order.id);
      if (orderIndex != -1) {
        _orders[orderIndex] = order.copyWith(queue: newQueue);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.id} diperbarui: ${newQueue.statusLabel}'),
      ),
    );
  }

  void _showOrderSummary(BuildContext context, _OwnerOrder order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KcSpacing.lg,
              KcSpacing.sm,
              KcSpacing.lg,
              KcSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan pesanan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: KcSpacing.xs),
                Text(
                  '${order.id} · ${order.time}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KcSpacing.lg),
                _SummaryRow(label: 'Pelanggan', value: order.customer),
                _SummaryRow(label: 'Jumlah', value: '${order.portions} porsi'),
                _SummaryRow(label: 'Pembayaran', value: 'Tunai saat mengambil'),
                const Divider(height: KcSpacing.lg),
                _SummaryRow(
                  label: 'Total',
                  value: order.total,
                  isEmphasized: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _OrderQueue { baru, diproses, siap }

extension on _OrderQueue {
  String get label => switch (this) {
    _OrderQueue.baru => 'Baru',
    _OrderQueue.diproses => 'Diproses',
    _OrderQueue.siap => 'Siap',
  };

  String get statusLabel => switch (this) {
    _OrderQueue.baru => 'Menunggu konfirmasi',
    _OrderQueue.diproses => 'Diproses',
    _OrderQueue.siap => 'Siap diambil',
  };

  Color foregroundColor(KcStatusColors colors) => switch (this) {
    _OrderQueue.baru => colors.warning,
    _OrderQueue.diproses => colors.info,
    _OrderQueue.siap => colors.success,
  };

  Color containerColor(KcStatusColors colors) => switch (this) {
    _OrderQueue.baru => colors.warningContainer,
    _OrderQueue.diproses => colors.infoContainer,
    _OrderQueue.siap => colors.successContainer,
  };
}

class _OwnerOrder {
  const _OwnerOrder({
    required this.id,
    required this.customer,
    required this.portions,
    required this.total,
    required this.time,
    required this.queue,
  });

  final String id;
  final String customer;
  final int portions;
  final String total;
  final String time;
  final _OrderQueue queue;

  _OwnerOrder copyWith({_OrderQueue? queue}) => _OwnerOrder(
    id: id,
    customer: customer,
    portions: portions,
    total: total,
    time: time,
    queue: queue ?? this.queue,
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final style = isEmphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KcSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style?.copyWith(
                color: isEmphasized
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}

const _sampleOrders = [
  _OwnerOrder(
    id: 'KC-027',
    customer: 'Doni',
    portions: 2,
    total: 'Rp30.000',
    time: '12.05',
    queue: _OrderQueue.baru,
  ),
  _OwnerOrder(
    id: 'KC-028',
    customer: 'Ayu',
    portions: 1,
    total: 'Rp18.000',
    time: '12.05',
    queue: _OrderQueue.baru,
  ),
  _OwnerOrder(
    id: 'KC-029',
    customer: 'Bima',
    portions: 2,
    total: 'Rp24.000',
    time: '12.06',
    queue: _OrderQueue.baru,
  ),
  _OwnerOrder(
    id: 'KC-025',
    customer: 'Raka',
    portions: 1,
    total: 'Rp12.000',
    time: '11.58',
    queue: _OrderQueue.diproses,
  ),
  _OwnerOrder(
    id: 'KC-026',
    customer: 'Sari',
    portions: 1,
    total: 'Rp18.000',
    time: '12.01',
    queue: _OrderQueue.diproses,
  ),
  _OwnerOrder(
    id: 'KC-024',
    customer: 'Dita',
    portions: 2,
    total: 'Rp23.000',
    time: '12.03',
    queue: _OrderQueue.siap,
  ),
];
