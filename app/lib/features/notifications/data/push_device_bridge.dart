import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_messaging_client.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_notification_payload.dart';

/// Abstraction for Android FCM registration token retrieval and token refresh.
abstract interface class PushTokenSource {
  /// Requests notification permission (Android 13+) when appropriate and
  /// returns the current Android FCM token, or `null` when Firebase Messaging
  /// is not configured or notification permission was denied by the user.
  Future<String?> getAndroidFcmToken();

  /// Emits refreshed Android FCM tokens while the app is running.
  Stream<String> get onTokenRefresh;

  /// Returns a stable per-installation device identifier for device binding
  /// and clean logout revocation (`R2`).
  Future<String> getOrCreateDeviceId();
}

/// Real Android [PushTokenSource] backed by [PushMessagingClient] (Firebase Messaging)
/// and secure per-installation device ID persistence.
class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource({
    required this._client,
    FlutterSecureStorage? storage,
  }) : _deviceIdStore = _DeviceIdStore(storage);

  final PushMessagingClient _client;
  final _DeviceIdStore _deviceIdStore;
  var _permissionGranted = false;

  @override
  Future<String?> getAndroidFcmToken() async {
    final initialized = await _client.ensureInitialized();
    if (!initialized) return null;

    final permission = await _client.requestNotificationPermission();
    if (permission != PushPermissionOutcome.granted) {
      _permissionGranted = false;
      return null;
    }

    _permissionGranted = true;
    return _client.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => _client.onTokenRefresh.where(
    (token) => _permissionGranted && token.trim().isNotEmpty,
  );

  @override
  Future<String> getOrCreateDeviceId() => _deviceIdStore.getOrCreateDeviceId();
}

/// Safe fallback when Firebase Messaging is intentionally disabled/stubbed.
class DefaultPushTokenSource implements PushTokenSource {
  DefaultPushTokenSource({FlutterSecureStorage? storage})
    : _deviceIdStore = _DeviceIdStore(storage);

  final _DeviceIdStore _deviceIdStore;

  @override
  Future<String?> getAndroidFcmToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<String> getOrCreateDeviceId() => _deviceIdStore.getOrCreateDeviceId();
}

class _DeviceIdStore {
  _DeviceIdStore(this._storage);

  static const _deviceIdKey = 'kc_notifications_device_id';
  final FlutterSecureStorage? _storage;
  String? _cachedDeviceId;

  Future<String> getOrCreateDeviceId() async {
    final cached = _cachedDeviceId;
    if (cached != null) return cached;

    if (!kIsWeb && _storage != null) {
      try {
        final stored = await _storage.read(key: _deviceIdKey);
        if (stored != null && stored.trim().isNotEmpty) {
          _cachedDeviceId = stored.trim();
          return _cachedDeviceId!;
        }
      } catch (_) {
        // Fallback to in-memory generated identifier.
      }
    }

    final generated = _generateDeviceId();
    _cachedDeviceId = generated;
    if (!kIsWeb && _storage != null) {
      try {
        await _storage.write(key: _deviceIdKey, value: generated);
      } catch (_) {
        // Best-effort persistence.
      }
    }
    return generated;
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'android-$hex';
  }
}
