import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kantin_cerdas/app/bootstrap.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/kantin_cerdas_app.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/theme/kc_theme.dart';

/// Menyiapkan dependensi penyimpanan lokal sebelum membangun ProviderScope utama.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});
  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<List<Override>> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _start();
  }

  Future<List<Override>> _start() =>
      bootstrap().timeout(const Duration(seconds: 15));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Override>>(
      future: _initialization,
      builder: (context, snapshot) {
        final finished = snapshot.connectionState == ConnectionState.done;
        if (finished && snapshot.hasData) {
          return ProviderScope(
            overrides: snapshot.data!,
            child: const KantinCerdasApp(),
          );
        }
        final failed = finished && snapshot.hasError;
        return _BootstrapStatusShell(
          failed: failed,
          onRetry: failed
              ? () => setState(() {
                  _initialization = _start();
                })
              : null,
        );
      },
    );
  }
}

class _BootstrapStatusShell extends StatelessWidget {
  const _BootstrapStatusShell({required this.failed, this.onRetry});

  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KantinCerdas',
      debugShowCheckedModeBanner: false,
      theme: KcTheme.light,
      darkTheme: KcTheme.dark,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(KcSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: KcStatusPanel(
                  title: failed
                      ? 'Aplikasi belum siap'
                      : 'Menyiapkan KantinCerdas',
                  message: failed
                      ? 'Pengaturan di perangkat belum dapat dibaca. Coba lagi untuk melanjutkan.'
                      : 'Mohon tunggu sebentar.',
                  loading: !failed,
                  icon: Icons.error_outline,
                  action: onRetry != null
                      ? KcButton(label: 'Coba lagi', onPressed: onRetry)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
