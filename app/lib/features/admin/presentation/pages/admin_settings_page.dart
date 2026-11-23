import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/dialogs/account_edit_dialog.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_theme_mode_card.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KcSpacing.md),
          children: [
            const KcThemeModeCard(),
            const SizedBox(height: KcSpacing.md),
            Text('Keamanan Login', style: theme.textTheme.titleMedium),
            const SizedBox(height: KcSpacing.xs),
            Card(
              clipBehavior: Clip.antiAlias,
              child: account.canManageCredentials
                  ? Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Ubah email'),
                          subtitle: Text(account.email),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => AccountEditDialog(
                              account: account,
                              edit: AccountEdit.email,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Atur Ulang Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => AccountEditDialog(
                              account: account,
                              edit: AccountEdit.password,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Padding(
                      padding: EdgeInsets.all(KcSpacing.md),
                      child: Text(
                        'Akun Admin ini masuk melalui Google. Pengelolaan email dan kata sandi dikelola melalui akun Google Anda.',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
