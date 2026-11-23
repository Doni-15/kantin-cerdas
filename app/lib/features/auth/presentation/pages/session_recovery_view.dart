import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';

class SessionRecoveryView extends ConsumerStatefulWidget {
  const SessionRecoveryView({super.key, required this.error});
  final Object error;

  @override
  ConsumerState<SessionRecoveryView> createState() =>
      _SessionRecoveryViewState();
}

class _SessionRecoveryViewState extends ConsumerState<SessionRecoveryView>
    with AuthAction<SessionRecoveryView> {
  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(
          title: 'Sesi belum pulih',
          subtitle: authMessage(widget.error),
        ),
        if (problem != null) AuthNotice(problem!),
        FilledButton(
          onPressed: busy ? null : () => ref.invalidate(authControllerProvider),
          child: const Text('Coba lagi'),
        ),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  final restart = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Masuk ulang?'),
                      content: const Text(
                        'Sesi tersimpan pada perangkat ini akan dihapus.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Hapus sesi'),
                        ),
                      ],
                    ),
                  );
                  if (restart == true && mounted) {
                    await runAction(
                      ref.read(authControllerProvider.notifier).logout,
                    );
                  }
                },
          child: const Text('Masuk ulang'),
        ),
      ],
    ),
  );
}
