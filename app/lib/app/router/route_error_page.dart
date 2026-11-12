import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({super.key});
  static const _contentMaxWidth = 440.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = context.canPop();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KcSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: KcSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      'Halaman tidak dapat dibuka',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: KcSpacing.xs),
                  Text(
                    'Halaman yang dituju tidak dapat ditampilkan. '
                    'Silakan lanjutkan melalui halaman utama.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: KcSpacing.lg),
                  KcButton(
                    label: 'Ke halaman utama',
                    leading: const Icon(Icons.home_outlined),
                    onPressed: () {
                      context.go(Routes.app);
                    },
                  ),
                  if (canGoBack) ...[
                    const SizedBox(height: KcSpacing.sm),
                    KcButton(
                      label: 'Kembali',
                      variant: KcButtonVariant.outlined,
                      leading: const Icon(Icons.arrow_back),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
