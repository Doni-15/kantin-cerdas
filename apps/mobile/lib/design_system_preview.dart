import 'package:flutter/material.dart';
import 'package:kantincerdas/app/theme/kantin_cerdas_theme.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_spacing.dart';
import 'package:kantincerdas/shared/widgets/kc_button.dart';
import 'package:kantincerdas/shared/widgets/kc_fields.dart';
import 'package:kantincerdas/shared/widgets/kc_filter_bar.dart';
import 'package:kantincerdas/shared/widgets/kc_overlays.dart';
import 'package:kantincerdas/shared/widgets/kc_state_view.dart';

/// Entry point pengembang: flutter run -t lib/design_system_preview.dart.
void main() => runApp(const DesignSystemPreview());

class DesignSystemPreview extends StatefulWidget {
  const DesignSystemPreview({super.key});

  @override
  State<DesignSystemPreview> createState() => _DesignSystemPreviewState();
}

class _DesignSystemPreviewState extends State<DesignSystemPreview> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: KantinCerdasTheme.light,
      darkTheme: KantinCerdasTheme.dark,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: _PreviewScreen(onToggleTheme: () => setState(() => _dark = !_dark)),
    );
  }
}

class _PreviewScreen extends StatefulWidget {
  const _PreviewScreen({required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<_PreviewScreen> {
  final _search = TextEditingController();
  final _input = TextEditingController();
  final _selected = <String>{'Semua'};

  @override
  void dispose() {
    _search.dispose();
    _input.dispose();
    super.dispose();
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KantinCerdasSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          for (final child in children) ...[
            const SizedBox(height: KantinCerdasSpacing.space3),
            child,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void notify() => showKcSnackBar(context: context, message: 'Aksi dicoba.');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komponen UI'),
        toolbarHeight:
            MediaQuery.orientationOf(context) == Orientation.landscape
            ? 48
            : kToolbarHeight,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Ganti tema terang atau gelap',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FocusTraversalGroup(
          child: ListView(
            padding: const EdgeInsets.all(KantinCerdasSpacing.space4),
            children: [
              _section('Tombol', [
                for (final variant in KcButtonVariant.values)
                  KcButton(
                    label: switch (variant) {
                      KcButtonVariant.primary => 'Tambah',
                      KcButtonVariant.secondary => 'Lihat detail',
                      KcButtonVariant.tertiary => 'Lihat semua',
                      KcButtonVariant.destructive => 'Kosongkan',
                    },
                    variant: variant,
                    onPressed: notify,
                  ),
                KcButton(label: 'Simpan', loading: true, onPressed: notify),
                const KcButton(label: 'Stan tutup', onPressed: null),
                const Text('Pemesanan tersedia setelah stan dibuka.'),
              ]),
              _section('Pencarian dan input', [
                KcSearchField(controller: _search, onChanged: (_) {}),
                KcInput(
                  label: 'Catatan',
                  controller: _input,
                  helperText: 'Opsional, maksimal 100 karakter.',
                  validator: (value) => (value?.length ?? 0) > 100
                      ? 'Ringkas catatan menjadi maksimal 100 karakter.'
                      : null,
                ),
                KcFilterBar(
                  options: const ['Semua', 'Nasi', 'Mi', 'Camilan', 'Minuman'],
                  selected: _selected,
                  onSelected: (option, selected) => setState(() {
                    selected ? _selected.add(option) : _selected.remove(option);
                  }),
                ),
              ]),
              _section('Dialog dan bottom sheet', [
                KcButton(
                  label: 'Coba dialog',
                  onPressed: () async {
                    final confirmed = await showKcConfirmation(
                      context: context,
                      title: 'Kosongkan pilihan?',
                      message: 'Ini pratinjau. Tidak ada pesanan yang dihapus.',
                      confirmLabel: 'Kosongkan',
                      destructive: true,
                    );
                    if (!context.mounted) return;
                    showKcSnackBar(
                      context: context,
                      message: confirmed ? 'Dikonfirmasi.' : 'Dibatalkan.',
                    );
                  },
                ),
                KcButton(
                  label: 'Coba bottom sheet',
                  onPressed: () => showKcBottomSheet<void>(
                    context: context,
                    title: 'Pilihan',
                    builder: (context) => KcInput(
                      label: 'Catatan pilihan',
                      controller: _input,
                      maxLines: 3,
                    ),
                  ),
                ),
              ]),
              _section('State konten', [
                for (final state in KcViewState.values)
                  KcStateView(
                    state: state,
                    title: switch (state) {
                      KcViewState.loading => 'Memuat menu',
                      KcViewState.empty => 'Belum ada menu yang cocok',
                      KcViewState.error => 'Menu belum dapat dimuat',
                      KcViewState.offline => 'Kamu sedang offline',
                      KcViewState.disabled => 'Stan sedang tutup',
                      KcViewState.success => 'Pilihan tersimpan',
                    },
                    message: switch (state) {
                      KcViewState.loading => 'Tunggu sebentar.',
                      KcViewState.empty => 'Coba ubah filter.',
                      KcViewState.error => 'Periksa koneksi lalu coba lagi.',
                      KcViewState.offline => 'Menampilkan data yang tersimpan.',
                      KcViewState.disabled =>
                        'Kamu masih bisa melihat menunya.',
                      KcViewState.success =>
                        'Kamu bisa melanjutkan memilih menu.',
                    },
                    actionLabel: state == KcViewState.error
                        ? 'Coba lagi'
                        : null,
                    onAction: state == KcViewState.error ? notify : null,
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
