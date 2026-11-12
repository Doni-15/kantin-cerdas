import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

/// Tempatkan pada halaman tanpa draft. Router menangani loading/error restore.
class RefreshSessionButton extends ConsumerWidget {
  const RefreshSessionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    final enabled =
        !auth.isLoading && !auth.hasError && user != null && user.isActive;
    return KcButton(
      label: 'Periksa akses akun',
      variant: KcButtonVariant.outlined,
      leading: const Icon(Icons.manage_accounts_outlined),
      onPressed: !enabled
          ? null
          : () {
              final started = ref
                  .read(authStateProvider.notifier)
                  .refreshSession();
              if (!started && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tunggu proses akun yang sedang berjalan selesai.',
                    ),
                  ),
                );
              }
            },
    );
  }
}
