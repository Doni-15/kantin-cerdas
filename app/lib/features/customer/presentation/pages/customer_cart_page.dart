import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_confirmation_page.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/rupiah_formatter.dart';

class CustomerCartPage extends ConsumerWidget {
  const CustomerCartPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keranjang',
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () {
                _showClearCartDialog(
                  context,
                  ref,
                );
              },
              child: const Text(
                'Kosongkan',
              ),
            ),
        ],
      ),

      body: cart.isEmpty
          ? const _EmptyCart()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // NAMA STAN
                Text(
                  cart.stallName ?? '',
                  style: theme.textTheme.titleLarge,
                ),

                const SizedBox(height: 4),

                // LOKASI STAN
                Text(
                  '${cart.block ?? ''} · Ambil langsung di stan',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 16),

                // ITEM KERANJANG
                ...cart.items.map(
                  (item) {
                    return _CartMenuItem(
                      key: ValueKey(item.menu.id),
                      item: item,
                    );
                  },
                ),

                const SizedBox(height: 20),

                // INFORMASI PEMBAYARAN
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'Bayar tunai saat mengambil',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),

      // BAGIAN BAWAH
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // TOTAL
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.totalQuantity} porsi',
                            style: theme.textTheme.bodySmall,
                          ),

                          const SizedBox(height: 2),

                          Text(
                            formatRupiah(
                              cart.totalPrice,
                            ),
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),

                    // LANJUT KONFIRMASI
                    FilledButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                    
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return const CustomerOrderConfirmationPage();
                            },
                          ),
                        );
                      },
                      child: const Text(
                        'Lanjut konfirmasi',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showClearCartDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final cart = ref.read(cartProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Kosongkan keranjang?',
          ),
          content: Text(
            '${cart.totalQuantity} porsi dari '
            '${cart.stallName} akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Kosongkan',
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      ref
          .read(cartProvider.notifier)
          .clearCart();
    }
  }
}

// ================================================================
// ITEM MENU DI KERANJANG
// ================================================================

class _CartMenuItem extends ConsumerStatefulWidget {
  const _CartMenuItem({
    super.key,
    required this.item,
  });

  final CartItem item;

  @override
  ConsumerState<_CartMenuItem> createState() =>
      _CartMenuItemState();
}

class _CartMenuItemState
    extends ConsumerState<_CartMenuItem> {
  late final TextEditingController _noteController;

  bool isEditingNote = false;

  @override
  void initState() {
    super.initState();

    _noteController = TextEditingController(
      text: widget.item.note,
    );
  }

  @override
  void didUpdateWidget(
    covariant _CartMenuItem oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!isEditingNote &&
        oldWidget.item.note != widget.item.note) {
      _noteController.text = widget.item.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
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
          // INFORMASI MENU
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GAMBAR SEMENTARA
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAMA MENU
                    Text(
                      item.menu.name,
                      style: theme.textTheme.titleSmall,
                    ),

                    const SizedBox(height: 4),

                    // HARGA
                    Text(
                      '${formatRupiah(item.menu.price)} / porsi',
                      style: theme.textTheme.bodyMedium,
                    ),

                    // CATATAN YANG SUDAH TERSIMPAN
                    if (item.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4,
                        ),
                        child: Text(
                          item.note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ======================================================
          // FORM CATATAN MENU
          // ======================================================

          Offstage(
            offstage: !isEditingNote,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan',
                  style: theme.textTheme.titleSmall,
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Sambal dipisah',
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();

                        _noteController.text =
                            widget.item.note;

                        setState(() {
                          isEditingNote = false;
                        });
                      },
                      child: const Text(
                        'Batal',
                      ),
                    ),

                    const SizedBox(width: 8),

                    FilledButton(
                      onPressed: () {
                        final note =
                            _noteController.text.trim();

                        FocusManager.instance.primaryFocus?.unfocus();

                        ref
                            .read(cartProvider.notifier)
                            .updateItemNote(
                              item.menu.id,
                              note,
                            );

                        setState(() {
                          isEditingNote = false;
                        });
                      },
                      child: const Text(
                        'Simpan catatan',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ======================================================
          // ACTION MENU
          // ======================================================

          Row(
            children: [
              // CATATAN / UBAH CATATAN
              TextButton(
                onPressed: () {
                  setState(() {
                    isEditingNote = true;
                  });
                },
                child: Text(
                  item.note.isEmpty
                      ? 'Catatan'
                      : 'Ubah catatan',
                ),
              ),

              // HAPUS
              IconButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();

                  ref
                      .read(cartProvider.notifier)
                      .removeItem(
                        item.menu.id,
                      );
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),

              const Spacer(),

              // JUMLAH PESANAN
              Container(
                height: 42,
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // KURANG
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();

                        ref
                            .read(cartProvider.notifier)
                            .decreaseItem(
                              item.menu.id,
                            );
                      },
                      icon: const Icon(
                        Icons.remove,
                        size: 18,
                      ),
                    ),

                    // JUMLAH
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // TAMBAH
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();

                        ref
                            .read(cartProvider.notifier)
                            .addItem(
                              item.menu,
                            );
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// KERANJANG KOSONG
// ================================================================

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Keranjangmu masih kosong',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Pilih menu dari stan yang kamu inginkan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cari menu',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}