import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_brand.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.showLogo = false});
  final Widget child;
  final bool showLogo;

  static const _compactWidthBreakpoint = 400.0;
  static const _maxContentWidth = 420.0;
  static const _logoSize = 64.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacing = constraints.maxWidth < _compactWidthBreakpoint
                ? KcSpacing.md
                : KcSpacing.lg;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(spacing),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 2 * spacing).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: Column(
                      children: [
                        if (showLogo) ...[
                          const KcAppLogo(size: _logoSize),
                          const SizedBox(height: KcSpacing.md),
                        ],
                        child,
                      ],
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
