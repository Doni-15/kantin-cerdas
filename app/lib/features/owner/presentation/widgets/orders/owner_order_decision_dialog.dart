import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderDecisionDialog extends ConsumerStatefulWidget {
  const OwnerOrderDecisionDialog({
    super.key,
    required this.order,
    required this.target,
    required this.ownerId,
    required this.sessionGeneration,
  });
  final OrderRecord order;
  final OrderStatus target;
  final String ownerId;
  final int sessionGeneration;

  @override
  ConsumerState<OwnerOrderDecisionDialog> createState() =>
      _OwnerOrderDecisionDialogState();
}

class _OwnerOrderDecisionDialogState
    extends ConsumerState<OwnerOrderDecisionDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final AuthStateNotifier _session;
  bool _cash = false;
  bool _food = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _session = ref.read(authStateProvider.notifier);
  }

  bool _validSession() {
    final auth = ref.read(authStateProvider);
    return auth.activeOwnerId == widget.ownerId &&
        identical(_session, ref.read(authStateProvider.notifier)) &&
        _session.sessionGeneration == widget.sessionGeneration;
  }

  void _close([OwnerOrderTransition? result]) {
    if (!mounted || _closing || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _closing = true;
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    ref.listen(authStateProvider, (_, _) {
      if (!_validSession()) {
        _close();
      }
    });
    if (!_validSession()) {
      return AlertDialog(
        title: const Text('Sesi berubah'),
        content: const Text(
          'Buka kembali pesanan dari akun yang sedang aktif.',
        ),
        actions: [TextButton(onPressed: _close, child: const Text('Tutup'))],
      );
    }
    final rejecting = widget.target == OrderStatus.rejected;
    final completing = widget.target == OrderStatus.completed;
    final (title, action, explanation) = switch (widget.target) {
      OrderStatus.processing => (
        'Terima pesanan?',
        'Terima pesanan',
        'Pastikan semua menu dan jumlah yang diminta dapat disiapkan.',
      ),
      OrderStatus.ready => (
        'Pesanan siap diambil?',
        'Tandai siap',
        'Pastikan seluruh makanan sudah siap sebelum memberi tahu pelanggan.',
      ),
      OrderStatus.rejected => (
        'Tolak pesanan?',
        'Tolak pesanan',
        'Jelaskan alasan penolakan agar pelanggan mengetahui kendalanya.',
      ),
      OrderStatus.completed => (
        'Selesaikan pesanan?',
        'Selesaikan pesanan',
        'Cocokkan nomor pesanan dengan pelanggan. Centang kedua konfirmasi setelah serah terima dilakukan.',
      ),
      _ => (
        'Status tidak dapat diubah',
        'Konfirmasi',
        'Muat ulang dan periksa status pesanan terbaru.',
      ),
    };
    return AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.order.orderNumber} · ${widget.order.customerName}'),
            Text('Total ${formatRupiah(widget.order.totalPriceIdr)}'),
            const SizedBox(height: KcSpacing.sm),
            Text(explanation),
            const SizedBox(height: KcSpacing.sm),
            if (rejecting)
              TextFormField(
                controller: _reason,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Alasan penolakan',
                ),
                validator: (value) {
                  final reason = value?.trim() ?? '';
                  return reason.isEmpty
                      ? 'Alasan wajib diisi.'
                      : reason.characters.length > 300
                      ? 'Maksimal 300 karakter.'
                      : null;
                },
              ),
            if (completing) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Uang ${formatRupiah(widget.order.totalPriceIdr)} sudah diterima',
                ),
                value: _cash,
                onChanged: (value) => setState(() => _cash = value ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Seluruh makanan sudah diserahkan'),
                value: _food,
                onChanged: (value) => setState(() => _food = value ?? false),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _close, child: const Text('Batal')),
        FilledButton(
          onPressed:
              !OwnerOrderTransition.canMoveTo(widget.order, widget.target) ||
                  (completing && (!_cash || !_food))
              ? null
              : () {
                  if (!_validSession()) {
                    _close();
                    return;
                  }
                  if (!(_form.currentState?.validate() ?? false)) {
                    return;
                  }
                  _close(
                    OwnerOrderTransition(
                      orderId: widget.order.id,
                      status: widget.target,
                      expectedVersion: widget.order.version,
                      reason: _reason.text,
                      cashReceived: _cash,
                      foodHandedOver: _food,
                    ),
                  );
                },
          child: Text(action),
        ),
      ],
    );
  }
}
