import 'package:flutter/material.dart';
import 'package:kantincerdas/app/foundation_screen.dart';

class KantinCerdasApp extends StatelessWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KantinCerdas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE85D2A)),
        useMaterial3: true,
      ),
      home: const FoundationScreen(),
    );
  }
}
