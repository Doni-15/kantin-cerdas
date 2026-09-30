import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_success_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/rupiah_formatter.dart';

class CustomerOrderConfirmationPage
    extends ConsumerStatefulWidget {
  const CustomerOrderConfirmationPage({
    super.key,
  });

  @override
  ConsumerState<CustomerOrderConfirmationPage>
      createState() =>
          _CustomerOrderConfirmationPageState();
}

class _CustomerOrderConfirmationPageState
    extends ConsumerState<CustomerOrderConfirmationPage> {
  bool isSubmitting = false;

  Future<void> _createOrder() async {
    if (isSubmitting) {
      return;
    }

    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // Simulasi proses mengirim pesanan.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) {
      return;
    }

    // Simpan data sebelum keranjang dikosongkan.
    final stallName = cart.stallName ?? '';
    final block = cart.block ?? '';
    final totalQuantity = cart.totalQuantity;
    final totalPrice = cart.totalPrice;

    // Untuk sementara nomor pesanan dummy.
    const orderNumber = 'KC-027';

    // Kosongkan keranjang setelah pesanan berhasil.
    ref
        .read(cartProvider.notifier)
        .clearCart();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return CustomerOrderSuccessPage(
            orderNumber: orderNumber,
            stallName: stallName,
            block: block,
            totalQuantity: totalQuantity,
            totalPrice: totalPrice,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konfirmasi pesanan',
        ),
      ),

      body: cart.isEmpty
          ? const Center(
              child: Text(
                'Keranjang kosong',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =================================================
                // LOKASI PENGAMBILAN
                // =================================================

                Text(
                  'Lokasi pengambilan',
                  style: theme.textTheme.titleLarge,
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme
                        .surfaceContainer,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color:
                            theme.colorScheme.primary,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              cart.stallName ?? '',
                              style: theme
                                  .textTheme
                                  .titleSmall,
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Kantin Kampus · ${cart.block ?? ''}',
                              style: theme
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // =================================================
                // PESANAN
                // =================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesananmu',
                      style: theme.textTheme.titleLarge,
                    ),

                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text(
                        'Ubah',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ...cart.items.map(
                  (item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme
                                .colorScheme
                                .outlineVariant,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // GAMBAR SEMENTARA
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              size: 20,
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}× ${item.menu.name}',
                                  style: theme
                                      .textTheme
                                      .titleSmall,
                                ),

                                if (item.note.isNotEmpty) ...[
                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    item.note,
                                    style: theme
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            formatRupiah(
                              item.subtotal,
                            ),
                            style:
                                theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // =================================================
                // TOTAL
                // =================================================

                Row(
                  children: [
                    Text(
                      'Total · ${cart.totalQuantity} porsi',
                      style: theme.textTheme.titleMedium,
                    ),

                    const Spacer(),

                    Text(
                      formatRupiah(
                        cart.totalPrice,
                      ),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // =================================================
                // PEMBAYARAN
                // =================================================

                Text(
                  'Pembayaran',
                  style: theme.textTheme.titleLarge,
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme
                        .surfaceContainer,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color:
                            theme.colorScheme.primary,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tunai saat mengambil',
                              style: theme
                                  .textTheme
                                  .titleSmall,
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Bayar langsung di konter',
                              style: theme
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Disiapkan sekitar ${cart.items.first.menu.waitTime} setelah stan menerima pesanan.',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),

      // ===========================================================
      // TOMBOL BUAT PESANAN
      // ===========================================================

      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color:
                          theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : _createOrder,
                    child: isSubmitting
                        ? const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),

                              SizedBox(width: 10),

                              Text(
                                'Mengirim pesanan...',
                              ),
                            ],
                          )
                        : const Text(
                            'Buat pesanan',
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}