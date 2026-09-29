import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/profile/account_security_page.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_account_info.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_action_tile.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_section.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_settings_section.dart';
import 'package:kantin_cerdas/core/widgets/profile/ks_profile_header.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/logout_button.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({
    super.key,
    required this.user,
  });

  final User user;

  void _openAccountSecurity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AccountSecurityPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Text(
            'Profil',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          ProfileHeader(
            name: user.name,
            username: user.username,
          ),
          const SizedBox(height: 40),
          ProfileAccountInfo(
            name: user.name,
            username: user.username,
            email: user.email,
          ),
          const SizedBox(height: 32),
          const ProfileSettingsSection(),
          const SizedBox(height: 32),
          ProfileSection(
            title: 'Lainnya',
            child: Column(
              children: [
                ProfileActionTile(
                  icon: Icons.shield_outlined,
                  title: 'Keamanan Akun',
                  onTap: () => _openAccountSecurity(context),
                ),
                const Divider(height: 1, indent: 72),
                // Belum tersedia untuk Admin: Pusat Bantuan hanya punya konten
                // Customer dan Owner (HelpRole).
                ProfileActionTile(
                  icon: Icons.help_outline,
                  title: 'Pusat Bantuan',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 72),
                // Belum tersedia untuk Admin: isi Syarat & Ketentuan membahas
                // pemesanan dan pengajuan kantin.
                ProfileActionTile(
                  icon: Icons.description_outlined,
                  title: 'Syarat & Ketentuan',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Kantin Cerdas v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const LogoutButton(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
