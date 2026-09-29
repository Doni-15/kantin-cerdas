import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/router/routes.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/canteen_application_status_presentation.dart';

class CanteenApplicationStatusCard extends ConsumerWidget {
  const CanteenApplicationStatusCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = switch (ref.watch(canteenApplicationProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };

    if (application == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      // 1. Tambahkan margin agar tidak menabrak status bar dan tepi layar
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0), 
      elevation: 0,
      // 2. Beri warna latar yang sedikit berbeda dari background utama
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      // 3. Tambahkan border tipis agar bentuk kartu tegas
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStatus(context, application.status),
            const SizedBox(height: 20),
            _buildButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 4. Bungkus ikon dengan Container agar terlihat seperti badge premium
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.storefront_outlined,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Pengajuan Kantin',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(
    BuildContext context,
    CanteenApplicationStatus status,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          status.shortDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5, // Line height untuk keterbacaan
          ),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context) {
    // 5. Ubah menjadi FilledButton.tonal agar tombol CTA (Call to Action) lebih menonjol
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.tonalIcon(
        onPressed: () => context.push(Routes.canteenApplication),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Lihat Status'),
      ),
    );
  }
}