import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';

/// Pengaturan aplikasi yang sudah tersedia di UI dan tersimpan di local storage.
/// (Bahasa belum punya state, jadi belum disimpan.)
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final storage = ref.read(localStorageProvider);
    final savedTheme = storage.getString(StorageKeys.themeMode);

    return AppSettings(
      themeMode: ThemeMode.values
              .where((mode) => mode.name == savedTheme)
              .firstOrNull ??
          ThemeMode.system,
      notificationsEnabled:
          storage.getBool(StorageKeys.notificationsEnabled) ?? true,
    );
  }

  /// State berubah seketika. Mengembalikan false jika gagal menyimpan.
  Future<bool> setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);

    return ref
        .read(localStorageProvider)
        .setString(StorageKeys.themeMode, mode.name);
  }

  /// State berubah seketika. Mengembalikan false jika gagal menyimpan.
  Future<bool> setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);

    return ref
        .read(localStorageProvider)
        .setBool(StorageKeys.notificationsEnabled, enabled);
  }
}
