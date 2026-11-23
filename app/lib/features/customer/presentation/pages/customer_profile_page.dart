import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/account_view.dart';
import 'package:kantin_cerdas/features/customer/application/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_owner_application_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_settings_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_profile_owner_application_card.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_account_header_card.dart';

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key, required this.account});

  final AuthAccount account;

  @override
  ConsumerState<CustomerProfilePage> createState() =>
      _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  var _busyLogout = false;

  Future<void> _logout() async {
    if (_busyLogout) return;
    final confirmed = await showCustomerConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Sesi pada perangkat ini akan diakhiri.',
      confirmLabel: 'Keluar',
    );
    if (!mounted || !confirmed) return;

    setState(() => _busyLogout = true);
    try {
      await ref
          .read(customerOrderControllerProvider)
          .clearLocalAttempts(widget.account.id);
      await ref.read(authControllerProvider.notifier).logout();
    } catch (error) {
      if (!mounted) return;
      showCustomerSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal keluar dari akun.'),
      );
    } finally {
      if (mounted) setState(() => _busyLogout = false);
    }
  }

  void _openEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => AuthAccountScreen(
          account: widget.account,
          onBack: () => Navigator.of(routeContext).pop(),
          onOpenOwnerArea: widget.account.role == AuthRole.owner
              ? () {
                  Navigator.of(routeContext).popUntil((route) => route.isFirst);
                  ref
                      .read(
                        ownerCustomerViewProvider(widget.account.id).notifier,
                      )
                      .switchToOwner();
                }
              : null,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerSettingsPage(account: widget.account),
      ),
    );
  }

  void _openOwnerApplication() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerOwnerApplicationPage(account: widget.account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final theme = Theme.of(context);
    final photo = ref.watch(accountPhotoProvider(account.id));
    final bytes = photo.asData?.value;
    final isOwner = account.role == AuthRole.owner;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            KcSpacing.md,
            KcSpacing.sm,
            KcSpacing.md,
            KcSpacing.lg * 2,
          ),
          children: [
            KcAccountHeaderCard(
              displayName: account.displayName ?? 'Customer',
              email: account.email,
              roleLabel: account.role.label,
              avatarBytes: bytes,
            ),
            const SizedBox(height: KcSpacing.md),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit Profil'),
                    subtitle: const Text('Nama, foto profil, dan kredensial'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openEditProfile,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Pengaturan'),
                    subtitle: const Text('Tema aplikasi & informasi akun'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openSettings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            if (isOwner)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(KcSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pemilik Kantin (Disetujui)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buka kembali dashboard pengelolaan kantin, menu, dan pesanan Anda.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: KcSpacing.sm),
                      FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(
                                ownerCustomerViewProvider(account.id).notifier,
                              )
                              .switchToOwner();
                        },
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Masuk Area Owner'),
                      ),
                    ],
                  ),
                ),
              )
            else
              CustomerProfileOwnerApplicationCard(
                accountId: account.id,
                onOpenForm: _openOwnerApplication,
              ),
            const SizedBox(height: KcSpacing.md),
            OutlinedButton.icon(
              onPressed: _busyLogout ? null : _logout,
              icon: const Icon(Icons.logout),
              label: _busyLogout
                  ? const Text('Keluar...')
                  : const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}
