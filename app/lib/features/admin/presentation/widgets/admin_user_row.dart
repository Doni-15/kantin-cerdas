import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_status_pills.dart';

class AdminUserRow extends StatelessWidget {
  const AdminUserRow({super.key, required this.user, required this.onTap});

  final AdminManagedUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(user.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                user.role.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              buildAccountStatusPill(context, user.isActive),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
