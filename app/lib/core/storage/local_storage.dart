import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal untuk preferensi dan data sederhana.
class LocalStorage {
  const LocalStorage._(this._preferences, this._prefix);
  final String _prefix;
  final SharedPreferencesWithCache _preferences;

  /// Membuka penyimpanan dan memuat cache sebelum digunakan aplikasi.
  static Future<LocalStorage> create({String prefix = ''}) async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return LocalStorage._(preferences, prefix);
  }

  /// Null jika key belum tersedia atau nilainya berbeda tipe.
  String? getString(String key) {
    final value = _preferences.get('$_prefix$key');
    return value is String ? value : null;
  }

  /// Null jika key belum tersedia atau nilainya berbeda tipe.
  bool? getBool(String key) {
    final value = _preferences.get('$_prefix$key');
    return value is bool ? value : null;
  }

  Future<void> setString(String key, String value) {
    return _preferences.setString('$_prefix$key', value);
  }

  Future<void> setBool(String key, bool value) {
    return _preferences.setBool('$_prefix$key', value);
  }

  Future<void> remove(String key) {
    return _preferences.remove('$_prefix$key');
  }
}
