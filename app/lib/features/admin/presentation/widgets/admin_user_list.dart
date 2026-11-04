import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_user_card.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminUserList extends StatelessWidget {
  const AdminUserList({
    super.key,
    required this.page,
    required this.pageNumber,
    required this.hasSearch,
    required this.onPrevious,
    required this.onNext,
  });

  final AdminUserPage page;
  final int pageNumber;
  final bool hasSearch;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (page.users.isEmpty)
          KcStatusPanel(
            title: hasSearch
                ? 'Pengguna tidak ditemukan'
                : 'Tidak ada pengguna di halaman ini',
            message: hasSearch
                ? 'Coba nama atau email lain.'
                : 'Muat ulang untuk memperbarui daftar.',
            icon: Icons.people_outline,
          )
        else
          for (final user in page.users)
            Padding(
              padding: const EdgeInsets.only(bottom: KcSpacing.xs),
              child: AdminUserCard(key: ValueKey(user.id), user: user),
            ),
        const SizedBox(height: KcSpacing.sm),
        Wrap(
          spacing: KcSpacing.xs,
          runSpacing: KcSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: onPrevious,
              child: const Text('Sebelumnya'),
            ),
            Text('Halaman $pageNumber'),
            OutlinedButton(onPressed: onNext, child: const Text('Selanjutnya')),
          ],
        ),
      ],
    );
  }
}
