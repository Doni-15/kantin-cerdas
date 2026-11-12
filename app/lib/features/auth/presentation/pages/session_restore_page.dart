import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/app/router/auth_destination.dart';
import 'package:kantin_cerdas/core/widgets/kc_brand.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/logout_button.dart';

class SessionRestorePage extends ConsumerWidget {
  const SessionRestorePage({super.key});

  static const _contentMaxWidth = 440.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Saat retry, tampilkan loading meskipun error sebelumnya masih tersimpan.
    final error = authState.isLoading ? null : authState.asError?.error;

    final progressMessage = authState.isLoading
        ? 'Memeriksa status sesi...'
        : 'Menyiapkan halaman...';

    final theme = Theme.of(context);

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
                  const Center(child: KcBrand(logoSize: 60)),
                  const SizedBox(height: KcSpacing.lg),
                  if (error == null) ...[
                    Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: progressMessage,
                      ),
                    ),
                    const SizedBox(height: KcSpacing.md),
                    Text(
                      progressMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ] else ...[
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: KcSpacing.md),
                    Text(
                      'Sesi belum dapat dipulihkan',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: KcSpacing.xs),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        authErrorMessage(error),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: KcSpacing.lg),
                    KcButton(
                      label: 'Coba lagi',
                      leading: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.read(authStateProvider.notifier).retryRestore();
                      },
                    ),
                    const SizedBox(height: KcSpacing.sm),
                    KcButton(
                      label: 'Ke halaman masuk',
                      variant: KcButtonVariant.outlined,
                      onPressed: () {
                        // Pilihan eksplisit pengguna; tidak menghapus
                        // token atau mengubah status autentikasi.
                        context.go(
                          continueAuthLocation(
                            GoRouterState.of(context).uri,
                            Routes.login,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: KcSpacing.sm),
                    const LogoutButton(confirmBeforeLogout: false),
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
