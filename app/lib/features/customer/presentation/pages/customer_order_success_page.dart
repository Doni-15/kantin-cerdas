import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_detail_page.dart';

/// Pertahankan route lama. Segmen /success sendiri bukan bukti keberhasilan.
class CustomerOrderSuccessPage extends StatelessWidget {
  const CustomerOrderSuccessPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) =>
      CustomerOrderDetailPage(orderId: orderId, showSubmissionNotice: true);
}
