import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/auth_destination.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/password_reset_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/password_reset_form.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class PasswordResetPage extends ConsumerWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      passwordResetControllerProvider.select((s) => s.isSubmitting),
    );
    void backToLogin() {
      FocusScope.of(context).unfocus();
      // Works for both direct links and navigation from login, preserving next.
      context.go(
        continueAuthLocation(GoRouterState.of(context).uri, Routes.login),
      );
    }

    return PopScope<Object?>(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lupa password'),
          leading: IconButton(
            tooltip: 'Kembali ke masuk',
            icon: const BackButtonIcon(),
            onPressed: busy ? null : backToLogin,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(KcSpacing.lg),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: PasswordResetForm(onBackToLogin: backToLogin),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
