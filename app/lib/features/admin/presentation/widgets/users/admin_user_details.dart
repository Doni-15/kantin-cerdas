import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
import 'package:kantin_cerdas/features/admin/presentation/mappers/admin_user_labels.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminUserDetails extends StatelessWidget {
  const AdminUserDetails({super.key, required this.record});
  final AdminUserRecord record;
  @override
  Widget build(BuildContext context) {
    final user = record.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('@${user.username}'),
            const SizedBox(height: KcSpacing.sm),
            SelectableText(user.email),
            SelectableText('ID pengguna: ${user.id}'),
            const SizedBox(height: KcSpacing.sm),
            Wrap(
              spacing: KcSpacing.xs,
              runSpacing: KcSpacing.xs,
              children: [
                Chip(label: Text(adminUserRoleLabel(user.role))),
                Chip(
                  avatar: Icon(
                    user.isActive ? Icons.check_circle_outline : Icons.block,
                  ),
                  label: Text(adminUserAccessLabel(user.isActive)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
