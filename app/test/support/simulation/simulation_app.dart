import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_application_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_user_detail_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_detail_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_order_detail_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';
import 'package:kantin_cerdas/kantin_cerdas_app.dart';
import 'package:kantin_cerdas/theme/kc_theme_exports.dart';

import 'simulation.dart';
import 'simulation_overrides.dart';

class SimulationApp extends StatefulWidget {
  const SimulationApp({super.key});
  @override
  State<SimulationApp> createState() => _SimulationAppState();
}

class _SimulationAppState extends State<SimulationApp> {
  late Future<(LocalStorage, SimulationStore)> _ready;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _ready = _open();
  }

  Future<(LocalStorage, SimulationStore)> _open() async {
    final storage = await LocalStorage.create(
      prefix: 'kantin_cerdas.simulation.v1.',
    );
    return (storage, await SimulationStore.open(storage));
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(LocalStorage, SimulationStore)>(
    future: _ready,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Data simulasi gagal dibaca. Data tidak dihapus otomatis.',
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _ready = _open();
                          }),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      }
      final (storage, store) = snapshot.data!;
      return ProviderScope(
        key: ValueKey(_generation),
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          ...simulationOverrides(store),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: KcTheme.light,
          darkTheme: KcTheme.dark,
          home: Column(
            children: [
              SimulationPanel(
                store: store,
                onReset: () async {
                  await store.reset();
                  if (mounted) {
                    setState(() {
                      _generation++;
                    });
                  }
                },
              ),
              const Expanded(child: KantinCerdasApp()),
            ],
          ),
        ),
      );
    },
  );
}

class SimulationPanel extends ConsumerStatefulWidget {
  const SimulationPanel({
    super.key,
    required this.store,
    required this.onReset,
  });
  final SimulationStore store;
  final Future<void> Function() onReset;
  @override
  ConsumerState<SimulationPanel> createState() => _SimulationPanelState();
}

class _SimulationPanelState extends ConsumerState<SimulationPanel> {
  bool _open = false, _confirm = false, _busy = false;
  String? _error;
  void _reload() {
    ref.invalidate(customerCatalogProvider);
    ref.invalidate(customerOrderFeedProvider);
    ref.invalidate(customerOrderDetailProvider);
    ref.invalidate(canteenApplicationProvider);
    ref.invalidate(foodPreferencesProvider);
    ref.invalidate(ownerStallProvider);
    ref.invalidate(ownerMenusProvider);
    ref.invalidate(ownerOrdersProvider);
    ref.invalidate(ownerOrderDetailProvider);
    ref.invalidate(adminSummaryProvider);
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminApplicationsProvider);
    ref.invalidate(adminApplicationDetailProvider);
    ref.invalidate(adminUserDetailProvider);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'MODE SIMULASI • data fiktif',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _open = !_open;
                }),
                child: Text(_open ? 'Tutup' : 'Kontrol'),
              ),
            ],
          ),
          if (_open)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .45,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Akun: pelanggan, pelanggan2, pemilik, pemilik2, pemilik3, admin\nPassword semua: Simulasi123!\nGunakan akun/data fiktif saja. Email reset dan AI tidak nyata.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final scenario in SimulationScenario.values)
                          ChoiceChip(
                            label: Text(switch (scenario) {
                              SimulationScenario.normal => 'Normal',
                              SimulationScenario.slow => 'Lambat',
                              SimulationScenario.empty => 'Daftar kosong',
                              SimulationScenario.readError => 'Gagal baca',
                              SimulationScenario.conflict => 'Konflik tulis',
                              SimulationScenario.unknown =>
                                'Respons tulis hilang',
                            }),
                            selected: widget.store.scenario == scenario,
                            onSelected: _busy
                                ? null
                                : (_) {
                                    setState(() {
                                      widget.store.scenario = scenario;
                                    });
                                    _reload();
                                  },
                          ),
                      ],
                    ),
                    TextButton(
                      onPressed: _reload,
                      child: const Text('Muat ulang data layar'),
                    ),
                    if (_confirm) ...[
                      const Text(
                        'Reset menghapus semua data, sesi, dan penanda simulasi lalu mengembalikan contoh awal. Data app normal tidak disentuh.',
                      ),
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _confirm = false;
                                  }),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    setState(() {
                                      _busy = true;
                                      _error = null;
                                    });
                                    try {
                                      await widget.onReset();
                                    } catch (_) {
                                      if (mounted) {
                                        setState(() {
                                          _busy = false;
                                          _error = 'Reset gagal. Coba lagi.';
                                        });
                                      }
                                    }
                                  },
                            child: Text(
                              _busy ? 'Mereset...' : 'Ya, reset simulasi',
                            ),
                          ),
                        ],
                      ),
                    ] else
                      TextButton(
                        onPressed: () => setState(() {
                          _confirm = true;
                        }),
                        child: const Text('Reset data simulasi'),
                      ),
                    if (_error != null) Text(_error!),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
