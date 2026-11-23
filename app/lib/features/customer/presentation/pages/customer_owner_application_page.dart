import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/customer/application/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_application_status_card.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';

class CustomerOwnerApplicationPage extends ConsumerStatefulWidget {
  const CustomerOwnerApplicationPage({super.key, required this.account});

  final AuthAccount account;

  @override
  ConsumerState<CustomerOwnerApplicationPage> createState() =>
      _CustomerOwnerApplicationPageState();
}

class _CustomerOwnerApplicationPageState
    extends ConsumerState<CustomerOwnerApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _stallCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  var _submitting = false;
  var _showResubmitForm = false;

  @override
  void dispose() {
    _stallCtrl.dispose();
    _locationCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(customerOrderControllerProvider)
          .submitOwnerApplication(
            accountId: widget.account.id,
            plannedStallName: _stallCtrl.text.trim(),
            plannedLocation: _locationCtrl.text.trim(),
            reason: _reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _showResubmitForm = false);
      showCustomerSnackBar(
        context,
        'Pengajuan Owner dikirim dan menunggu pemeriksaan Admin.',
      );
    } catch (error) {
      if (!mounted) return;
      showCustomerSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal mengirim pengajuan Owner.'),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final stateAsync = ref.watch(customerOwnerApplicationProvider(account.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Pemilik Kantin')),
      body: SafeArea(
        child: stateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => CustomerErrorView(
            error: error,
            fallback: 'Status pengajuan tidak dapat dimuat.',
            onRetry: () =>
                ref.invalidate(customerOwnerApplicationProvider(account.id)),
          ),
          data: (state) {
            final app = state.latestApplication;
            final showForm =
                app == null ||
                (app.status == OwnerApplicationStatus.ditolak &&
                    _showResubmitForm);

            return ListView(
              padding: const EdgeInsets.all(KcSpacing.md),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  'Ajukan Peran Pemilik Kantin',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Pengajuan ini akan ditinjau secara manual oleh Admin. Pengajuan tidak membuat kantin maupun mengubah role secara otomatis.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KcSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(KcSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identitas Pemohon',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(account.displayName ?? '-'),
                        Text(
                          account.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: KcSpacing.md),
                if (app != null) ...[
                  CustomerApplicationStatusCard(
                    application: app,
                    hasActiveOrders: state.activeOrderIndicator.hasActiveOrders,
                    onResubmit:
                        app.status == OwnerApplicationStatus.ditolak &&
                            !_showResubmitForm
                        ? () => setState(() => _showResubmitForm = true)
                        : null,
                  ),
                  const SizedBox(height: KcSpacing.md),
                ],
                if (showForm)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _stallCtrl,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Nama rencana kantin',
                            hintText: 'Contoh: Warung Sehat Kampus',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama rencana kantin wajib diisi.'
                              : null,
                        ),
                        const SizedBox(height: KcSpacing.sm),
                        TextFormField(
                          controller: _locationCtrl,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Rencana lokasi usaha',
                            hintText: 'Contoh: Kantin Tengah Blok B-03',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Rencana lokasi wajib diisi.'
                              : null,
                        ),
                        const SizedBox(height: KcSpacing.sm),
                        TextFormField(
                          controller: _reasonCtrl,
                          maxLength: 500,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Alasan singkat pengajuan',
                            hintText:
                                'Jelaskan menu dan kesiapan operasional kantin Anda',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Alasan singkat wajib diisi.'
                              : null,
                        ),
                        const SizedBox(height: KcSpacing.md),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const KcInlineProgressIndicator()
                              : const Text('Kirim Pengajuan'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
