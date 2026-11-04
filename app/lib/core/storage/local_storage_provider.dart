import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';

/// Menyediakan storage lokal yang sudah disiapkan oleh bootstrap.
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw StateError(
    'localStorageProvider harus di-override melalui bootstrap().',
  );
});
