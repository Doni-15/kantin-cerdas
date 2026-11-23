import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/account_view.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_dialogs.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_account_header_card.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

class OwnerAccountPage extends ConsumerStatefulWidget {
  const OwnerAccountPage({super.key, required this.account});

  final AuthAccount account;

  @override
  ConsumerState<OwnerAccountPage> createState() => _OwnerAccountPageState();
}

class _OwnerAccountPageState extends ConsumerState<OwnerAccountPage> {
  var _busy = false;

  Future<void> _logout() async {
    if (_busy) return;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Kamu akan keluar dari sesi perangkat ini.',
      confirmLabel: 'Keluar',
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
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal keluar dari akun.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchToCustomer() {
    ref
        .read(ownerCustomerViewProvider(widget.account.id).notifier)
        .switchToCustomer();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final photo = ref.watch(accountPhotoProvider(account.id));
    final bytes = photo.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun Owner')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KcSpacing.md),
          children: [
            KcAccountHeaderCard(
              displayName: account.displayName ?? 'Owner',
              email: account.email,
              roleLabel: 'Pemilik Kantin',
              avatarBytes: bytes,
            ),
            const SizedBox(height: KcSpacing.md),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Informasi Akun & Pengaturan'),
                    subtitle: const Text(
                      'Ubah nama, foto profil, email, atau password.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AuthAccountScreen(
                          account: account,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('Beralih ke Customer'),
                    subtitle: const Text(
                      'Jelajahi kantin sebagai pelanggan dengan akun yang sama.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _switchToCustomer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KcSpacing.lg),
            OutlinedButton.icon(
              onPressed: _busy ? null : _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}
