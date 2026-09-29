import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_action_tile.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_section.dart';

/// Blok "Kantin" di halaman profil: pintu masuk ke pengajuan buka kantin.
class CustomerCanteenSection extends StatelessWidget {
  const CustomerCanteenSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Kantin',
      child: ProfileActionTile(
        icon: Icons.storefront_outlined,
        title: 'Buka Kantin',
        subtitle: 'Ajukan untuk menjadi pemilik kantin',
        onTap: () => context.push(Routes.canteenApplication),
      ),
    );
  }
}
