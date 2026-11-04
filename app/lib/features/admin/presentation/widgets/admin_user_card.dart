import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/admin/presentation/mappers/admin_user_labels.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminUserCard extends StatelessWidget {
  const AdminUserCard({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = adminUserRoleLabel(user.role);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(user.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: KcSpacing.xs),
            Text('@${user.username}'),
            Text(user.email),
            const SizedBox(height: KcSpacing.sm),
            Wrap(
              spacing: KcSpacing.xs,
              runSpacing: KcSpacing.xs,
              children: [
                Chip(label: Text(role)),
                Chip(
                  avatar: Icon(
                    user.isActive ? Icons.check_circle_outline : Icons.block,
                  ),
                  label: Text(adminUserAccessLabel(user.isActive)),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.sm),
            OutlinedButton(
              onPressed: () =>
                  context.push(Routes.adminUserDetailLocation(user.id)),
              child: const Text('Buka detail pengguna'),
            ),
          ],
        ),
      ),
    );
  }
}
