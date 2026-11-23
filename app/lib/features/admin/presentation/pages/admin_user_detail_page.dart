import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/admin/application/admin_action_controller.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_detail_field.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_dialogs.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_formatters.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_state_views.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_status_pills.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';

class AdminUserDetailPage extends ConsumerStatefulWidget {
  const AdminUserDetailPage({
    super.key,
    required this.accountId,
    required this.userId,
  });

  final String accountId;
  final String userId;

  @override
  ConsumerState<AdminUserDetailPage> createState() =>
      _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends ConsumerState<AdminUserDetailPage> {
  var _busy = false;

  AdminUserKey get _key => (accountId: widget.accountId, userId: widget.userId);

  Future<void> _deactivate(AdminManagedUser user) async {
    if (_busy) return;
    final reason = await showAdminReasonSheet(
      context,
      title: 'Nonaktifkan Akun',
      description:
          'Masukkan alasan penonaktifan akun ${user.displayName}. Tindakan ini akan dicatat pada riwayat audit.',
      fieldLabel: 'Alasan Penonaktifan *',
      hint: 'Contoh: Pelanggaran tata tertib kantin.',
      confirmLabel: 'Nonaktifkan',
    );
    if (!mounted || reason == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(adminActionControllerProvider)
          .setUserActiveStatus(
            accountId: widget.accountId,
            targetUserId: user.id,
            isActive: false,
            reason: reason,
          );
      if (!mounted) return;
      showAdminSnackBar(context, 'Akun dinonaktifkan.');
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(adminUserDetailProvider(_key));
      showAdminSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menonaktifkan akun.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reactivate(AdminManagedUser user) async {
    if (_busy) return;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Aktifkan kembali akun?',
      message:
          'Akun ${user.displayName} (${user.email}) akan dapat masuk dan menggunakan aplikasi kembali.',
      confirmLabel: 'Aktifkan Kembali',
    );
    if (!mounted || !confirmed) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(adminActionControllerProvider)
          .setUserActiveStatus(
            accountId: widget.accountId,
            targetUserId: user.id,
            isActive: true,
          );
      if (!mounted) return;
      showAdminSnackBar(context, 'Akun diaktifkan kembali.');
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(adminUserDetailProvider(_key));
      showAdminSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal mengaktifkan kembali akun.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(adminUserDetailProvider(_key));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengguna')),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AdminErrorView(
            error: error,
            fallback: 'Detail pengguna tidak dapat dimuat.',
            onRetry: () => ref.invalidate(adminUserDetailProvider(_key)),
          ),
          data: (user) {
            final isSelf = user.id == widget.accountId;
            final hasActiveOrders = user.activeOrderIndicator.hasActiveOrders;
            final canDeactivate =
                user.isActive && !isSelf && !hasActiveOrders && !_busy;

            return ListView(
              padding: const EdgeInsets.all(KcSpacing.md),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    buildAccountStatusPill(context, user.isActive),
                    Text(
                      user.role.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KcSpacing.md),
                AdminDetailField(label: 'Nama', value: user.displayName),
                AdminDetailField(label: 'Email', value: user.email),
                AdminDetailField(
                  label: 'Verifikasi Email',
                  value: user.emailVerified
                      ? 'Terverifikasi'
                      : 'Belum terverifikasi',
                ),
                const Divider(height: KcSpacing.lg),
                AdminDetailField(
                  label: 'Indikator Pesanan Aktif',
                  value: hasActiveOrders ? 'Ada' : 'Tidak Ada',
                ),
                if (user.isActive && hasActiveOrders) ...[
                  Container(
                    padding: const EdgeInsets.all(KcSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(KcRadius.small),
                    ),
                    child: Text(
                      'Akun tidak dapat dinonaktifkan selama masih memiliki pesanan aktif (Menunggu Konfirmasi, Diproses, atau Siap Diambil).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: KcSpacing.md),
                ],
                if (user.isActive && isSelf) ...[
                  Text(
                    'Akun Admin yang sedang digunakan tidak dapat dinonaktifkan sendiri.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: KcSpacing.md),
                ],
                if (user.isActive)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: canDeactivate ? () => _deactivate(user) : null,
                    child: _busy
                        ? const KcInlineProgressIndicator()
                        : const Text('Nonaktifkan Akun'),
                  )
                else
                  FilledButton(
                    onPressed: _busy ? null : () => _reactivate(user),
                    child: _busy
                        ? const KcInlineProgressIndicator()
                        : const Text('Aktifkan Kembali'),
                  ),
                const Divider(height: KcSpacing.lg * 1.5),
                Text(
                  'Riwayat Tindakan Admin',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: KcSpacing.xs),
                if (user.recentLogs.isEmpty)
                  Text(
                    'Belum ada catatan tindakan Admin untuk akun ini.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (final log in user.recentLogs) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(log.actionType.label),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oleh ${log.adminName} · ${formatAdminDate(log.createdAt)}',
                          ),
                          if (log.reason != null) Text('Alasan: ${log.reason}'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
