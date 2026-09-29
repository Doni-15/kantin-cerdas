import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/kantin_cerdas_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(await LocalStorage.create()),
    ],
  );

  await _restoreSession(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KantinCerdasApp(),
    ),
  );
}

/// Memulihkan sesi sebelum UI tampil agar router langsung ke halaman yang benar.
/// Dibatasi waktu supaya aplikasi tidak menggantung di layar kosong.
Future<void> _restoreSession(ProviderContainer container) async {
  try {
    await container
        .read(authStateProvider.notifier)
        .restoreSession()
        .timeout(const Duration(seconds: 8));
  } on TimeoutException {
    // Lanjut ke login. Jika pemulihan selesai kemudian, auth state terisi dan
    // router otomatis mengarahkan ke halaman utama.
  }
}
