import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/owner/application/owner_menu_controller.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_archived_menu_detail_view.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_dialogs.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_photo_field.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

class OwnerMenuFormPage extends ConsumerStatefulWidget {
  const OwnerMenuFormPage({super.key, required this.accountId, this.existing});

  final String accountId;
  final OwnerMenuItem? existing;

  @override
  ConsumerState<OwnerMenuFormPage> createState() => _OwnerMenuFormPageState();
}

class _OwnerMenuFormPageState extends ConsumerState<OwnerMenuFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.price}',
  );
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late bool _isAvailable = widget.existing?.isAvailable ?? true;
  String? _categoryId;
  PickedOwnerPhoto? _pickedPhoto;
  var _removePhoto = false;
  var _dirty = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ref.read(ownerPhotoPickerProvider)();
      if (picked == null || !mounted) return;
      setState(() {
        _pickedPhoto = picked;
        _removePhoto = false;
        _dirty = true;
      });
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal memilih foto menu.'),
      );
    }
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate() || _categoryId == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerMenuControllerProvider)
          .saveMenu(
            accountId: widget.accountId,
            menuId: widget.existing?.id,
            name: _name.text.trim(),
            categoryId: _categoryId!,
            price: int.parse(_price.text.trim()),
            isAvailable: _isAvailable,
            description: _description.text.trim(),
            newPhoto: _pickedPhoto,
            removePhoto: _removePhoto,
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menyimpan menu.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive() async {
    final menu = widget.existing;
    if (menu == null || _busy) return;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: 'Arsipkan menu "${menu.name}"?',
      message:
          'Menu tidak akan tampil di katalog pelanggan. Item di keranjang pelanggan akan ditandai Tidak Tersedia. Riwayat pesanan lama tetap aman.',
      confirmLabel: 'Arsipkan Menu',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerMenuControllerProvider)
          .archiveMenu(accountId: widget.accountId, menuId: menu.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal mengarsipkan menu.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final menu = widget.existing;
    if (menu == null || _busy) return;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: 'Pulihkan menu "${menu.name}"?',
      message:
          'Menu akan kembali ke daftar aktif. Pastikan harga dan status Tersedia/Habis sudah sesuai sebelum menerima pesanan.',
      confirmLabel: 'Pulihkan Menu',
    );
    if (!mounted || !confirmed) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerMenuControllerProvider)
          .restoreMenu(accountId: widget.accountId, menuId: menu.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal memulihkan menu.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDiscard() async {
    if (_busy) return;
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await showOwnerConfirmDialog(
      context,
      title: 'Buang perubahan?',
      message: 'Perubahan menu yang belum disimpan akan hilang.',
      confirmLabel: 'Buang Perubahan',
    );
    if (mounted && discard) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    if (existing != null && existing.isArchived) {
      return OwnerArchivedMenuDetailView(
        accountId: widget.accountId,
        menu: existing,
        busy: _busy,
        onRestore: _restore,
      );
    }

    final categoriesAsync = ref.watch(
      ownerCategoriesProvider(widget.accountId),
    );
    final existingPhoto = existing != null && existing.hasPhoto && !_removePhoto
        ? ref
              .watch(
                ownerMenuPhotoProvider((
                  accountId: widget.accountId,
                  menuId: existing.id,
                )),
              )
              .asData
              ?.value
        : null;
    final previewBytes = _pickedPhoto?.bytes ?? existingPhoto;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _dirty) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _confirmDiscard),
          title: Text(existing == null ? 'Tambah Menu' : 'Ubah Menu'),
        ),
        body: SafeArea(
          child: categoriesAsync.when(
            loading: () => const OwnerLoadingView(message: 'Memuat kategori…'),
            error: (error, _) => OwnerErrorView(
              error: error,
              onRetry: () =>
                  ref.invalidate(ownerCategoriesProvider(widget.accountId)),
            ),
            data: (categories) {
              if (categories.isEmpty) {
                return const OwnerEmptyView(
                  icon: Icons.category_outlined,
                  title: 'Belum ada kategori menu',
                  description:
                      'Tambahkan kategori terlebih dahulu melalui halaman Kategori Menu.',
                );
              }
              _categoryId ??= categories.first.id;
              if (!categories.any((c) => c.id == _categoryId)) {
                _categoryId = categories.first.id;
              }
              return Form(
                key: _formKey,
                onChanged: () {
                  if (!_dirty) setState(() => _dirty = true);
                },
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(KcSpacing.md),
                  children: [
                    OwnerPhotoField(
                      title: 'Foto Menu (Opsional)',
                      bytes: previewBytes,
                      busy: _busy,
                      emptyIcon: Icons.fastfood_outlined,
                      onPick: _pickPhoto,
                      onRemove: previewBytes == null
                          ? null
                          : () => setState(() {
                              _pickedPhoto = null;
                              _removePhoto = true;
                              _dirty = true;
                            }),
                    ),
                    const SizedBox(height: KcSpacing.md),
                    TextFormField(
                      controller: _name,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Menu *',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Nama menu wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: KcSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
                      ),
                      items: [
                        for (final cat in categories)
                          DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _categoryId = val;
                                  _dirty = true;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: KcSpacing.md),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Harga Rupiah *',
                        prefixText: 'Rp ',
                      ),
                      validator: (v) {
                        final parsed = int.tryParse((v ?? '').trim());
                        if (parsed == null ||
                            parsed < 1 ||
                            parsed > 100000000) {
                          return 'Masukkan harga rupiah bulat minimal Rp1.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: KcSpacing.md),
                    TextFormField(
                      controller: _description,
                      maxLength: 2000,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi (Opsional)',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: KcSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_isAvailable ? 'Tersedia' : 'Habis'),
                      subtitle: const Text(
                        'Mengubah ketersediaan menu tidak menurunkan stok otomatis.',
                      ),
                      value: _isAvailable,
                      onChanged: _busy
                          ? null
                          : (val) => setState(() {
                              _isAvailable = val;
                              _dirty = true;
                            }),
                    ),
                    const SizedBox(height: KcSpacing.md),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: const Text('Simpan Menu'),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: KcSpacing.xs),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: _busy ? null : _archive,
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Arsipkan Menu'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
