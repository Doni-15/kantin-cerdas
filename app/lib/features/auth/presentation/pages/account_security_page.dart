import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/config/app_feature_flags.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

  static const _contentMaxWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showActivitySection =
        AppFeatureFlags.enableDeviceSessionManagement ||
        AppFeatureFlags.enableLoginActivityHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keamanan akun'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const BackButtonIcon(),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.app);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KcSpacing.lg),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kelola password dan akses akunmu.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: KcSpacing.lg),
                  Text('Keamanan', style: theme.textTheme.titleMedium),
                  const SizedBox(height: KcSpacing.sm),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Ubah password'),
                          subtitle: const Text('Ganti password akunmu.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push(Routes.changePassword);
                          },
                        ),
                        if (AppFeatureFlags.enableEmailVerification) ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.mark_email_read_outlined),
                            title: const Text('Verifikasi email'),
                            subtitle: const Text(
                              'Konfirmasi alamat email akunmu.',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              KcSnackBar.info(
                                context,
                                'Verifikasi email akan tersedia setelah terhubung ke server.',
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showActivitySection) ...[
                    const SizedBox(height: KcSpacing.lg),
                    Text('Aktivitas akun', style: theme.textTheme.titleMedium),
                    const SizedBox(height: KcSpacing.sm),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (AppFeatureFlags.enableDeviceSessionManagement)
                            ListTile(
                              leading: const Icon(Icons.devices_outlined),
                              title: const Text('Perangkat yang login'),
                              subtitle: const Text(
                                'Kelola sesi akun pada perangkatmu.',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                KcSnackBar.info(
                                  context,
                                  'Manajemen perangkat aktif akan tersedia setelah terhubung ke server.',
                                );
                              },
                            ),
                          if (AppFeatureFlags.enableDeviceSessionManagement &&
                              AppFeatureFlags.enableLoginActivityHistory)
                            const Divider(),
                          if (AppFeatureFlags.enableLoginActivityHistory)
                            ListTile(
                              leading: const Icon(Icons.history_outlined),
                              title: const Text('Aktivitas login'),
                              subtitle: const Text('Lihat riwayat akses akun.'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                KcSnackBar.info(
                                  context,
                                  'Riwayat aktivitas login akan tersedia setelah terhubung ke server.',
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
