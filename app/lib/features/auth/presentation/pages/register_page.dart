import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/register_form.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  static const _formMaxWidth = 440.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(KcSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _formMaxWidth,
                      ),
                      child: const RegisterForm(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
