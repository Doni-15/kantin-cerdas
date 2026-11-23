import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/notifications/application/push_notification_coordinator.dart';
import 'package:kantin_cerdas/kantin_cerdas_app.dart';

export 'package:kantin_cerdas/kantin_cerdas_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseMessagingSafely();

  runApp(const ProviderScope(child: KantinCerdasApp()));
}
