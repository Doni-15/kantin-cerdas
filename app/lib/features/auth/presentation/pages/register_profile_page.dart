import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/app/router/auth_destination.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/register_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/register_draft_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/register_profile_form.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class RegisterProfilePage extends ConsumerWidget {
  const RegisterProfilePage({super.key});
  static const _formMaxWidth = 440.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(registerDraftProvider);
    final isSubmitting = ref.watch(
      registerControllerProvider.select((state) => state.isLoading),
    );

    return PopScope<Object?>(
      canPop: !isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lengkapi profil'),
          leading: IconButton(
            tooltip: 'Kembali',
            icon: const BackButtonIcon(),
            onPressed: isSubmitting
                ? null
                : () {
                    FocusScope.of(context).unfocus();

                    if (context.canPop()) {
                      // Kembali biasa menghasilkan null untuk tahap pertama.
                      context.pop();
                    } else {
                      context.go(
                        continueAuthLocation(
                          GoRouterState.of(context).uri,
                          Routes.register,
                        ),
                      );
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(KcSpacing.lg),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                child: draft == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Isi data akun terlebih dahulu '
                            'untuk melanjutkan pendaftaran.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: KcSpacing.lg),
                          KcButton(
                            label: 'Mulai pendaftaran',
                            onPressed: () {
                              context.go(
                                continueAuthLocation(
                                  GoRouterState.of(context).uri,
                                  Routes.register,
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : const RegisterProfileForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
