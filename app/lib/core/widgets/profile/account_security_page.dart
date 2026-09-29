import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/router/routes.dart';

class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan Akun'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          // Deskripsi ringkas pengganti judul besar yang redundan
          Text(
            'Kelola keamanan dan akses akun kamu.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionTitle(context, 'Keamanan'),
          const SizedBox(height: 12),
          _buildCustomCard(
            context: context,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: _buildLeadingIcon(context, Icons.lock_outline),
                title: const Text(
                  'Ubah Password',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Perbarui password akun secara berkala'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.changePassword),
              ),
              const Divider(height: 1, indent: 64), // Indent agar sejajar teks
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: _buildLeadingIcon(
                  context,
                  Icons.mark_email_read_outlined,
                ),
                title: const Text(
                  'Verifikasi Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Pastikan alamat email akun sudah terverifikasi',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Aktivitas Akun'),
          const SizedBox(height: 12),
          _buildCustomCard(
            context: context,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: _buildLeadingIcon(context, Icons.devices_outlined),
                title: const Text(
                  'Perangkat yang Login',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Lihat perangkat yang sedang menggunakan akun',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: _buildLeadingIcon(context, Icons.history_outlined),
                title: const Text(
                  'Aktivitas Login',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Lihat riwayat aktivitas login akun'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ],
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

  // Widget helper untuk menyeragamkan ikon bulat bergaya Profil & Pengaturan
  Widget _buildLeadingIcon(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: Icon(icon, color: colorScheme.onSurfaceVariant),
    );
  }

  // Widget helper untuk Card dengan border tipis modern
  Widget _buildCustomCard({
    required BuildContext context,
    required List<Widget> children,
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
      child: Column(children: children),
    );
  }
}
