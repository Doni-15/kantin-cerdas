import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_info_tile.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_section.dart';

/// Blok "Informasi Akun" yang sama untuk semua role.
class ProfileAccountInfo extends StatelessWidget {
  const ProfileAccountInfo({
    super.key,
    required this.name,
    required this.username,
    required this.email,
  });

  final String name;
  final String username;
  final String email;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Informasi Akun',
      child: Column(
        children: [
          ProfileInfoTile(
            icon: Icons.person_outline,
            label: 'Nama',
            value: name,
          ),
          const Divider(height: 1, indent: 72),
          ProfileInfoTile(
            icon: Icons.alternate_email,
            label: 'Username',
            value: username,
          ),
          const Divider(height: 1, indent: 72),
          ProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
        ],
      ),
    );
  }
}
