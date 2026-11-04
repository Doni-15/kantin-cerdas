import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerPageBody extends StatelessWidget {
  const OwnerPageBody({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });
  final String title;
  final String description;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KcSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: KcSpacing.xs),
                Text(description),
                const SizedBox(height: KcSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
