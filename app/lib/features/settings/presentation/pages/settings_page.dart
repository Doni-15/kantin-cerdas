import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/config/app_build_info.dart';
import 'package:kantin_cerdas/core/settings/app_settings_provider.dart';
import 'package:kantin_cerdas/core/widgets/kc_logo.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _contentMaxWidth = 640.0;

  bool _saving = false;

  Future<void> _setThemeMode(ThemeMode? mode) async {
    if (mode == null || _saving) {
      return;
    }

    if (mode == ref.read(appSettingsProvider).themeMode) {
      return;
    }

    final controller = ref.read(appSettingsProvider.notifier);

    setState(() {
      _saving = true;
    });

    try {
      await controller.setThemeMode(mode);
    } catch (_) {
      if (mounted) {
        KcSnackBar.error(
          context,
          'Tema belum dapat disimpan. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _openAbout() {
    showAboutDialog(
      context: context,
      applicationIcon: const KcLogo(size: 48),
      applicationName: 'Kantin Cerdas',
      applicationVersion: AppBuildInfo.version,
      applicationLegalese: '© 2026 Kantin Cerdas',
      children: const [
        SizedBox(height: KcSpacing.md),
        Text(
          'Kantin Cerdas merupakan aplikasi untuk mendukung '
          'pemesanan makanan dan pengelolaan kantin kampus.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = settings.themeMode;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
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
                    'Atur tampilan aplikasi sesuai kenyamananmu.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: KcSpacing.lg),
                  Text('Tema aplikasi', style: theme.textTheme.titleMedium),
                  const SizedBox(height: KcSpacing.sm),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: RadioGroup<ThemeMode>(
                      groupValue: themeMode,
                      onChanged: _setThemeMode,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<ThemeMode>(
                            value: ThemeMode.system,
                            enabled: !_saving,
                            title: const Text('Ikuti sistem'),
                            subtitle: const Text(
                              'Menyesuaikan pengaturan tema perangkat.',
                            ),
                          ),
                          const Divider(),
                          RadioListTile<ThemeMode>(
                            value: ThemeMode.light,
                            enabled: !_saving,
                            title: const Text('Terang'),
                            subtitle: const Text('Gunakan tampilan terang.'),
                          ),
                          const Divider(),
                          RadioListTile<ThemeMode>(
                            value: ThemeMode.dark,
                            enabled: !_saving,
                            title: const Text('Gelap'),
                            subtitle: const Text('Gunakan tampilan gelap.'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_saving) ...[
                    const SizedBox(height: KcSpacing.md),
                    const Row(
                      children: [
                        SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Menyimpan tema',
                          ),
                        ),
                        SizedBox(width: KcSpacing.sm),
                        Expanded(child: Text('Menyimpan tema...')),
                      ],
                    ),
                  ],
                  const SizedBox(height: KcSpacing.lg),
                  Text('Bahasa', style: theme.textTheme.titleMedium),
                  const SizedBox(height: KcSpacing.sm),
                  const Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: Icon(Icons.language_outlined),
                      title: Text('Bahasa aplikasi'),
                      subtitle: Text('Bahasa Indonesia'),
                    ),
                  ),
                  const SizedBox(height: KcSpacing.lg),
                  Text('Informasi', style: theme.textTheme.titleMedium),
                  const SizedBox(height: KcSpacing.sm),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Pusat bantuan'),
                          subtitle: const Text(
                            'Panduan menggunakan KantinCerdas.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push(Routes.help);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Syarat dan ketentuan'),
                          subtitle: const Text(
                            'Ketentuan penggunaan aplikasi.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push(Routes.terms);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Tentang aplikasi'),
                          subtitle: const Text(AppBuildInfo.displayVersion),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _openAbout,
                        ),
                      ],
                    ),
                  ),
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
          ),
        ),
      ),
    );
  }
}
