import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_action_tile.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_section.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_setting_part.dart';

/// Blok "Akun > Pengaturan" yang sama untuk semua role.
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Akun',
      child: ProfileActionTile(
        icon: Icons.settings_outlined,
        title: 'Pengaturan',
        subtitle: 'Kelola pengaturan akun',
        onTap: () => _openSettings(context),
      ),
    );
  }
}
