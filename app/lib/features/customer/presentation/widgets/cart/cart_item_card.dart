import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart_quantity_button.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CartItemCard extends ConsumerStatefulWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.latestMenu,
    required this.enabled,
    required this.canAdd,
    required this.unavailable,
  });

  final CartItem item;
  final MenuItem? latestMenu;
  final bool enabled;
  final bool canAdd;
  final bool unavailable;

  @override
  ConsumerState<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<CartItemCard> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.note);
  }

  @override
  void didUpdateWidget(covariant CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final note = widget.item.note;

    if (_noteController.text != note) {
      _noteController.value = TextEditingValue(
        text: note,
        selection: TextSelection.collapsed(offset: note.length),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final latestMenu = widget.latestMenu;

    return Padding(
      padding: const EdgeInsets.only(bottom: KcSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.menu.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus ${item.menu.name}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.enabled
                        ? () {
                            FocusScope.of(context).unfocus();
                            ref
                                .read(cartProvider.notifier)
                                .removeItem(widget.item.menu.id);
                          }
                        : null,
                  ),
                ],
              ),
              Text('${formatRupiah(item.menu.price)} per item'),
              const SizedBox(height: KcSpacing.xs),
              Text(
                'Estimasi subtotal ${formatRupiah(item.subtotal)}',
                style: theme.textTheme.titleSmall,
              ),
              if (latestMenu != null &&
                  latestMenu.price != item.menu.price) ...[
                const SizedBox(height: KcSpacing.xs),
                Text(
                  'Harga katalog terbaru: '
                  '${formatRupiah(latestMenu.price)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (widget.unavailable) ...[
                const SizedBox(height: KcSpacing.xs),
                Text(
                  'Belum tersedia untuk dipesan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: KcSpacing.md),
              KcTextField(
                label: 'Catatan menu (opsional)',
                hint: 'Tulis permintaan untuk menu ini',
                controller: _noteController,
                maxLength: CustomerInputLimits.maxNoteLength,
                enabled: widget.enabled,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                onChanged: (note) {
                  ref
                      .read(cartProvider.notifier)
                      .updateItemNote(widget.item.menu.id, note);
                },
              ),
              const SizedBox(height: KcSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CartQuantityButton(
                  menu: latestMenu ?? item.menu,
                  canAdd: widget.canAdd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
