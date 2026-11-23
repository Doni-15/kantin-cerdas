import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/owner/application/owner_menu_controller.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_dialogs.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerCategorySheet extends ConsumerStatefulWidget {
  const OwnerCategorySheet({
    super.key,
    required this.accountId,
    required this.existing,
    this.editing,
  });

  final String accountId;
  final List<OwnerCategory> existing;
  final OwnerCategory? editing;

  @override
  ConsumerState<OwnerCategorySheet> createState() => _OwnerCategorySheetState();
}

class _OwnerCategorySheetState extends ConsumerState<OwnerCategorySheet> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _isDuplicate {
    final normalized = _name.text.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return widget.existing.any(
      (c) =>
          c.id != widget.editing?.id &&
          c.name.trim().toLowerCase() == normalized,
    );
  }

  Future<void> _save() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty || _isDuplicate || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(ownerMenuControllerProvider);
      if (widget.editing == null) {
        await controller.createCategory(
          accountId: widget.accountId,
          name: trimmed,
        );
      } else {
        await controller.renameCategory(
          accountId: widget.accountId,
          categoryId: widget.editing!.id,
          name: trimmed,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = presentAppError(error, fallback: 'Gagal menyimpan kategori.');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final editing = widget.editing;
    if (editing == null || !editing.canDelete || _busy) return;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: 'Hapus kategori "${editing.name}"?',
      message: 'Kategori ini sudah tidak memiliki menu aktif maupun arsip.',
      confirmLabel: 'Hapus Kategori',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(ownerMenuControllerProvider)
          .deleteCategory(accountId: widget.accountId, categoryId: editing.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = presentAppError(error, fallback: 'Kategori gagal dihapus.');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.editing;
    final duplicate = _isDuplicate;
    final trimmed = _name.text.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        KcSpacing.md,
        0,
        KcSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + KcSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing == null ? 'Tambah Kategori' : 'Ubah Kategori',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: KcSpacing.md),
            TextField(
              controller: _name,
              maxLength: 60,
              autofocus: true,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: 'Nama kategori *',
                counterText: '',
                errorText: duplicate
                    ? 'Nama kategori sudah digunakan di kantin ini.'
                    : _error,
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            FilledButton(
              onPressed: (_busy || trimmed.isEmpty || duplicate) ? null : _save,
              child: const Text('Simpan'),
            ),
            if (editing != null) ...[
              const SizedBox(height: KcSpacing.xs),
              if (editing.canDelete)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: _busy ? null : _delete,
                  child: const Text('Hapus Kategori'),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KcSpacing.xs),
                  child: Text(
                    'Kategori masih dipakai oleh ${editing.totalMenuCount} menu (${editing.activeMenuCount} aktif, ${editing.archivedMenuCount} arsip). Pindahkan seluruh menu terlebih dahulu sebelum menghapus.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
