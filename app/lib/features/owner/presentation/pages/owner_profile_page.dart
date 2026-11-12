import 'package:kantin_cerdas/core/config/app_build_info.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/profile_identity_header.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/refresh_session_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/logout_button.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Profil pemilik kantin menggunakan data sesi dari router.
///
/// Integrasi backend untuk data akun berada pada fitur autentikasi.
class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Scaffold dan navigasi bawah disediakan oleh OwnerShell.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(KcSpacing.lg),
          children: [
            Semantics(
              header: true,
              child: Text('Profil', style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: KcSpacing.lg),
            ProfileIdentityHeader(user: user),
            const SizedBox(height: KcSpacing.lg),
            Semantics(
              header: true,
              child: Text('Data akun', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: KcSpacing.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Nama lengkap'),
                    subtitle: SelectableText(user.name),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.alternate_email),
                    title: const Text('Username'),
                    subtitle: SelectableText(user.username),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: SelectableText(user.email),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KcSpacing.lg),
            Semantics(
              header: true,
              child: Text('Pengaturan', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: KcSpacing.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Keamanan akun'),
                    subtitle: const Text('Kelola password akun'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.accountSecurity),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Tema aplikasi'),
                    subtitle: const Text('Atur tampilan terang atau gelap'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KcSpacing.lg),
            Semantics(
              header: true,
              child: Text('Kantin', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: KcSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Pengaturan kantin'),
                subtitle: const Text('Kelola informasi kantin'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.ownerStallSettings),
              ),
            ),
            const SizedBox(height: KcSpacing.lg),
            Semantics(
              header: true,
              child: Text('Informasi', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: KcSpacing.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Bantuan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.help),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Syarat dan ketentuan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.terms),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KcSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.customerHome),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Belanja dan pesanan pribadi'),
            ),
            const SizedBox(height: KcSpacing.sm),
            const RefreshSessionButton(),
            const SizedBox(height: KcSpacing.sm),
            const Text('Periksa kembali role dan status akun dari layanan.'),
            const SizedBox(height: KcSpacing.lg),
            const LogoutButton(),
            const SizedBox(height: KcSpacing.lg),
            Center(
              child: Text(
                AppBuildInfo.displayVersion,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
