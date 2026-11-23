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

class AdminApplicationDetailPage extends ConsumerStatefulWidget {
  const AdminApplicationDetailPage({
    super.key,
    required this.accountId,
    required this.applicationId,
  });

  final String accountId;
  final String applicationId;

  @override
  ConsumerState<AdminApplicationDetailPage> createState() =>
      _AdminApplicationDetailPageState();
}

class _AdminApplicationDetailPageState
    extends ConsumerState<AdminApplicationDetailPage> {
  var _busy = false;

  AdminApplicationKey get _key =>
      (accountId: widget.accountId, applicationId: widget.applicationId);

  Future<void> _approve(AdminOwnerApplication app) async {
    if (_busy) return;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Setujui pengajuan Owner?',
      message:
          'Akun ${app.applicantName} akan diberi peran Owner tanpa membuat kantin otomatis.',
      confirmLabel: 'Setujui Pengajuan',
    );
    if (!mounted || !confirmed) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(adminActionControllerProvider)
          .reviewApplication(
            accountId: widget.accountId,
            applicationId: app.id,
            approve: true,
          );
      if (!mounted) return;
      showAdminSnackBar(context, 'Pengajuan Owner disetujui.');
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(adminApplicationDetailProvider(_key));
      showAdminSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menyetujui pengajuan.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(AdminOwnerApplication app) async {
    if (_busy) return;
    final reason = await showAdminReasonSheet(
      context,
      title: 'Tolak Pengajuan Owner',
      description:
          'Masukkan alasan penolakan yang jelas untuk ${app.applicantName}.',
      fieldLabel: 'Alasan Penolakan *',
      hint: 'Contoh: Masih ada pesanan aktif atau data rencana kurang jelas.',
      confirmLabel: 'Konfirmasi Tolak',
    );
    if (!mounted || reason == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(adminActionControllerProvider)
          .reviewApplication(
            accountId: widget.accountId,
            applicationId: app.id,
            approve: false,
            rejectionReason: reason,
          );
      if (!mounted) return;
      showAdminSnackBar(context, 'Pengajuan Owner ditolak.');
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(adminApplicationDetailProvider(_key));
      showAdminSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menolak pengajuan.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(adminApplicationDetailProvider(_key));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: SafeArea(
        child: appAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AdminErrorView(
            error: error,
            fallback: 'Detail pengajuan tidak dapat dimuat.',
            onRetry: () => ref.invalidate(adminApplicationDetailProvider(_key)),
          ),
          data: (app) {
            final isPending =
                app.status == AdminApplicationStatus.menungguReview;
            final hasActiveOrders = app.activeOrderIndicator.hasActiveOrders;
            final canApprove =
                isPending &&
                !hasActiveOrders &&
                app.applicantIsActive &&
                !_busy;

            return ListView(
              padding: const EdgeInsets.all(KcSpacing.md),
              children: [
                Row(
                  children: [
                    buildApplicationStatusPill(context, app.status),
                    const Spacer(),
                    Text(
                      formatAdminDate(app.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KcSpacing.md),
                AdminDetailField(
                  label: 'Nama Pemohon',
                  value: app.applicantName,
                ),
                AdminDetailField(
                  label: 'Email Pemohon',
                  value: app.applicantEmail,
                ),
                AdminDetailField(
                  label: 'Status Akun',
                  value: app.applicantIsActive ? 'Aktif' : 'Nonaktif',
                ),
                const Divider(height: KcSpacing.lg),
                AdminDetailField(
                  label: 'Nama Rencana Kantin',
                  value: app.plannedStallName,
                ),
                AdminDetailField(
                  label: 'Lokasi Rencana',
                  value: app.plannedLocation,
                ),
                AdminDetailField(label: 'Alasan Singkat', value: app.reason),
                const Divider(height: KcSpacing.lg),
                AdminDetailField(
                  label: 'Indikator Pesanan Aktif',
                  value: hasActiveOrders ? 'Ada' : 'Tidak Ada',
                ),
                if (hasActiveOrders && isPending) ...[
                  const SizedBox(height: KcSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(KcSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(KcRadius.small),
                    ),
                    child: Text(
                      'Pemohon masih memiliki pesanan aktif. Sesuai aturan, persetujuan diblokir dan Admin harus menolak pengajuan dengan alasan.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                if (!app.applicantIsActive && isPending) ...[
                  const SizedBox(height: KcSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(KcSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(KcRadius.small),
                    ),
                    child: Text(
                      'Akun pemohon sedang dinonaktifkan sehingga pengajuan tidak dapat disetujui.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                if (!isPending) ...[
                  const Divider(height: KcSpacing.lg),
                  if (app.decidedByName != null)
                    AdminDetailField(
                      label: 'Diputuskan oleh',
                      value: app.decidedByName!,
                    ),
                  if (app.decidedAt != null)
                    AdminDetailField(
                      label: 'Waktu Keputusan',
                      value: formatAdminDate(app.decidedAt!),
                    ),
                  if (app.rejectionReason != null)
                    AdminDetailField(
                      label: 'Alasan Penolakan',
                      value: app.rejectionReason!,
                    ),
                ],
                if (isPending) ...[
                  const SizedBox(height: KcSpacing.lg),
                  FilledButton(
                    onPressed: canApprove ? () => _approve(app) : null,
                    child: _busy
                        ? const KcInlineProgressIndicator()
                        : const Text('Setujui Pengajuan'),
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _reject(app),
                    child: const Text('Tolak Pengajuan'),
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
