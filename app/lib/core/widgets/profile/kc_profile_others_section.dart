import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/profile/account_security_page.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_help_page.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_action_tile.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_section.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_terms_page.dart';

/// Blok "Lainnya" (Keamanan Akun, Pusat Bantuan, Syarat & Ketentuan) + versi aplikasi.
///
/// Isi Pusat Bantuan mengikuti [helpRole]. Hanya untuk role yang punya
/// konten bantuan (lihat HelpRole).
class ProfileOthersSection extends StatelessWidget {
  const ProfileOthersSection({
    super.key,
    required this.helpRole,
  });

  final HelpRole helpRole;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSection(
          title: 'Lainnya',
          child: Column(
            children: [
              ProfileActionTile(
                icon: Icons.shield_outlined,
                title: 'Keamanan Akun',
                onTap: () => _open(context, const AccountSecurityPage()),
              ),
              const Divider(height: 1, indent: 72),
              ProfileActionTile(
                icon: Icons.help_outline,
                title: 'Pusat Bantuan',
                onTap: () => _open(context, HelpPage(role: helpRole)),
              ),
              const Divider(height: 1, indent: 72),
              ProfileActionTile(
                icon: Icons.description_outlined,
                title: 'Syarat & Ketentuan',
                onTap: () => _open(context, const KcTermsPage()),
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
      ],
    );
  }
}
