import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const defaultSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: false),
);

/// Satu-satunya provider FlutterSecureStorage terpusat untuk seluruh aplikasi.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return defaultSecureStorage;
});
