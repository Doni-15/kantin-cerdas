import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Semua key penyimpanan di satu tempat agar tidak bentrok antar feature.
abstract final class StorageKeys {
  // Auth
  static const authTokens = 'auth.tokens';
  static const authDummyState = 'auth.dummy_state';

  // Customer
  static const canteenApplicationDummyState =
      'customer.canteen_application.dummy_state';

  // Settings
  static const themeMode = 'settings.theme_mode';
  static const notificationsEnabled = 'settings.notifications_enabled';
}

/// Penyimpanan key-value lokal yang dipakai bersama seluruh feature.
///
/// Method tulis mengembalikan `false` jika gagal menyimpan (tidak melempar),
/// method baca tidak pernah melempar untuk data rusak (mengembalikan null).
class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorage> create() async {
    return LocalStorage(await SharedPreferences.getInstance());
  }

  String? getString(String key) => _prefs.getString(key);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setString(String key, String value) {
    return _guard(() => _prefs.setString(key, value));
  }

  Future<bool> setBool(String key, bool value) {
    return _guard(() => _prefs.setBool(key, value));
  }

  Future<bool> remove(String key) {
    return _guard(() => _prefs.remove(key));
  }

  /// Membaca JSON object. Null jika belum ada, bukan object, atau isinya rusak.
  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);

    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<bool> writeJson(String key, Map<String, dynamic> value) {
    return setString(key, jsonEncode(value));
  }

  Future<bool> _guard(Future<bool> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return false;
    }
  }
}
