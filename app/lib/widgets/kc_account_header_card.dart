import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class KcAccountHeaderRow extends StatelessWidget {
  const KcAccountHeaderRow({
    super.key,
    required this.displayName,
    required this.email,
    required this.roleLabel,
    this.avatarBytes,
    this.avatarRadius = 28,
    this.roleSpacing = 4,
  });

  final String displayName;
  final String email;
  final String roleLabel;
  final Uint8List? avatarBytes;
  final double avatarRadius;
  final double roleSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          foregroundImage: avatarBytes == null
              ? null
              : MemoryImage(avatarBytes!),
          child: const Icon(Icons.person_outline),
        ),
        const SizedBox(width: KcSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: roleSpacing),
              Text(
                roleLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KcAccountHeaderCard extends StatelessWidget {
  const KcAccountHeaderCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.roleLabel,
    this.avatarBytes,
  });

  final String displayName;
  final String email;
  final String roleLabel;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: KcAccountHeaderRow(
          displayName: displayName,
          email: email,
          roleLabel: roleLabel,
          avatarBytes: avatarBytes,
        ),
      ),
    );
  }
}
