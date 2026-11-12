import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_page_body.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_stall_section.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/dashboard/owner_stall_overview.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/orders/owner_order_feed.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key, required this.ownerName});
  final String ownerName;
  @override
  Widget build(BuildContext context) {
    return OwnerPageBody(
      title: 'Halo, $ownerName',
      description: 'Pantau stan dan pesanan terbarumu.',
      child: OwnerStallSection(
        builder: (stall) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OwnerStallOverview(stall: stall),
            const SizedBox(height: KcSpacing.lg),
            Text(
              'Pesanan terbaru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: KcSpacing.sm),
            const OwnerOrderFeed(preview: true),
          ],
        ),
      ),
    );
  }
}
