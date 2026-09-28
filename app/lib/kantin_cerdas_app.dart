import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/router/app_router.dart';
import 'package:kantin_cerdas/theme/kc_theme.dart';

class KantinCerdasApp extends StatelessWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'KantinCerdas',
      theme: KcTheme.light,
      darkTheme: KcTheme.dark,
      themeMode: ThemeMode.system,
      
      routerConfig: appRouter,
    );
  }
}