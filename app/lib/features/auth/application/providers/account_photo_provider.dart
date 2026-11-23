import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart'
    show authControllerProvider;
import 'package:kantin_cerdas/features/auth/application/providers/auth_repository_provider.dart';

final accountPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, accountId) async {
      final hasMatchingSession = ref.watch(
        authControllerProvider.select((state) {
          final session = state.asData?.value;
          return session != null && session.account.id == accountId;
        }),
      );
      if (!hasMatchingSession) return null;
      final session = ref.read(authControllerProvider).asData?.value;
      if (session == null || session.account.id != accountId) return null;
      final bytes = await ref.watch(authRepositoryProvider).loadAvatar(session);
      if (!ref.mounted) return null;
      return bytes;
    }, retry: (_, _) => null);
