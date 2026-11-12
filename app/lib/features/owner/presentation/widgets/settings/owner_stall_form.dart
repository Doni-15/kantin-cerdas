import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_image_picker_field.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_mutation_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_discard_dialog.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_session_dialog.dart';

class OwnerStallForm extends ConsumerStatefulWidget {
  const OwnerStallForm({super.key, required this.stall, required this.onClose});
  final OwnerStall stall;
  final VoidCallback onClose;
  @override
  ConsumerState<OwnerStallForm> createState() => OwnerStallFormState();
}

class OwnerStallFormState extends ConsumerState<OwnerStallForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _block;
  late final TextEditingController _description;
  late final TextEditingController _minutes;
  late bool _open;
  String? _imageUrl;
  late OwnerStall _baseline;
  late final OwnerDialogSession _session;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _confirming = false;
  bool _leaving = false;
  bool _allowPop = false;
  bool _needsReload = false;
  bool _acceptNextSnapshot = false;

  bool get _dirty =>
      _name.text != _baseline.name ||
      _block.text != _baseline.block ||
      _description.text != _baseline.description ||
      _minutes.text != _baseline.prepTimeMin.toString() ||
      _open != _baseline.isOpen ||
      _imageUrl != _baseline.imageUrl;
  bool get _stale => widget.stall.version != _baseline.version;

  void _adopt(OwnerStall stall) {
    _baseline = stall;
    _name.text = stall.name;
    _block.text = stall.block;
    _description.text = stall.description;
    _minutes.text = stall.prepTimeMin.toString();
    _open = stall.isOpen;
    _imageUrl = stall.imageUrl;
  }

  @override
  void didUpdateWidget(covariant OwnerStallForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stall.id != _baseline.id ||
        (_stale && (!_dirty || _acceptNextSnapshot))) {
      _adopt(widget.stall);
      _acceptNextSnapshot = false;
    }
  }

  Future<void> _useLatest() async {
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
        if (_stale) {
          setState(() {
            _adopt(widget.stall);
            _needsReload = false;
          });
        } else {
          ref.invalidate(ownerStallProvider);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  /// Dipakai tombol toolbar dan callback back sistem dengan aturan yang sama.
  Future<void> requestClose() async {
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
      if (!mounted || !_session.isCurrent(ref)) {
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
          widget.onClose();
        }
      });
    } finally {
      if (mounted && !_leaving) {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _baseline = widget.stall;
    _session = OwnerDialogSession(ref);
    _name = TextEditingController(text: widget.stall.name);
    _block = TextEditingController(text: widget.stall.block);
    _description = TextEditingController(text: widget.stall.description);
    _minutes = TextEditingController(text: widget.stall.prepTimeMin.toString());
    _open = widget.stall.isOpen;
    _imageUrl = widget.stall.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _block.dispose();
    _description.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        _uploadingImage ||
        _confirming ||
        _leaving ||
        _stale ||
        _needsReload ||
        !_dirty ||
        !_session.isCurrent(ref) ||
        ref.read(ownerMutationProvider).blocked ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final input = OwnerStallInput(
      id: _baseline.id,
      name: _name.text,
      block: _block.text,
      description: _description.text,
      isOpen: _open,
      prepTimeMin: int.parse(_minutes.text),
      expectedVersion: _baseline.version,
      imageUrl: _imageUrl,
    );
    setState(() => _saving = true);
    try {
      if (_baseline.isOpen && !input.isOpen) {
        final confirmed = await showOwnerDialog<bool>(
          context: context,
          ref: ref,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('Tutup stan sementara?'),
            content: const Text(
              'Pesanan baru akan dihentikan setelah perubahan tersimpan. Pesanan yang sudah masuk tetap perlu ditangani.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Tutup stan'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true || !_session.isCurrent(ref)) {
          return;
        }
      }
      if (!mounted || !_session.isCurrent(ref)) {
        return;
      }
      final ok = await ref
          .read(ownerMutationControllerProvider.notifier)
          .saveStall(input);
      if (!mounted || !_session.isCurrent(ref)) {
        return;
      }
      if (ok) {
        _acceptNextSnapshot = true;
        if (_stale) {
          setState(() => _adopt(widget.stall));
          _acceptNextSnapshot = false;
        }
      } else {
        final error = ref.read(ownerMutationProvider).error;
        if (error is OwnerConflictFailure) {
          setState(() => _needsReload = true);
        }
      }
      // Provider memuat ulang snapshot hanya setelah hasil terverifikasi.
      // Gagal: pertahankan input beserta expectedVersion awal.
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _required(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty
        ? 'Wajib diisi.'
        : text.characters.length > 120
        ? 'Maksimal 120 karakter.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(ownerMutationProvider);
    final working =
        _saving || _uploadingImage || _confirming || _leaving || mutation.busy;
    final enabled = !mutation.blocked && !working;
    return Form(
      key: _form,
      onChanged: () => setState(() {}),
      canPop: _allowPop || (!_dirty && !working),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          requestClose();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KcImagePickerField(
            label: 'Foto stan (opsional)',
            actorId: _baseline.ownerId,
            category: MediaUploadCategory.stallPhoto,
            imageUrl: _imageUrl,
            enabled: enabled,
            fallbackIcon: Icons.storefront_outlined,
            onBusyChanged: (busy) => setState(() => _uploadingImage = busy),
            onChanged: (newUrl) => setState(() => _imageUrl = newUrl),
          ),
          const SizedBox(height: KcSpacing.md),
          TextFormField(
            controller: _name,
            enabled: enabled,
            maxLength: 120,
            validator: _required,
            decoration: const InputDecoration(labelText: 'Nama stan'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: KcSpacing.sm),
          TextFormField(
            controller: _block,
            enabled: enabled,
            maxLength: 120,
            validator: _required,
            decoration: const InputDecoration(labelText: 'Lokasi atau blok'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: KcSpacing.sm),
          TextFormField(
            controller: _description,
            enabled: enabled,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Deskripsi stan'),
            validator: (v) => (v?.trim().characters.length ?? 0) > 1000
                ? 'Maksimal 1000 karakter.'
                : null,
          ),
          const SizedBox(height: KcSpacing.sm),
          TextFormField(
            controller: _minutes,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            decoration: const InputDecoration(
              labelText: 'Estimasi persiapan',
              suffixText: 'menit',
            ),
            validator: (v) {
              final minutes = int.tryParse(v ?? '');
              return minutes == null || minutes < 1 || minutes > 180
                  ? 'Isi 1–180 menit.'
                  : null;
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Stan buka'),
            subtitle: const Text('Perubahan berlaku setelah disimpan.'),
            value: _open,
            onChanged: enabled
                ? (value) => setState(() => _open = value)
                : null,
          ),
          if (!mutation.succeeded || !_dirty)
            const OwnerMutationNotice(operationPrefix: 'stall:'),
          const SizedBox(height: KcSpacing.md),
          if (_stale || _needsReload) ...[
            const Text(
              'Data stan sudah diperbarui. Isianmu tetap ada. Muat data terbaru sebelum menyimpan.',
            ),
            TextButton(
              onPressed: working ? null : _useLatest,
              child: const Text('Muat data terbaru'),
            ),
          ],
          KcButton(
            label: 'Simpan pengaturan',
            isLoading: _saving || mutation.busy,
            onPressed: enabled && _dirty && !_stale && !_needsReload
                ? _save
                : null,
          ),
        ],
      ),
    );
  }
}
