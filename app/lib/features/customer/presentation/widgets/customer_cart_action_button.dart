import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_cart_page.dart';

class CustomerCartAppBarButton extends ConsumerWidget {
  const CustomerCartAppBarButton({
    super.key,
    required this.accountId,
    this.onOpenedCartOrder,
  });

  final String accountId;
  final ValueChanged<String>? onOpenedCartOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(customerCartProvider(accountId)).asData?.value;
    final count = cart?.itemCount ?? 0;

    return Semantics(
      button: true,
      label: count > 0 ? 'Keranjang, $count item' : 'Keranjang',
      excludeSemantics: true,
      child: IconButton(
        tooltip: 'Keranjang',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CustomerCartPage(
                accountId: accountId,
                onOrderCompleted: onOpenedCartOrder,
              ),
            ),
          );
        },
        icon: Badge.count(
          count: count,
          isLabelVisible: count > 0,
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
    );
  }
}
