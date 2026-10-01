import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/owner/presentation/providers/owner_canteen_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_menu_filter_chip.dart';

class OwnerStallSettingsPage
    extends ConsumerStatefulWidget {
  const OwnerStallSettingsPage({
    super.key,
  });

  @override
  ConsumerState<OwnerStallSettingsPage>
      createState() =>
          _OwnerStallSettingsPageState();
}

class _OwnerStallSettingsPageState
    extends ConsumerState<OwnerStallSettingsPage> {
  late bool _isStallOpen;

  late String _preparationTime;

  final List<String> _preparationTimes = [
    '5–10 menit',
    '10–15 menit',
    '15–20 menit',
  ];

  @override
  void initState() {
    super.initState();

    final canteen =
        ref.read(ownerCanteenProvider);

    _isStallOpen =
        canteen.isStallOpen;

    _preparationTime =
        canteen.preparationTime;
  }

  void _saveChanges() {
    ref
        .read(ownerCanteenProvider.notifier)
        .updateStallStatus(
          _isStallOpen,
        );

    ref
        .read(ownerCanteenProvider.notifier)
        .updatePreparationTime(
          _preparationTime,
        );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Pengaturan stan berhasil disimpan',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan stan',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =======================================================
          // INFORMASI STAN
          // =======================================================

          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 32,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dapur Bu Rina',
                      style:
                          theme.textTheme.titleLarge,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Kantin Kampus · Blok A',
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Masakan rumahan, hangat setiap hari.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 28),

          // =======================================================
          // PENERIMAAN PESANAN
          // =======================================================

          Text(
            'Penerimaan pesanan',
            style: theme.textTheme.titleLarge,
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isStallOpen
                          ? 'Stan buka'
                          : 'Stan tutup',
                      style:
                          theme.textTheme.titleSmall,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _isStallOpen
                          ? 'Menerima pesanan baru'
                          : 'Pesanan baru dinonaktifkan',
                      style: theme
                          .textTheme.bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: _isStallOpen,
                onChanged: (value) {
                  setState(() {
                    _isStallOpen = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(
            color:
                theme.colorScheme.outlineVariant,
          ),

          const SizedBox(height: 18),

          // =======================================================
          // ESTIMASI
          // =======================================================

          Text(
            'Estimasi penyajian',
            style: theme.textTheme.titleLarge,
          ),

          const SizedBox(height: 6),

          Text(
            'Ditampilkan kepada mahasiswa.',
            style:
                theme.textTheme.bodySmall?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _preparationTimes.map(
                (time) {
                  return OwnerMenuFilterChip(
                    label: time,
                    selected:
                        _preparationTime ==
                            time,
                    onTap: () {
                      setState(() {
                        _preparationTime =
                            time;
                      });
                    },
                  );
                },
              ).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // =======================================================
          // JAM OPERASIONAL
          // =======================================================

          Text(
            'Jam operasional',
            style: theme.textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: theme
                  .colorScheme
                  .surfaceContainer,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Senin–Jumat',
                    style: theme
                        .textTheme.bodyMedium,
                  ),
                ),

                Text(
                  '08.00–16.00',
                  style:
                      theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Jam operasional sebagai informasi. '
            'Penerimaan pesanan mengikuti status buka atau tutup.',
            style:
                theme.textTheme.bodySmall?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),

      // ===========================================================
      // SIMPAN
      // ===========================================================

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color:
                    theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveChanges,
              child: const Text(
                'Simpan perubahan',
              ),
            ),
          ),
        ),
      ),
    );
  }
}