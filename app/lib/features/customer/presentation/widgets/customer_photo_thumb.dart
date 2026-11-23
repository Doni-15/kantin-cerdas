import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';

class CustomerMediaThumb extends ConsumerWidget {
  const CustomerMediaThumb({
    super.key,
    required this.accountId,
    required this.targetId,
    required this.isStall,
    required this.hasPhoto,
    this.size = 60,
    this.fallbackIcon = Icons.restaurant_outlined,
  });

  final String accountId;
  final String targetId;
  final bool isStall;
  final bool hasPhoto;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Uint8List? bytes;
    if (hasPhoto) {
      final photoAsync = isStall
          ? ref.watch(
              customerStallPhotoProvider((
                accountId: accountId,
                stallId: targetId,
              )),
            )
          : ref.watch(
              customerMenuPhotoProvider((
                accountId: accountId,
                menuId: targetId,
              )),
            );
      bytes = photoAsync.asData?.value;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(KcRadius.small),
      child: Container(
        width: size,
        height: size,
        color: theme.colorScheme.surfaceContainerHighest,
        child: bytes != null
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  fallbackIcon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Icon(fallbackIcon, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
