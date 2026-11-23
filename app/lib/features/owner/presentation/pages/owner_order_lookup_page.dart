import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/owner/application/owner_order_controller.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_order_detail_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderLookupPage extends ConsumerStatefulWidget {
  const OwnerOrderLookupPage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<OwnerOrderLookupPage> createState() =>
      _OwnerOrderLookupPageState();
}

class _OwnerOrderLookupPageState extends ConsumerState<OwnerOrderLookupPage> {
  final _codeController = TextEditingController();
  var _busy = false;
  String? _error;
  OwnerOrderDetail? _found;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookup(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _found = null;
    });
    try {
      final result = await ref
          .read(ownerOrderControllerProvider)
          .lookupByCode(accountId: widget.accountId, code: code);
      if (!mounted) return;
      setState(() => _found = result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = presentAppError(
          error,
          fallback: 'Pesanan tidak ditemukan atau terjadi kesalahan.',
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanCode128() async {
    if (_busy) return;
    final scanned = await ref.read(ownerBarcodeScannerProvider)();
    if (!mounted) return;
    if (scanned == null || scanned.trim().isEmpty) {
      setState(() {
        _error =
            'Pemindai kamera Code 128 belum tersedia pada perangkat ini. Masukkan nomor pesanan secara manual.';
      });
      return;
    }
    _codeController.text = scanned.trim();
    await _lookup(scanned);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cari & Pindai Pesanan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KcSpacing.md),
          children: [
            Text(
              'Masukkan nomor pesanan atau pindai barcode Code 128 milik pelanggan. Pemindaian hanya menampilkan pesanan tanpa mengubah status atau pembayaran.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            TextField(
              controller: _codeController,
              maxLength: 40,
              textInputAction: TextInputAction.search,
              onSubmitted: _lookup,
              decoration: InputDecoration(
                labelText: 'Nomor Pesanan (Code 128)',
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: 'Pindai Code 128',
                  onPressed: _busy ? null : _scanCode128,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ),
            ),
            const SizedBox(height: KcSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _lookup(_codeController.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Cari Pesanan'),
                  ),
                ),
                const SizedBox(width: KcSpacing.xs),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _scanCode128,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pindai'),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: KcSpacing.md),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: KcSpacing.md),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(KcSpacing.md),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            if (_found case final OwnerOrderDetail order) ...[
              const SizedBox(height: KcSpacing.md),
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
                              order.summary.orderNumber,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: KcSpacing.xs),
                          OwnerStatusBadge.forOrderStatus(
                            context,
                            order.summary.status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Pelanggan: ${order.summary.customerName}'),
                      const SizedBox(height: 4),
                      Text(
                        '${order.summary.itemSummary} · ${formatRupiah(context, order.summary.totalAmount)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: KcSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => OwnerOrderDetailPage(
                                accountId: widget.accountId,
                                orderId: order.summary.id,
                              ),
                            ),
                          ),
                          child: const Text('Lihat Detail Pesanan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
