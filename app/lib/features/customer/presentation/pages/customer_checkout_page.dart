import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/customer/application/customer_checkout_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_checkout_widgets.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerCheckoutPage extends ConsumerStatefulWidget {
  const CustomerCheckoutPage({
    super.key,
    required this.accountId,
    required this.initialCart,
    this.onOrderCompleted,
  });

  final String accountId;
  final CustomerCart initialCart;
  final ValueChanged<String>? onOrderCompleted;

  @override
  ConsumerState<CustomerCheckoutPage> createState() =>
      _CustomerCheckoutPageState();
}

class _CustomerCheckoutPageState extends ConsumerState<CustomerCheckoutPage> {
  var _submitting = false;
  CheckoutUncertain? _uncertain;
  CustomerCheckoutAttempt? _pendingAttempt;

  @override
  void initState() {
    super.initState();
    _loadPendingAttempt();
  }

  Future<void> _loadPendingAttempt() async {
    final saved = await ref
        .read(customerCheckoutControllerProvider)
        .readPendingAttempt(widget.accountId);
    if (!mounted || saved == null) return;
    setState(() => _pendingAttempt = saved);
  }

  Future<void> _submitOrder(CustomerCart cart) async {
    if (_submitting || !cart.canCheckout) return;
    final confirmed = await showCustomerConfirmDialog(
      context,
      title: 'Kirim pesanan tunai?',
      message:
          'Total ${formatRupiah(cart.subtotal)} dibayar tunai saat mengambil pesanan di ${cart.stall?.name ?? 'kantin'}.',
      confirmLabel: 'Kirim Pesanan',
    );
    if (!mounted || !confirmed) return;

    setState(() {
      _submitting = true;
      _uncertain = null;
    });
    try {
      final outcome = await ref
          .read(customerCheckoutControllerProvider)
          .submitCheckout(accountId: widget.accountId, cart: cart);
      if (!mounted) return;
      _handleOutcome(outcome);
    } catch (error) {
      if (!mounted) return;
      showCustomerSnackBar(
        context,
        presentAppError(error, fallback: 'Checkout gagal. Periksa keranjang.'),
      );
      ref.invalidate(customerCartProvider(widget.accountId));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _checkPendingAttempt(CustomerCheckoutAttempt attempt) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final outcome = await ref
          .read(customerCheckoutControllerProvider)
          .verifyOrRetryAttempt(accountId: widget.accountId, attempt: attempt);
      if (!mounted) return;
      _handleOutcome(outcome);
    } catch (error) {
      if (!mounted) return;
      showCustomerSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal memeriksa status checkout.'),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleOutcome(CheckoutOutcome outcome) {
    switch (outcome) {
      case CheckoutConfirmed(:final order):
        widget.onOrderCompleted?.call(order.summary.id);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => CustomerOrderDetailPage(
              accountId: widget.accountId,
              orderId: order.summary.id,
            ),
          ),
          (route) => route.isFirst,
        );
      case CheckoutUncertain():
        setState(() {
          _uncertain = outcome;
          _pendingAttempt = outcome.attempt;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartAsync = ref.watch(customerCartProvider(widget.accountId));
    final cart = cartAsync.asData?.value ?? widget.initialCart;
    final stall = cart.stall;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(KcSpacing.md),
                children: [
                  if (_uncertain case final CheckoutUncertain uncertain)
                    CustomerCheckoutUncertainBanner(
                      message: uncertain.message,
                      busy: _submitting,
                      onVerify: () => _checkPendingAttempt(uncertain.attempt),
                    )
                  else if (_pendingAttempt case final pending?
                      when pending.cartVersion == cart.draftVersion)
                    CustomerCheckoutUncertainBanner(
                      message:
                          'Ada upaya pengiriman tertunda untuk versi keranjang ini.',
                      busy: _submitting,
                      onVerify: () => _checkPendingAttempt(pending),
                    ),
                  if (stall != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(KcSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stall.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Periksa kembali ringkasan pesanan Anda sebelum mengirim.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
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
                        children: [
                          for (var i = 0; i < cart.items.length; i++) ...[
                            if (i > 0) const Divider(height: KcSpacing.md),
                            CustomerCheckoutItemRow(item: cart.items[i]),
                          ],
                          if (cart.generalNote.isNotEmpty) ...[
                            const Divider(height: KcSpacing.md),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Catatan pesanan: ${cart.generalNote}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
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
                            'Pengambilan',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ambil langsung di kantin (${stall == null ? '-' : 'Blok ${stall.block}'})',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Divider(height: KcSpacing.md),
                          Text(
                            'Metode Pembayaran',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text('Bayar tunai saat mengambil makanan'),
                        ],
                      ),
                    ),
                  ),
                  for (final blocker in cart.blockers)
                    Container(
                      margin: const EdgeInsets.only(top: KcSpacing.sm),
                      padding: const EdgeInsets.all(KcSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(KcRadius.small),
                      ),
                      child: Text(
                        blocker.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            CustomerCheckoutBottomBar(
              totalAmount: cart.subtotal,
              canCheckout: cart.canCheckout,
              submitting: _submitting,
              onSubmit: () => _submitOrder(cart),
            ),
          ],
        ),
      ),
    );
  }
}
