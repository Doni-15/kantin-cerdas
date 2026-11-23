import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/application/owner_stall_controller.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_dialogs.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_photo_field.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_stall_publish_section.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_stall_schedule_section.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

class OwnerStallPage extends ConsumerStatefulWidget {
  const OwnerStallPage({
    super.key,
    required this.accountId,
    required this.onOpenMenusTab,
  });

  final String accountId;
  final VoidCallback onOpenMenusTab;

  @override
  ConsumerState<OwnerStallPage> createState() => _OwnerStallPageState();
}

class _OwnerStallPageState extends ConsumerState<OwnerStallPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _campus = TextEditingController();
  final _block = TextEditingController();
  final _description = TextEditingController();
  final _waitMinutes = TextEditingController();

  String? _syncedKey;
  List<OwnerScheduleDay> _schedules = const [];
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _campus.dispose();
    _block.dispose();
    _description.dispose();
    _waitMinutes.dispose();
    super.dispose();
  }

  void _syncFromBundle(OwnerStallBundle bundle) {
    final stall = bundle.stall;
    final key =
        '${stall?.id}:${stall?.name}:${stall?.campus}:${stall?.block}:'
        '${stall?.description}:${stall?.waitMinutes}:'
        '${bundle.schedules.map((s) => '${s.dayOfWeek}${s.isOpenDay}${s.openTime}${s.closeTime}').join(',')}';
    if (_syncedKey == key) return;
    _syncedKey = key;
    _name.text = stall?.name ?? '';
    _campus.text = stall?.campus ?? '';
    _block.text = stall?.block ?? '';
    _description.text = stall?.description ?? '';
    _waitMinutes.text = '${stall?.waitMinutes ?? 15}';
    _schedules = bundle.schedules.isNotEmpty
        ? List<OwnerScheduleDay>.from(bundle.schedules)
        : [
            for (var d = 1; d <= 7; d++)
              OwnerScheduleDay(dayOfWeek: d, isOpenDay: false),
          ];
  }

  Future<void> _saveProfile(bool isNewStall) async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerStallControllerProvider)
          .saveProfile(
            accountId: widget.accountId,
            isNewStall: isNewStall,
            name: _name.text.trim(),
            campus: _campus.text.trim(),
            block: _block.text.trim(),
            description: _description.text.trim(),
            waitMinutes: int.parse(_waitMinutes.text.trim()),
          );
      if (!mounted) return;
      showKcSnackBar(
        context,
        isNewStall
            ? 'Profil kantin berhasil dibuat.'
            : 'Profil kantin disimpan.',
      );
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menyimpan profil kantin.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ref.read(ownerPhotoPickerProvider)();
      if (picked == null || !mounted) return;
      await ref
          .read(ownerStallControllerProvider)
          .uploadStallPhoto(accountId: widget.accountId, photo: picked);
      if (!mounted) return;
      showKcSnackBar(context, 'Foto kantin diperbarui.');
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal mengunggah foto kantin.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_busy) return;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: 'Hapus foto kantin?',
      message:
          'Foto kantin bersifat opsional dan dapat ditambahkan kembali nanti.',
      confirmLabel: 'Hapus Foto',
    );
    if (!mounted || !confirmed) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerStallControllerProvider)
          .removeStallPhoto(widget.accountId);
      if (!mounted) return;
      showKcSnackBar(context, 'Foto kantin dihapus.');
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menghapus foto kantin.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveSchedule() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerStallControllerProvider)
          .saveSchedule(accountId: widget.accountId, schedules: _schedules);
      if (!mounted) return;
      showKcSnackBar(context, 'Jam operasional informatif disimpan.');
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menyimpan jam operasional.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publishStall() async {
    if (_busy) return;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: 'Terbitkan kantin sekarang?',
      message:
          'Kantin yang sudah diterbitkan tidak dapat dibatalkan publikasinya pada MVP. Kantin akan mulai dalam status Tutup sampai kamu membukanya secara manual.',
      confirmLabel: 'Terbitkan Kantin',
    );
    if (!mounted || !confirmed) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerStallControllerProvider)
          .publishStall(widget.accountId);
      if (!mounted) return;
      showKcSnackBar(context, 'Kantin diterbitkan dalam status Tutup.');
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal menerbitkan kantin.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleOpen(OwnerStall stall) async {
    if (_busy) return;
    final nextOpen = !stall.isOpen;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: nextOpen ? 'Buka kantin?' : 'Tutup kantin?',
      message: nextOpen
          ? 'Pelanggan dapat mengirim pesanan baru ke kantin ini.'
          : 'Pesanan baru dihentikan; pesanan yang sudah aktif tetap diproses.',
      confirmLabel: nextOpen ? 'Buka Kantin' : 'Tutup Kantin',
    );
    if (!mounted || !confirmed) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerStallControllerProvider)
          .setStallOpen(accountId: widget.accountId, isOpen: nextOpen);
      if (!mounted) return;
      showKcSnackBar(context, nextOpen ? 'Kantin dibuka.' : 'Kantin ditutup.');
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal mengubah status Buka/Tutup.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleScheduleOpenDay(int index, bool isOpenDay) {
    final day = _schedules[index];
    setState(() {
      _schedules[index] = OwnerScheduleDay(
        dayOfWeek: day.dayOfWeek,
        isOpenDay: isOpenDay,
        openTime: isOpenDay ? (day.openTime ?? '08:00') : null,
        closeTime: isOpenDay ? (day.closeTime ?? '17:00') : null,
      );
    });
  }

  Future<void> _pickScheduleTime(int index, {required bool isStart}) async {
    final day = _schedules[index];
    final current =
        _parseTime(isStart ? day.openTime : day.closeTime) ??
        TimeOfDay(hour: isStart ? 8 : 17, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _schedules[index] = OwnerScheduleDay(
        dayOfWeek: day.dayOfWeek,
        isOpenDay: true,
        openTime: isStart ? formatted : (day.openTime ?? '08:00'),
        closeTime: isStart ? (day.closeTime ?? '17:00') : formatted,
      );
    });
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(ownerStallProvider(widget.accountId));
    final stallForPhoto = bundleAsync.asData?.value.stall;
    final photoAsync = (stallForPhoto != null && stallForPhoto.hasPhoto)
        ? ref.watch(ownerStallPhotoProvider(widget.accountId))
        : const AsyncValue<Uint8List?>.data(null);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bundleAsync.asData?.value.stall == null
              ? 'Buat Kantin'
              : 'Informasi Kantin',
        ),
      ),
      body: SafeArea(
        child: bundleAsync.when(
          loading: () =>
              const OwnerLoadingView(message: 'Memuat profil kantin…'),
          error: (error, _) => OwnerErrorView(
            error: error,
            onRetry: () => ref.invalidate(ownerStallProvider(widget.accountId)),
          ),
          data: (bundle) {
            _syncFromBundle(bundle);
            final stall = bundle.stall;
            final isNew = stall == null;
            final eligibility = bundle.publishEligibility;
            final photoBytes = stall != null && stall.hasPhoto
                ? photoAsync.asData?.value
                : null;

            return RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(ownerStallProvider(widget.accountId).future),
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(KcSpacing.md),
                  children: [
                    if (stall != null) ...[
                      OwnerPhotoField(
                        title: 'Foto Kantin (Opsional)',
                        bytes: photoBytes,
                        busy: _busy,
                        onPick: _pickAndUploadPhoto,
                        onRemove: stall.hasPhoto ? _removePhoto : null,
                      ),
                      const SizedBox(height: KcSpacing.md),
                    ],
                    Text('Informasi Dasar', style: theme.textTheme.titleMedium),
                    const SizedBox(height: KcSpacing.sm),
                    TextFormField(
                      controller: _name,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kantin *',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Nama kantin wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: KcSpacing.md),
                    TextFormField(
                      controller: _campus,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Kampus/Universitas *',
                        hintText: 'Contoh: Universitas Sumatera Utara',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Kampus/universitas wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: KcSpacing.md),
                    TextFormField(
                      controller: _block,
                      maxLength: 60,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Fisik Detail *',
                        hintText: 'Contoh: Kantin Teknik Blok A-03',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Lokasi fisik detail wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: KcSpacing.md),
                    TextFormField(
                      controller: _description,
                      maxLength: 2000,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Kantin (Opsional)',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: KcSpacing.md),
                    TextFormField(
                      controller: _waitMinutes,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Estimasi Persiapan Umum',
                        suffixText: 'menit',
                        helperText:
                            'Berlaku informatif saat pesanan berikutnya diterima (0–240 menit).',
                      ),
                      validator: (v) {
                        final parsed = int.tryParse((v ?? '').trim());
                        if (parsed == null || parsed < 0 || parsed > 240) {
                          return 'Masukkan estimasi antara 0 hingga 240 menit.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: KcSpacing.md),
                    FilledButton(
                      onPressed: _busy ? null : () => _saveProfile(isNew),
                      child: Text(
                        isNew ? 'Simpan & Buat Kantin' : 'Simpan Perubahan',
                      ),
                    ),
                    if (stall != null) ...[
                      const SizedBox(height: KcSpacing.lg),
                      OwnerStallScheduleSection(
                        schedules: _schedules,
                        busy: _busy,
                        onToggleOpenDay: _toggleScheduleOpenDay,
                        onPickTime: _pickScheduleTime,
                        onSaveSchedule: _saveSchedule,
                      ),
                      const SizedBox(height: KcSpacing.lg),
                      OwnerStallPublishSection(
                        stall: stall,
                        eligibility: eligibility,
                        busy: _busy,
                        onPublishStall: _publishStall,
                        onOpenMenusTab: widget.onOpenMenusTab,
                        onToggleOpen: () => _toggleOpen(stall),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
