import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/owner/application/owner_order_controller.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_order_rules.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_action_bar.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_dialogs.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_items_card.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_summary_card.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

class OwnerOrderDetailPage extends ConsumerStatefulWidget {
  const OwnerOrderDetailPage({
    super.key,
    required this.accountId,
    required this.orderId,
  });

  final String accountId;
  final String orderId;

  @override
  ConsumerState<OwnerOrderDetailPage> createState() =>
      _OwnerOrderDetailPageState();
}

class _OwnerOrderDetailPageState extends ConsumerState<OwnerOrderDetailPage> {
  var _busy = false;

  OwnerOrderDetailKey get _key =>
      (accountId: widget.accountId, orderId: widget.orderId);

  Future<void> _executeAction(
    OwnerOrderDetail detail,
    OwnerOrderAction action,
  ) async {
    if (_busy) return;
    final summary = detail.summary;
    String? reason;
    var cashReceived = false;
    var foodHandedOver = false;

    switch (action) {
      case OwnerOrderAction.accept:
        final ok = await showOwnerConfirmDialog(
          context,
          title: 'Terima pesanan ${summary.orderNumber}?',
          message:
              'Pesanan akan diproses dan pelanggan tidak lagi dapat membatalkannya.',
          confirmLabel: 'Terima Pesanan',
        );
        if (!ok) return;
      case OwnerOrderAction.reject:
        reason = await showOwnerReasonSheet(
          context,
          title: 'Tolak pesanan ${summary.orderNumber}',
          description:
              'Berikan alasan penolakan yang jelas untuk pelanggan. Pesanan tidak dapat dikembalikan ke antrean aktif.',
          hint: 'Contoh: Bahan menu sedang habis.',
          confirmLabel: 'Tolak Pesanan',
        );
        if (reason == null) return;
      case OwnerOrderAction.ready:
        final ok = await showOwnerConfirmDialog(
          context,
          title: 'Tandai siap diambil?',
          message:
              'Pastikan seluruh pesanan sudah selesai disiapkan. Kode pengambilan akan tampil di aplikasi pelanggan.',
          confirmLabel: 'Siap Diambil',
        );
        if (!ok) return;
      case OwnerOrderAction.failFulfillment:
        reason = await showOwnerReasonSheet(
          context,
          title: 'Pesanan gagal dipenuhi',
          description:
              'Berikan alasan kegagalan pemenuhan pesanan. Pembayaran tetap Belum Lunas.',
          hint: 'Contoh: Stok bahan habis saat dimasak.',
          confirmLabel: 'Konfirmasi Gagal Dipenuhi',
        );
        if (reason == null) return;
      case OwnerOrderAction.complete:
        final ok = await showCompleteOrderConfirmationDialog(
          context,
          orderNumber: summary.orderNumber,
          totalText: formatRupiah(context, summary.totalAmount),
        );
        if (!ok) return;
        cashReceived = true;
        foodHandedOver = true;
      case OwnerOrderAction.notPickedUp:
        final ok = await showOwnerConfirmDialog(
          context,
          title: 'Tandai Tidak Diambil?',
          message:
              'Gunakan hanya jika pelanggan tidak mengambil pesanan. Status menjadi akhir dan pembayaran tetap Belum Lunas.',
          confirmLabel: 'Tandai Tidak Diambil',
          destructive: true,
        );
        if (!ok) return;
      case OwnerOrderAction.failPickup:
        reason = await showOwnerReasonSheet(
          context,
          title: 'Tandai Gagal Diambil',
          description:
              'Gunakan jika pihak kantin tidak dapat menyerahkan pesanan yang sudah Siap Diambil. Status menjadi akhir dan pembayaran tetap Belum Lunas.',
          hint: 'Contoh: Makanan rusak dan tidak tersedia pengganti.',
          confirmLabel: 'Konfirmasi Gagal Diambil',
        );
        if (reason == null) return;
    }

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerOrderControllerProvider)
          .performAction(
            accountId: widget.accountId,
            orderId: widget.orderId,
            action: action,
            reason: reason,
            cashReceived: cashReceived,
            foodHandedOver: foodHandedOver,
          );
      if (!mounted) return;
      showKcSnackBar(context, 'Status pesanan diperbarui: ${action.label}.');
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(ownerOrderDetailProvider(_key));
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal memperbarui status pesanan.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeOrderSyncProvider(widget.accountId));
    final detailAsync = ref.watch(ownerOrderDetailProvider(_key));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _busy
                ? null
                : () => ref.invalidate(ownerOrderDetailProvider(_key)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () =>
              const OwnerLoadingView(message: 'Memuat detail pesanan…'),
          error: (error, _) => OwnerErrorView(
            error: error,
            onRetry: () => ref.invalidate(ownerOrderDetailProvider(_key)),
          ),
          data: (detail) {
            final summary = detail.summary;
            final actions = OwnerOrderRules.allowedActions(summary.status);
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(ownerOrderDetailProvider(_key).future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(KcSpacing.md),
                      children: [
                        OwnerOrderSummaryCard(summary: summary),
                        if (summary.status == OwnerOrderStatus.siapDiambil) ...[
                          const SizedBox(height: KcSpacing.sm),
                          Card(
                            color: theme.colorScheme.secondaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(KcSpacing.sm),
                              child: Text(
                                'Cocokkan nomor pesanan ${summary.orderNumber} atau barcode pelanggan sebelum menyerahkan makanan dan menerima uang tunai.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: KcSpacing.md),
                        Text(
                          'Rincian Pesanan',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: KcSpacing.xs),
                        OwnerOrderItemsCard(
                          items: detail.items,
                          totalAmount: summary.totalAmount,
                        ),
                        if (summary.generalNote.isNotEmpty) ...[
                          const SizedBox(height: KcSpacing.sm),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(KcSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catatan Umum Pesanan',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(summary.generalNote),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (detail.events.isNotEmpty) ...[
                          const SizedBox(height: KcSpacing.md),
                          Text(
                            'Riwayat Status',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: KcSpacing.xs),
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < detail.events.length;
                                  i++
                                ) ...[
                                  if (i > 0) const Divider(height: 1),
                                  ListTile(
                                    title: Text(
                                      detail.events[i].toStatus.label,
                                    ),
                                    subtitle: Text(
                                      [
                                        formatOrderTime(
                                          detail.events[i].createdAt,
                                        ),
                                        if (detail.events[i].reason != null &&
                                            detail.events[i].reason!.isNotEmpty)
                                          'Alasan: ${detail.events[i].reason}',
                                      ].join(' · '),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (actions.isNotEmpty)
                  OwnerOrderActionBar(
                    actions: actions,
                    busy: _busy,
                    onSelectAction: (action) => _executeAction(detail, action),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
