import 'package:flutter/material.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_motion.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_spacing.dart';
import 'package:kantincerdas/shared/widgets/kc_button.dart';

Future<bool> showKcConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        requestFocus: true,
        animationStyle: KantinCerdasMotion.styleOf(context),
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Text(message),
          actions: [
            KcButton(
              label: 'Batal',
              autofocus: true,
              variant: KcButtonVariant.tertiary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            KcButton(
              label: confirmLabel,
              variant: destructive
                  ? KcButtonVariant.destructive
                  : KcButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ??
      false;
}

/// Builder menerima context route agar Navigator.pop menutup sheet yang tepat.
/// Konten menggunakan tinggi intrinsik, tanpa Expanded/ListView bersarang.
Future<T?> showKcBottomSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    requestFocus: true,
    sheetAnimationStyle: KantinCerdasMotion.styleOf(context),
    builder: (context) {
      final media = MediaQuery.of(context);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (media.size.height - media.viewInsets.bottom) * 0.85,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(KantinCerdasSpacing.space4),
              child: FocusTraversalGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                        IconButton(
                          autofocus: true,
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: KantinCerdasSpacing.space4),
                    builder(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showKcSnackBar({
  required BuildContext context,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  assert((actionLabel == null) == (onAction == null));
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: onAction == null
          ? null
          : SnackBarAction(label: actionLabel!, onPressed: onAction),
    ),
    snackBarAnimationStyle: KantinCerdasMotion.styleOf(context),
  );
}
