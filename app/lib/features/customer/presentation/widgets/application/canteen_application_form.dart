import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/canteen_application_submit_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/application/application_discard_dialog.dart';

class CanteenApplicationForm extends ConsumerStatefulWidget {
  const CanteenApplicationForm({
    super.key,
    this.previous,
    required this.customerId,
    required this.onClose,
  });
  final String customerId;
  final VoidCallback onClose;
  final CanteenApplication? previous;
  @override
  ConsumerState<CanteenApplicationForm> createState() =>
      CanteenApplicationFormState();
}

class CanteenApplicationFormState
    extends ConsumerState<CanteenApplicationForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _phone;

  bool _saving = false;
  bool _confirming = false;
  bool _allowPop = false;
  bool _leaving = false;
  bool get _dirty =>
      _name.text != (widget.previous?.name ?? '') ||
      _description.text != (widget.previous?.description ?? '') ||
      _location.text != (widget.previous?.location ?? '') ||
      _phone.text != (widget.previous?.phone ?? '');

  /// Halaman diganti berdasarkan generasi sesi; dialog memeriksa sesi sendiri.
  Future<bool> confirmDiscard() async {
    if (!mounted ||
        _saving ||
        _confirming ||
        _leaving ||
        ref.read(canteenApplicationSubmitProvider).busy) {
      return false;
    }
    if (!_dirty) {
      return true;
    }
    setState(() => _confirming = true);
    try {
      final discard = await confirmApplicationDiscard(context, ref);
      return mounted && discard;
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> requestClose() async {
    if (!await confirmDiscard() || !mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
      _leaving = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        widget.onClose();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.previous?.name);
    _description = TextEditingController(text: widget.previous?.description);
    _location = TextEditingController(text: widget.previous?.location);
    _phone = TextEditingController(text: widget.previous?.phone);
  }

  @override
  void dispose() {
    for (final controller in [_name, _description, _location, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _requiredText(String? value, int max) {
    final text = value?.trim() ?? '';
    return text.isEmpty
        ? 'Wajib diisi.'
        : text.characters.length > max
        ? 'Maksimal $max karakter.'
        : null;
  }

  Future<void> _submit() async {
    if (_saving ||
        _confirming ||
        _leaving ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final draft = CanteenApplicationDraft(
      name: _name.text,
      description: _description.text,
      location: _location.text,
      phone: _phone.text,
    );
    setState(() => _saving = true);
    try {
      await ref
          .read(canteenApplicationSubmitProvider.notifier)
          .submit(draft, expectedPrevious: widget.previous);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(canteenApplicationSubmitProvider);
    final journal = ref.watch(
      canteenApplicationJournalProvider(widget.customerId),
    );
    final configured = ref
        .watch(canteenApplicationRepositoryProvider)
        .isSubmissionConfigured;
    final locked =
        journal.isLoading ||
        journal.hasError ||
        journal.asData == null ||
        journal.asData!.value != null;
    final enabled =
        !submit.busy && !_saving && !_confirming && !_leaving && !locked;
    return Form(
      key: _form,
      canPop:
          _allowPop || (!_dirty && !submit.busy && !_saving && !_confirming),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          requestClose();
        }
      },
      onChanged: () => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.previous == null ? 'Data pengajuan' : 'Perbaiki pengajuan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: KcSpacing.md),
          TextFormField(
            controller: _name,
            enabled: enabled,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Nama stan'),
            textInputAction: TextInputAction.next,
            validator: (value) => _requiredText(value, 120),
          ),
          const SizedBox(height: KcSpacing.sm),
          TextFormField(
            controller: _location,
            enabled: enabled,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Lokasi atau blok'),
            textInputAction: TextInputAction.next,
            validator: (value) => _requiredText(value, 120),
          ),
          const SizedBox(height: KcSpacing.sm),
          TextFormField(
            controller: _phone,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            maxLength: 24,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nomor telepon',
              hintText: 'Contoh: 081234567890',
            ),
            validator: (value) =>
                CanteenApplicationDraft.validPhone(value ?? '')
                ? null
                : 'Masukkan nomor telepon yang valid (8–15 digit).',
          ),
          const SizedBox(height: KcSpacing.sm),
          TextFormField(
            controller: _description,
            enabled: enabled,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Deskripsi usaha'),
            validator: (value) => _requiredText(value, 1000),
          ),
          const SizedBox(height: KcSpacing.md),
          const Text(
            'Pengajuan akan ditinjau admin. Pengiriman tidak otomatis mengubah akun menjadi pemilik stan.',
          ),
          const SizedBox(height: KcSpacing.md),
          if (!configured) ...[
            const Text('Layanan pengajuan belum tersedia saat ini.'),
            const SizedBox(height: KcSpacing.md),
          ],
          KcButton(
            label: 'Kirim pengajuan',
            isLoading: submit.busy,
            onPressed: enabled && configured && !submit.needsRefresh
                ? _submit
                : null,
          ),
        ],
      ),
    );
  }
}
