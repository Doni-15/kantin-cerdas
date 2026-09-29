import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/settings/app_settings_provider.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Nilai dibaca dari appSettingsProvider (tersimpan di local storage).
  // build() memanggil ref.watch agar halaman ikut diperbarui.
  ThemeMode get _themeMode => ref.read(appSettingsProvider).themeMode;

  bool get _notificationsEnabled =>
      ref.read(appSettingsProvider).notificationsEnabled;

  void _showThemeModePicker() {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return RadioGroup<ThemeMode>(
          groupValue: _themeMode,
          onChanged: _updateThemeMode,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Garis pegangan (Drag handle) khas Material 3
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mode Tampilan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRadioOption(
                  title: 'Terang',
                  subtitle: 'Gunakan tema terang',
                  icon: Icons.light_mode_outlined,
                  value: ThemeMode.light,
                  groupValue: _themeMode,
                  onChanged: (value) => _updateThemeMode(value),
                ),
                const SizedBox(height: 8),
                _buildRadioOption(
                  title: 'Gelap',
                  subtitle: 'Gunakan tema gelap',
                  icon: Icons.dark_mode_outlined,
                  value: ThemeMode.dark,
                  groupValue: _themeMode,
                  onChanged: (value) => _updateThemeMode(value),
                ),
                const SizedBox(height: 8),
                _buildRadioOption(
                  title: 'Mengikuti Sistem',
                  subtitle: 'Menyesuaikan pengaturan perangkat',
                  icon: Icons.settings_system_daydream_outlined,
                  value: ThemeMode.system,
                  groupValue: _themeMode,
                  onChanged: (value) => _updateThemeMode(value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateThemeMode(ThemeMode? value) async {
    if (value == null) return;

    // State berubah seketika; penyimpanan berjalan di belakang.
    final saving = ref.read(appSettingsProvider.notifier).setThemeMode(value);
    Navigator.of(context).pop();

    if (!await saving && mounted) {
      KcSnackBar.error(context, 'Pengaturan gagal disimpan.');
    }
  }

  Future<void> _updateNotifications(bool value) async {
    final saving = ref
        .read(appSettingsProvider.notifier)
        .setNotificationsEnabled(value);

    if (!await saving && mounted) {
      KcSnackBar.error(context, 'Pengaturan gagal disimpan.');
    }
  }

  void _showLanguagePicker() {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pilih Bahasa',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(Icons.language_outlined),
                  title: const Text(
                    'Bahasa Indonesia',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Kantin Cerdas',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Kantin Cerdas',
      children: const [
        SizedBox(height: 16),
        Text(
          'Kantin Cerdas merupakan aplikasi untuk mendukung '
          'pemesanan makanan dan pengelolaan kantin.',
        ),
      ],
    );
  }

  String _themeModeLabel() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Gelap';
      case ThemeMode.system:
        return 'Mengikuti Sistem';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appSettingsProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          _buildSectionTitle(context, 'Tampilan'),
          const SizedBox(height: 12),
          _buildCustomCard(
            context: context,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: _buildLeadingIcon(context, Icons.dark_mode_outlined),
              title: const Text(
                'Mode Tampilan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_themeModeLabel()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showThemeModePicker,
            ),
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Notifikasi'),
          const SizedBox(height: 12),
          _buildCustomCard(
            context: context,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              secondary: _buildLeadingIcon(
                context,
                Icons.notifications_outlined,
              ),
              title: const Text(
                'Notifikasi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Terima pemberitahuan dari aplikasi'),
              value: _notificationsEnabled,
              onChanged: _updateNotifications,
            ),
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Bahasa'),
          const SizedBox(height: 12),
          _buildCustomCard(
            context: context,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: _buildLeadingIcon(context, Icons.language_outlined),
              title: const Text(
                'Bahasa',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Bahasa Indonesia'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguagePicker,
            ),
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Aplikasi'),
          const SizedBox(height: 12),
          _buildCustomCard(
            context: context,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: _buildLeadingIcon(context, Icons.info_outline),
              title: const Text(
                'Tentang Aplikasi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Kantin Cerdas v1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openAbout,
            ),
          ),

          const SizedBox(height: 40),

          Center(
            child: Text(
              'Kantin Cerdas v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk ikon dengan latar belakang bulat (Menyamakan gaya halaman Profil)
  Widget _buildLeadingIcon(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: Icon(icon, color: colorScheme.onSurfaceVariant),
    );
  }

  // Widget helper untuk Card dengan desain border tipis modern
  Widget _buildCustomCard({
    required BuildContext context,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // Widget helper untuk opsi radio kustom di dalam BottomSheet agar terlihat estetik
  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<ThemeMode>(value: value),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
