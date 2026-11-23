import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_messaging_client.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_notification_payload.dart';

var _backgroundHandlerRegistered = false;

/// Top-level background FCM isolate entrypoint required by Firebase Messaging.
/// Validates payload against the 7 ORDER-017A events without logging sensitive
/// data or mutating authoritative order state locally.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    return;
  }

  // Validate against ORDER-017A contract; OS displays the notification block
  // automatically while backgrounded and Flutter re-fetches REST truth on open.
  PushNotificationPayload.tryParseRemoteData(
    message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );
}

/// Initializes Firebase Core & registers the background handler safely on Android.
/// Returns `false` (never throwing) when `google-services.json` is absent or on
/// non-Android targets so core app flows and checkout remain 100% unaffected.
Future<bool> initializeFirebaseMessagingSafely() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    if (!_backgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _backgroundHandlerRegistered = true;
    }
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Real Android Firebase Messaging implementation of [PushMessagingClient].
/// Gracefully degrades to unavailable when official Firebase configuration
/// (`app/android/app/google-services.json`) has not been supplied yet.
class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient();

  var _unavailable = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> ensureInitialized() async {
    if (!_isAndroid || _unavailable) return false;
    if (Firebase.apps.isNotEmpty) return true;
    final ok = await initializeFirebaseMessagingSafely();
    if (!ok) _unavailable = true;
    return ok;
  }

  @override
  Future<PushPermissionOutcome> requestNotificationPermission() async {
    if (!await ensureInitialized()) {
      return PushPermissionOutcome.unavailable;
    }
    try {
      // Triggers Android 13+ (API 33+) POST_NOTIFICATIONS runtime permission
      // prompt and succeeds immediately on Android 12 and below.
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermissionOutcome.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PushPermissionOutcome.denied,
        AuthorizationStatus.notDetermined =>
          PushPermissionOutcome.notDetermined,
      };
    } catch (_) {
      return PushPermissionOutcome.unavailable;
    }
  }

  @override
  Future<String?> getToken() async {
    if (!await ensureInitialized()) return null;
    try {
      // Backend FCM HTTP v1 targets standard device registration tokens (`message.token`).
      // ignore: deprecated_member_use
      final token = (await FirebaseMessaging.instance.getToken())?.trim();
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh {
    if (!_isAndroid || _unavailable || Firebase.apps.isEmpty) {
      return const Stream<String>.empty();
    }
    try {
      // Matches `getToken()` registration token contract with backend `/v1/notifications/devices`.
      // ignore: deprecated_member_use
      return FirebaseMessaging.instance.onTokenRefresh
          .map((token) => token.trim())
          .where((token) => token.isNotEmpty);
    } catch (_) {
      return const Stream<String>.empty();
    }
  }

  @override
  Stream<PushNotificationPayload> get onForegroundMessage {
    if (!_isAndroid || _unavailable || Firebase.apps.isEmpty) {
      return const Stream<PushNotificationPayload>.empty();
    }
    return _mapRemoteMessages(FirebaseMessaging.onMessage);
  }

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp {
    if (!_isAndroid || _unavailable || Firebase.apps.isEmpty) {
      return const Stream<PushNotificationPayload>.empty();
    }
    return _mapRemoteMessages(FirebaseMessaging.onMessageOpenedApp);
  }

  @override
  Future<PushNotificationPayload?> getInitialMessage() async {
    if (!await ensureInitialized()) return null;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) return null;
      return _toPayload(message);
    } catch (_) {
      return null;
    }
  }

  Stream<PushNotificationPayload> _mapRemoteMessages(
    Stream<RemoteMessage> source,
  ) async* {
    await for (final message in source) {
      final payload = _toPayload(message);
      if (payload != null) {
        yield payload;
      }
    }
  }

  PushNotificationPayload? _toPayload(RemoteMessage message) {
    return PushNotificationPayload.tryParseRemoteData(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }
}
