import 'package:flutter/material.dart';

import 'package:kantin_cerdas/core/design_system/kc_theme.dart';

class KantinCerdasApp extends StatelessWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KantinCerdas',
      theme: KcTheme.light,
      darkTheme: KcTheme.dark,
      themeMode: ThemeMode.system,

      // home: const SplashScreen(),
    );
  }
}