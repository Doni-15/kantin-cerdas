import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  AppSettings copyWith({ThemeMode? themeMode, bool? notificationsEnabled}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.themeMode == themeMode &&
          other.notificationsEnabled == notificationsEnabled);

  @override
  int get hashCode => Object.hash(themeMode, notificationsEnabled);
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettings> {
  static const _themeModeKey = 'settings.theme_mode';
  static const _notificationsEnabledKey = 'settings.notifications_enabled';
  Future<void> _pendingWrite = Future<void>.value();

  @override
  AppSettings build() {
    final storage = ref.watch(localStorageProvider);
    final savedMode = storage.getString(_themeModeKey);
    final savedNotifications = storage.getBool(_notificationsEnabledKey);

    final themeMode = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return AppSettings(
      themeMode: themeMode,
      notificationsEnabled: savedNotifications ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) {
    final currentRef = ref;

    final operation = _pendingWrite.then<void>((_) async {
      if (!currentRef.mounted) return;
      if (state.themeMode == mode) return;

      final storage = currentRef.read(localStorageProvider);
      await storage.setString(_themeModeKey, mode.name);

      if (!currentRef.mounted) return;

      state = state.copyWith(themeMode: mode);
    });

    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );

    return operation;
  }

  Future<void> setNotificationsEnabled(bool enabled) {
    final currentRef = ref;

    final operation = _pendingWrite.then<void>((_) async {
      if (!currentRef.mounted) return;
      if (state.notificationsEnabled == enabled) return;

      final storage = currentRef.read(localStorageProvider);
      await storage.setBool(_notificationsEnabledKey, enabled);

      if (!currentRef.mounted) return;

      state = state.copyWith(notificationsEnabled: enabled);
    });

    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );

    return operation;
  }
}
