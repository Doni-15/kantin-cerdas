import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';

/// Di-override di main() dengan instance yang sudah siap (LocalStorage.create()).
/// Di test, override dengan LocalStorage dari SharedPreferences.setMockInitialValues.
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError(
    'localStorageProvider harus di-override dengan LocalStorage yang sudah siap.',
  );
});
