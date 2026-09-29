import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/router/app_router.dart';
import 'package:kantin_cerdas/core/settings/app_settings_provider.dart';
import 'package:kantin_cerdas/theme/kc_theme.dart';

class KantinCerdasApp extends ConsumerWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'KantinCerdas',
      theme: KcTheme.light,
      darkTheme: KcTheme.dark,
      themeMode: ref.watch(appSettingsProvider.select((s) => s.themeMode)),
      
      routerConfig: ref.watch(routerProvider),
    );
  }
}