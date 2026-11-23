import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_action_logs_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_dialogs.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/account_view.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_account_header_card.dart';

class AdminAccountPage extends ConsumerStatefulWidget {
  const AdminAccountPage({super.key, required this.account});

  final AuthAccount account;

  @override
  ConsumerState<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends ConsumerState<AdminAccountPage> {
  var _busy = false;

  Future<void> _logout() async {
    if (_busy) return;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Keluar dari akun Admin?',
      message:
          'Sesi pada perangkat ini akan diakhiri dan akses data terlindungi dihentikan.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!mounted || !confirmed) return;

    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (!mounted) return;
      showAdminSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal keluar dari akun.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Tentang Aplikasi'),
        content: const Text(
          'Kantin Cerdas\nVersi 1.0.0\nPanel pengawasan administratif dan peninjauan pengajuan Owner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final photo = ref.watch(accountPhotoProvider(account.id));
    final bytes = photo.asData?.value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Akun Admin')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KcSpacing.md),
          children: [
            KcAccountHeaderRow(
              displayName: account.displayName ?? 'Admin',
              email: account.email,
              roleLabel: 'Admin',
              avatarBytes: bytes,
              avatarRadius: 26,
              roleSpacing: 2,
            ),
            const SizedBox(height: KcSpacing.lg),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Edit Profil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (routeContext) => AuthAccountScreen(
                    account: account,
                    onBack: () => Navigator.of(routeContext).pop(),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminSettingsPage(account: account),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_outlined),
              title: const Text('Riwayat Audit Admin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminActionLogsPage(accountId: account.id),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showAboutDialog,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                _busy ? 'Keluar...' : 'Keluar',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: _busy ? null : _logout,
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
