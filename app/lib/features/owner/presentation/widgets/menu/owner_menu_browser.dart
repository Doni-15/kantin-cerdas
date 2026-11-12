import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_load_error.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_mutation_notice.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/menu/owner_menu_card.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/menu/owner_menu_editor.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_session_dialog.dart';

class OwnerMenuBrowser extends ConsumerStatefulWidget {
  const OwnerMenuBrowser({super.key, required this.stallId});
  final String stallId;
  @override
  ConsumerState<OwnerMenuBrowser> createState() => _OwnerMenuBrowserState();
}

class _OwnerMenuBrowserState extends ConsumerState<OwnerMenuBrowser> {
  final _search = TextEditingController();
  final _form = GlobalKey<FormState>();
  final List<String?> _cursors = [null];
  String _query = '';
  bool? _available;
  bool _dialogOpen = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _applySearch() {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _query = _search.text.trim();
      _cursors
        ..clear()
        ..add(null);
    });
  }

  Future<void> _edit([OwnerMenu? menu]) async {
    if (_dialogOpen || ref.read(ownerMutationProvider).blocked) {
      return;
    }
    final session = OwnerDialogSession(ref);
    setState(() => _dialogOpen = true);
    try {
      final saved = await showOwnerDialog<bool>(
        context: context,
        ref: ref,
        builder: (_) => OwnerMenuEditor(stallId: widget.stallId, menu: menu),
      );
      if (!mounted || !session.isCurrent(ref)) {
        return;
      }
      if (saved == true) {
        setState(
          () => _cursors
            ..clear()
            ..add(null),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu tersimpan.')));
      }
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
      }
    }
  }

  Future<void> _delete(OwnerMenu menu) async {
    if (_dialogOpen || ref.read(ownerMutationProvider).blocked) {
      return;
    }
    final session = OwnerDialogSession(ref);
    setState(() => _dialogOpen = true);
    try {
      final confirmed = await showOwnerDialog<bool>(
        context: context,
        ref: ref,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: const Text('Hapus menu?'),
          content: Text(
            'Menu "${menu.name}" akan dihapus dari daftar jual. Pesanan yang sudah dibuat tetap memiliki rinciannya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus menu'),
            ),
          ],
        ),
      );
      if (!mounted || !session.isCurrent(ref) || confirmed != true) {
        return;
      }
      final ok = await ref
          .read(ownerMutationControllerProvider.notifier)
          .deleteMenu(menu);
      if (!mounted || !session.isCurrent(ref)) {
        return;
      }
      if (ok) {
        setState(
          () => _cursors
            ..clear()
            ..add(null),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu dihapus.')));
      }
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ownerMenusProvider((
      search: _query,
      available: _available,
      cursor: _cursors.last,
    ));
    final state = ref.watch(provider);
    final mutationBlocked = ref.watch(
      ownerMutationProvider.select((s) => s.blocked),
    );
    final blocked = mutationBlocked || _dialogOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: KcSpacing.xs,
          runSpacing: KcSpacing.xs,
          children: [
            FilledButton.icon(
              onPressed: blocked ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah menu'),
            ),
            TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref.invalidate(provider),
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
        const SizedBox(height: KcSpacing.md),
        Form(
          key: _form,
          child: TextFormField(
            controller: _search,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: 'Cari menu',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Cari menu',
                icon: const Icon(Icons.arrow_forward),
                onPressed: _applySearch,
              ),
            ),
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _applySearch(),
            validator: (v) => (v?.trim().characters.length ?? 0) > 120
                ? 'Maksimal 120 karakter.'
                : null,
          ),
        ),
        Wrap(
          spacing: KcSpacing.xs,
          runSpacing: KcSpacing.xs,
          children: [
            for (final filter in [
              (label: 'Semua', value: null),
              (label: 'Tersedia', value: true),
              (label: 'Habis', value: false),
            ])
              ChoiceChip(
                label: Text(filter.label),
                selected: _available == filter.value,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _available = filter.value;
                      _cursors
                        ..clear()
                        ..add(null);
                    });
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: KcSpacing.md),
        const OwnerMutationNotice(operationPrefix: 'menu:'),
        state.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const KcLoadingSkeleton(
            label: 'Memuat menu',
            layout: KcSkeletonLayout.catalog,
          ),
          error: (error, _) => OwnerLoadError(
            error: error,
            onRetry: () => ref.invalidate(provider),
          ),
          data: (page) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (page.items.isEmpty)
                const KcStatusPanel(
                  title: 'Tidak ada menu yang sesuai',
                  message:
                      'Ubah pencarian atau filter. Gunakan Tambah menu untuk membuat menu baru.',
                  icon: Icons.restaurant_menu,
                ),
              for (final menu in page.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: KcSpacing.sm),
                  child: OwnerMenuCard(
                    key: ValueKey(menu.id),
                    menu: menu,
                    onEdit: blocked ? null : () => _edit(menu),
                    onDelete: blocked ? null : () => _delete(menu),
                  ),
                ),
              Wrap(
                spacing: KcSpacing.xs,
                runSpacing: KcSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _cursors.length == 1
                        ? null
                        : () => setState(() => _cursors.removeLast()),
                    child: const Text('Sebelumnya'),
                  ),
                  Text('Halaman ${_cursors.length}'),
                  OutlinedButton(
                    onPressed:
                        page.nextCursor == null ||
                            _cursors.contains(page.nextCursor)
                        ? null
                        : () => setState(() => _cursors.add(page.nextCursor)),
                    child: const Text('Selanjutnya'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (state.hasError && _cursors.length > 1)
          TextButton(
            onPressed: () => setState(() => _cursors.removeLast()),
            child: const Text('Halaman sebelumnya'),
          ),
      ],
    );
  }
}
