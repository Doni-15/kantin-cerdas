import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_image_picker_field.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_mutation_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_discard_dialog.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_session_dialog.dart';

class OwnerMenuEditor extends ConsumerStatefulWidget {
  const OwnerMenuEditor({super.key, required this.stallId, this.menu});
  final String stallId;
  final OwnerMenu? menu;
  @override
  ConsumerState<OwnerMenuEditor> createState() => _OwnerMenuEditorState();
}

class _OwnerMenuEditorState extends ConsumerState<OwnerMenuEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late OwnerMenuCategory _category;
  late bool _available;
  String? _imageUrl;
  late final OwnerDialogSession _session;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _confirming = false;
  bool _leaving = false;
  bool _allowPop = false;
  bool _needsReload = false;
  late final int _reviewRevision;

  bool get _dirty =>
      _name.text != (widget.menu?.name ?? '') ||
      _price.text != (widget.menu?.priceIdr.toString() ?? '') ||
      _description.text != (widget.menu?.description ?? '') ||
      _category != (widget.menu?.category ?? OwnerMenuCategory.other) ||
      _available != (widget.menu?.isAvailable ?? true) ||
      _imageUrl != widget.menu?.imageUrl;

  void _finish([bool? result]) {
    if (!mounted || _leaving || !_session.isCurrent(ref)) {
      return;
    }
    setState(() {
      _leaving = true;
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _session.isCurrent(ref) &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context, result);
      }
    });
  }

  Future<void> _requestClose() async {
    if (_saving ||
        _uploadingImage ||
        _confirming ||
        _leaving ||
        ref.read(ownerMutationProvider).busy) {
      return;
    }
    setState(() => _confirming = true);
    try {
      if (_dirty && !await confirmOwnerDiscard(context, ref)) {
        return;
      }
      if (mounted && _session.isCurrent(ref)) {
        _finish();
      }
    } finally {
      if (mounted && !_leaving) {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _session = OwnerDialogSession(ref);
    _reviewRevision = ref.read(ownerMutationProvider).reviewRevision;
    _name = TextEditingController(text: widget.menu?.name);
    _price = TextEditingController(text: widget.menu?.priceIdr.toString());
    _description = TextEditingController(text: widget.menu?.description);
    _category = widget.menu?.category ?? OwnerMenuCategory.other;
    _available = widget.menu?.isAvailable ?? true;
    _imageUrl = widget.menu?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        _uploadingImage ||
        _confirming ||
        _leaving ||
        _needsReload ||
        _reviewRevision != ref.read(ownerMutationProvider).reviewRevision ||
        !_session.isCurrent(ref) ||
        ref.read(ownerMutationProvider).blocked ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final input = OwnerMenuInput(
      id: widget.menu?.id,
      stallId: widget.stallId,
      name: _name.text,
      description: _description.text,
      category: _category,
      priceIdr: int.parse(_price.text),
      isAvailable: _available,
      expectedVersion: widget.menu?.version,
      imageUrl: _imageUrl,
    );
    setState(() => _saving = true);
    try {
      final ok = await ref
          .read(ownerMutationControllerProvider.notifier)
          .saveMenu(input, reviewRevision: _reviewRevision);
      if (!mounted || !_session.isCurrent(ref)) {
        return;
      }
      if (ok) {
        _finish(true);
      } else {
        final error = ref.read(ownerMutationProvider).error;
        if (input.id != null && error is OwnerConflictFailure) {
          setState(() => _needsReload = true);
        }
      }
    } finally {
      if (mounted && !_leaving) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(ownerMutationProvider);
    final ownerId = ref.watch(authStateProvider).activeOwnerId ?? '';
    final working =
        _saving || _uploadingImage || _confirming || _leaving || mutation.busy;
    final reviewChanged = mutation.reviewRevision != _reviewRevision;
    final enabled = !mutation.blocked && !working && !reviewChanged;
    return PopScope<bool>(
      canPop: _allowPop || (!_dirty && !working),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _requestClose();
        }
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KcSpacing.lg),
            child: Form(
              key: _form,
              onChanged: () => setState(() {}),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.menu == null ? 'Tambah menu' : 'Edit menu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: KcSpacing.md),
                  KcImagePickerField(
                    label: 'Foto menu (opsional)',
                    actorId: ownerId,
                    category: MediaUploadCategory.menuPhoto,
                    imageUrl: _imageUrl,
                    enabled: enabled,
                    fallbackIcon: Icons.restaurant_outlined,
                    onBusyChanged: (busy) =>
                        setState(() => _uploadingImage = busy),
                    onChanged: (newUrl) => setState(() => _imageUrl = newUrl),
                  ),
                  const SizedBox(height: KcSpacing.md),
                  TextFormField(
                    controller: _name,
                    enabled: enabled,
                    maxLength: 120,
                    decoration: const InputDecoration(labelText: 'Nama menu'),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Nama wajib diisi.'
                        : v!.trim().characters.length > 120
                        ? 'Maksimal 120 karakter.'
                        : null,
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  TextFormField(
                    controller: _price,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: 'Harga rupiah',
                      prefixText: 'Rp ',
                    ),
                    validator: (v) {
                      final amount = int.tryParse(v ?? '');
                      return amount == null || amount < 1 || amount > 10000000
                          ? 'Harga harus Rp1–Rp10.000.000.'
                          : null;
                    },
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  DropdownButtonFormField<OwnerMenuCategory>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      for (final category in OwnerMenuCategory.values)
                        DropdownMenuItem(
                          value: category,
                          child: Text(ownerCategoryLabel(category)),
                        ),
                    ],
                    onChanged: enabled
                        ? (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  TextFormField(
                    controller: _description,
                    enabled: enabled,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    validator: (v) => (v?.trim().characters.length ?? 0) > 1000
                        ? 'Maksimal 1000 karakter.'
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Menu tersedia'),
                    subtitle: const Text('Matikan jika menu sedang habis.'),
                    value: _available,
                    onChanged: enabled
                        ? (value) => setState(() => _available = value)
                        : null,
                  ),
                  const OwnerMutationNotice(operationPrefix: 'menu:'),
                  const SizedBox(height: KcSpacing.md),
                  if (reviewChanged)
                    const Text(
                      'Hasil perubahan sudah diperiksa. Tutup form dan tinjau daftar terbaru sebelum membuat perubahan baru.',
                    ),
                  if (_needsReload)
                    const Text(
                      'Menu sudah berubah. Tutup form dan buka kembali dari daftar terbaru sebelum menyimpan.',
                    ),
                  KcButton(
                    label: 'Simpan menu',
                    isLoading: _saving || mutation.busy,
                    onPressed: enabled && !_needsReload ? _save : null,
                  ),
                  TextButton(
                    onPressed: working ? null : _requestClose,
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
