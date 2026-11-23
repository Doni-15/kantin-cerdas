import 'dart:typed_data';

import 'package:flutter/material.dart';

class AuthAccountProfileHeader extends StatelessWidget {
  const AuthAccountProfileHeader({
    super.key,
    required this.displayName,
    required this.email,
    required this.roleLabel,
    required this.photoBytes,
    required this.busy,
    required this.onUpdatePhoto,
  });

  final String displayName;
  final String email;
  final String roleLabel;
  final Uint8List? photoBytes;
  final bool busy;
  final VoidCallback onUpdatePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: colors.surfaceContainerHighest,
                foregroundImage: photoBytes == null
                    ? null
                    : MemoryImage(photoBytes!),
                child: const Icon(Icons.person_outline, size: 40),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: colors.primary,
                  shape: CircleBorder(
                    side: BorderSide(color: colors.surface, width: 2),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: busy ? null : onUpdatePhoto,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
