import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_page_body.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_stall_section.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/orders/owner_order_feed.dart';

class OwnerOrdersPage extends StatelessWidget {
  const OwnerOrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return OwnerPageBody(
      title: 'Pesanan stan',
      description: 'Terima, siapkan, dan selesaikan pesanan pelanggan.',
      child: OwnerStallSection(
        builder: (stall) => OwnerOrderFeed(key: ValueKey(stall.id)),
      ),
    );
  }
}
