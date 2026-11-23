import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_detail_field.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_formatters.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_state_views.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_status_pills.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminStallDetailPage extends ConsumerWidget {
  const AdminStallDetailPage({
    super.key,
    required this.accountId,
    required this.stallId,
  });

  final String accountId;
  final String stallId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (accountId: accountId, stallId: stallId);
    final stallAsync = ref.watch(adminStallDetailProvider(key));
    final theme = Theme.of(context);
    final statusColors = KcStatusColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kantin')),
      body: SafeArea(
        child: stallAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AdminErrorView(
            error: error,
            fallback: 'Detail kantin tidak dapat dimuat.',
            onRetry: () => ref.invalidate(adminStallDetailProvider(key)),
          ),
          data: (stall) {
            final photo = stall.hasPhoto
                ? ref.watch(adminStallPhotoProvider(key)).asData?.value
                : null;
            return ListView(
              padding: const EdgeInsets.all(KcSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(KcSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColors.infoContainer,
                    borderRadius: BorderRadius.circular(KcRadius.small),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: statusColors.info,
                      ),
                      const SizedBox(width: KcSpacing.xs),
                      Expanded(
                        child: Text(
                          'Hanya dapat dilihat oleh Admin (read-only).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KcSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(KcRadius.card),
                  child: Container(
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: photo != null
                        ? Image.memory(photo, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.storefront_outlined, size: 42),
                          ),
                  ),
                ),
                const SizedBox(height: KcSpacing.md),
                Text(stall.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: KcSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminStatusPill(
                      label: stall.isListed ? 'Diterbitkan' : 'Belum Terbit',
                      foreground: stall.isListed
                          ? statusColors.info
                          : theme.colorScheme.onSurfaceVariant,
                      background: stall.isListed
                          ? statusColors.infoContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    if (stall.isListed)
                      AdminStatusPill(
                        label: stall.isOpen ? 'Buka' : 'Tutup',
                        foreground: stall.isOpen
                            ? statusColors.success
                            : theme.colorScheme.onSurfaceVariant,
                        background: stall.isOpen
                            ? statusColors.successContainer
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                    AdminStatusPill(
                      label: stall.ownerIsActive
                          ? 'Akun Owner Aktif'
                          : 'Owner Nonaktif',
                      foreground: stall.ownerIsActive
                          ? statusColors.success
                          : theme.colorScheme.onErrorContainer,
                      background: stall.ownerIsActive
                          ? statusColors.successContainer
                          : theme.colorScheme.errorContainer,
                    ),
                  ],
                ),
                const Divider(height: KcSpacing.lg),
                AdminDetailField(
                  label: 'Pemilik (Owner)',
                  value: stall.ownerName,
                ),
                AdminDetailField(label: 'Email Owner', value: stall.ownerEmail),
                AdminDetailField(label: 'Kampus', value: stall.campus),
                AdminDetailField(label: 'Lokasi / Blok', value: stall.block),
                AdminDetailField(
                  label: 'Estimasi Persiapan',
                  value: '${stall.waitMinutes} menit',
                ),
                if (stall.description != null &&
                    stall.description!.trim().isNotEmpty)
                  AdminDetailField(
                    label: 'Deskripsi',
                    value: stall.description!,
                  ),
                if (stall.schedules.isNotEmpty) ...[
                  const Divider(height: KcSpacing.lg),
                  Text(
                    'Jam Operasional Informatif',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: KcSpacing.xs),
                  for (final day in stall.schedules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(adminWeekdayName(day.dayOfWeek)),
                          ),
                          Text(
                            day.isOpenDay
                                ? '${day.openTime ?? '-'} - ${day.closeTime ?? '-'}'
                                : 'Tutup',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
