import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/kantin_cerdas_app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: KantinCerdasApp(),
    ),
  );
}