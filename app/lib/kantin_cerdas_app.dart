import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/app/auth_view.dart';
import 'package:kantin_cerdas/core/theme/theme_mode_provider.dart';
import 'package:kantin_cerdas/theme/kc_theme.dart';

class KantinCerdasApp extends ConsumerWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Kantin Cerdas',
      debugShowCheckedModeBanner: false,
      theme: KcTheme.light,
      darkTheme: KcTheme.dark,
      themeMode: themeMode,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AuthView(),
    );
  }
}
