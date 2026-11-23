import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/customer/application/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/code128_barcode_widget.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_order_detail_widgets.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrderDetailPage extends ConsumerStatefulWidget {
  const CustomerOrderDetailPage({
    super.key,
    required this.accountId,
    required this.orderId,
    this.syncInterval = const Duration(seconds: 8),
  });

  final String accountId;
  final String orderId;
  final Duration? syncInterval;

  @override
  ConsumerState<CustomerOrderDetailPage> createState() =>
      _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState
    extends ConsumerState<CustomerOrderDetailPage> {
  Timer? _syncTimer;
  var _cancelling = false;

  @override
  void initState() {
    super.initState();
    final interval = widget.syncInterval;
    if (interval != null) {
      _syncTimer = Timer.periodic(interval, (_) {
        if (!mounted) return;
        if (ref.read(realtimeOrderSyncProvider(widget.accountId)).isLive) {
          return;
        }
        final current = ref
            .read(
              customerOrderDetailProvider((
                accountId: widget.accountId,
                orderId: widget.orderId,
              )),
            )
            .asData
            ?.value;
        if (current != null && current.summary.status.isActive) {
          ref
              .read(customerOrderControllerProvider)
              .refreshOrderDetail(widget.accountId, widget.orderId);
        }
      });
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _cancelOrder(CustomerOrderDetail detail) async {
    if (_cancelling || !detail.summary.status.canCancel) return;
    final confirmed = await showCustomerConfirmDialog(
      context,
      title: 'Batalkan pesanan ${detail.summary.orderNumber}?',
      message:
          'Pesanan yang masih menunggu konfirmasi akan dibatalkan permanen.',
      confirmLabel: 'Ya, Batalkan',
      destructive: true,
    );
    if (!mounted || !confirmed) return;

    setState(() => _cancelling = true);
    try {
      await ref
          .read(customerOrderControllerProvider)
          .cancelOrder(accountId: widget.accountId, orderId: widget.orderId);
      if (!mounted) return;
      showCustomerSnackBar(context, 'Pesanan berhasil dibatalkan.');
    } catch (error) {
      if (!mounted) return;
      ref
          .read(customerOrderControllerProvider)
          .refreshOrderDetail(widget.accountId, widget.orderId);
      showCustomerSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal membatalkan pesanan.'),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeOrderSyncProvider(widget.accountId));
    final key = (accountId: widget.accountId, orderId: widget.orderId);
    final detailAsync = ref.watch(customerOrderDetailProvider(key));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => CustomerErrorView(
            error: error,
            fallback: 'Detail pesanan tidak dapat dimuat.',
            onRetry: () => ref.invalidate(customerOrderDetailProvider(key)),
          ),
          data: (detail) => _buildBody(context, detail, key),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomerOrderDetail detail,
    CustomerOrderDetailKey key,
  ) {
    final theme = Theme.of(context);
    final summary = detail.summary;

    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(customerOrderControllerProvider)
            .refreshOrderDetail(widget.accountId, widget.orderId);
        await ref.read(customerOrderDetailProvider(key).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KcSpacing.md),
        children: [
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
                          'Pesanan ${summary.orderNumber}',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      CustomerStatusChip.orderStatus(context, summary.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(summary.stallName, style: theme.textTheme.titleMedium),
                  if (summary.status == CustomerOrderStatus.diproses &&
                      summary.prepEstimateMinutes != null &&
                      summary.prepEstimateMinutes! > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Estimasi persiapan dari kantin: ± ${summary.prepEstimateMinutes} menit (informatif)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (summary.terminalAt != null &&
                      summary.status.isTerminal) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Waktu kejadian akhir: ${formatCustomerTimestamp(summary.terminalAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (summary.statusReason != null &&
              summary.statusReason!.trim().isNotEmpty) ...[
            const SizedBox(height: KcSpacing.sm),
            Container(
              padding: const EdgeInsets.all(KcSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(KcRadius.small),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.status == CustomerOrderStatus.gagalDiambil
                        ? 'Alasan Gagal Diambil dari Pemilik Kantin'
                        : 'Alasan dari Pemilik Kantin',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.statusReason!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (summary.status.showBarcode) ...[
            const SizedBox(height: KcSpacing.md),
            Code128BarcodeCard(value: summary.orderNumber),
          ],
          const SizedBox(height: KcSpacing.md),
          Text('Timeline Status', style: theme.textTheme.titleMedium),
          const SizedBox(height: KcSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KcSpacing.sm),
              child: detail.events.isEmpty
                  ? const Text('Belum ada riwayat kejadian.')
                  : Column(
                      children: [
                        for (var i = 0; i < detail.events.length; i++) ...[
                          if (i > 0) const Divider(height: KcSpacing.sm),
                          CustomerOrderTimelineRow(event: detail.events[i]),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: KcSpacing.md),
          Text('Ringkasan Item', style: theme.textTheme.titleMedium),
          const SizedBox(height: KcSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KcSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < detail.items.length; i++) ...[
                    if (i > 0) const Divider(height: KcSpacing.sm),
                    CustomerOrderSnapshotItemRow(item: detail.items[i]),
                  ],
                  if (summary.generalNote.isNotEmpty) ...[
                    const Divider(height: KcSpacing.md),
                    Text(
                      'Catatan pesanan: ${summary.generalNote}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const Divider(height: KcSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium),
                      Text(
                        formatRupiah(summary.totalAmount),
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KcSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KcSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengambilan & Pembayaran',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lokasi pengambilan: ${summary.stallName} (Blok ${summary.stallBlock})',
                  ),
                  const SizedBox(height: 4),
                  const Text('Metode: Bayar tunai saat mengambil makanan'),
                  const SizedBox(height: 4),
                  Text(
                    'Status Pembayaran: ${summary.paymentStatus.label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (summary.status.canCancel) ...[
            const SizedBox(height: KcSpacing.md),
            OutlinedButton.icon(
              onPressed: _cancelling ? null : () => _cancelOrder(detail),
              icon: const Icon(Icons.cancel_outlined),
              label: _cancelling
                  ? const Text('Membatalkan...')
                  : const Text('Batalkan Pesanan'),
            ),
          ],
        ],
      ),
    );
  }
}
