import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_help_page.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_account_info.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_others_section.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_settings_section.dart';
import 'package:kantin_cerdas/core/widgets/profile/ks_profile_header.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/logout_button.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/profile/customer_canteen_section.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({
    super.key,
    required this.user,
  });

  final User user;

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
          const CustomerCanteenSection(),
          const SizedBox(height: 32),
          const ProfileOthersSection(helpRole: HelpRole.customer),
          const SizedBox(height: 40),
          const LogoutButton(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
