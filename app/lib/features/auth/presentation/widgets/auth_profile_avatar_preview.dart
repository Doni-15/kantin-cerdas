import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/domain/avatar_picker.dart';

class AuthProfileAvatarPreview extends StatelessWidget {
  const AuthProfileAvatarPreview({
    super.key,
    required this.selectedPhoto,
    required this.storedPhotoBytes,
    required this.googlePhotoUrl,
  });

  static const _avatarRadius = 42.0;
  static const _avatarDiameter = 84.0;

  final PickedAvatar? selectedPhoto;
  final Uint8List? storedPhotoBytes;
  final String? googlePhotoUrl;

  @override
  Widget build(BuildContext context) {
    final selected = selectedPhoto;
    final stored = storedPhotoBytes;
    final google = googlePhotoUrl;

    return Center(
      child: CircleAvatar(
        radius: _avatarRadius,
        foregroundImage: selected != null
            ? MemoryImage(selected.bytes)
            : stored == null
            ? null
            : MemoryImage(stored),
        onForegroundImageError: selected != null || stored != null
            ? (_, _) {}
            : null,
        child: google != null && selected == null
            ? ClipOval(
                child: Image.network(
                  google,
                  width: _avatarDiameter,
                  height: _avatarDiameter,
                  fit: BoxFit.cover,
                  semanticLabel: 'Foto profil Google',
                  errorBuilder: (_, _, _) => const Icon(Icons.person_outline),
                ),
              )
            : const Icon(Icons.person_outline),
      ),
    );
  }
}
