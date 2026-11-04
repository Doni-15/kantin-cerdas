import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_order_feed.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const CustomerOrderFeed(history: false);
}
