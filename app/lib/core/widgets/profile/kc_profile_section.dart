import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_card.dart';

/// Satu blok di halaman profil: judul + kartu berisi [child].
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ProfileCard(child: child),
      ],
    );
  }
}
