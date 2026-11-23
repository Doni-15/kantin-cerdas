import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/dialogs/account_edit_dialog.dart';

class AuthAccountSettingsCard extends StatelessWidget {
  const AuthAccountSettingsCard({
    super.key,
    required this.account,
    required this.hasPhotoBytes,
    required this.hasCustomName,
    required this.customName,
    required this.busy,
    required this.onUpdatePhoto,
    required this.onEdit,
  });

  final AuthAccount account;
  final bool hasPhotoBytes;
  final bool hasCustomName;
  final String? customName;
  final bool busy;
  final VoidCallback onUpdatePhoto;
  final ValueChanged<AccountEdit> onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              AuthAccountMenuTile(
                icon: Icons.photo_camera_outlined,
                title: hasPhotoBytes
                    ? 'Ganti foto profil'
                    : 'Tambahkan foto profil',
                onTap: busy ? null : onUpdatePhoto,
              ),
              const Divider(height: 1, indent: 52),
              AuthAccountMenuTile(
                icon: Icons.badge_outlined,
                title: 'Ubah nama',
                subtitle: hasCustomName ? customName : 'Belum diatur',
                onTap: busy ? null : () => onEdit(AccountEdit.name),
              ),
              if (account.canManageCredentials) ...[
                const Divider(height: 1, indent: 52),
                AuthAccountMenuTile(
                  icon: Icons.email_outlined,
                  title: 'Ubah email',
                  subtitle: account.email,
                  onTap: busy ? null : () => onEdit(AccountEdit.email),
                ),
                const Divider(height: 1, indent: 52),
                AuthAccountMenuTile(
                  icon: Icons.lock_outline,
                  title: 'Ubah password',
                  onTap: busy ? null : () => onEdit(AccountEdit.password),
                ),
              ],
            ],
          ),
        ),
        if (!account.canManageCredentials) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kelola email dan password akun Google melalui Google.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class AuthAccountMenuTile extends StatelessWidget {
  const AuthAccountMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: colors.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
      trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
    );
  }
}
