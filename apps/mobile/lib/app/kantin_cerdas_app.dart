import 'package:flutter/material.dart';
import 'package:kantincerdas/app/foundation_screen.dart';
import 'package:kantincerdas/app/theme/kantin_cerdas_theme.dart';

class KantinCerdasApp extends StatelessWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KantinCerdas',
      debugShowCheckedModeBanner: false,
      theme: KantinCerdasTheme.light,
      darkTheme: KantinCerdasTheme.dark,
      themeMode: ThemeMode.system,
      home: const FoundationScreen(),
    );
  }
}
