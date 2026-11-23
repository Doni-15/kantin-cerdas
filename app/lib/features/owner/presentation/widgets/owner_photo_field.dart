import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerPhotoField extends StatelessWidget {
  const OwnerPhotoField({
    super.key,
    required this.title,
    required this.bytes,
    required this.busy,
    required this.onPick,
    this.onRemove,
    this.emptyIcon = Icons.storefront_outlined,
  });

  final String title;
  final Uint8List? bytes;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KcRadius.small),
              child: Container(
                width: 68,
                height: 68,
                color: theme.colorScheme.surfaceContainerHighest,
                child: bytes == null
                    ? Icon(emptyIcon, color: theme.colorScheme.onSurfaceVariant)
                    : Image.memory(
                        bytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(emptyIcon),
                      ),
              ),
            ),
            const SizedBox(width: KcSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: KcSpacing.xs,
                    runSpacing: 4,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : onPick,
                        child: Text(
                          bytes == null ? 'Pilih foto' : 'Ganti foto',
                        ),
                      ),
                      if (bytes != null && onRemove != null)
                        TextButton(
                          onPressed: busy ? null : onRemove,
                          child: const Text('Hapus foto'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
