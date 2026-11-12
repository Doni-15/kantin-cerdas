import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/change_password_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/change_password_form.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class ChangePasswordPage extends ConsumerWidget {
  const ChangePasswordPage({super.key});

  static const _formMaxWidth = 440.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      changePasswordControllerProvider.select((state) => state.isLoading),
    );

    return PopScope<Object?>(
      canPop: !isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ubah password'),
          leading: IconButton(
            tooltip: 'Kembali',
            icon: const BackButtonIcon(),
            onPressed: isSubmitting
                ? null
                : () {
                    FocusScope.of(context).unfocus();

                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(Routes.accountSecurity);
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
                child: const ChangePasswordForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
