import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/app/router/app_router.dart';
import 'package:kantin_cerdas/core/settings/app_settings_provider.dart';
import 'package:kantin_cerdas/theme/kc_theme_exports.dart';

class KantinCerdasApp extends ConsumerWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      appSettingsProvider.select((settings) => settings.themeMode),
    );

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KantinCerdas',
      debugShowCheckedModeBanner: false,
      theme: KcTheme.light,
      darkTheme: KcTheme.dark,
      themeMode: themeMode,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
