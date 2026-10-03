import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu_item.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_stall_settings_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_canteen_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_menu_card.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_menu_filter_chip.dart';

class OwnerCanteenPage
    extends ConsumerStatefulWidget {
  const OwnerCanteenPage({
    super.key,
  });

  @override
  ConsumerState<OwnerCanteenPage>
      createState() =>
          _OwnerCanteenPageState();
}

class _OwnerCanteenPageState
    extends ConsumerState<OwnerCanteenPage> {
  final TextEditingController
      _searchController =
      TextEditingController();

  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Tersedia',
    'Habis',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OwnerMenuItem> _getFilteredMenus(
    List<OwnerMenuItem> menus,
  ) {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    return menus.where(
      (menu) {
        final matchesSearch =
            menu.name
                .toLowerCase()
                .contains(query);

        bool matchesFilter = true;

        if (_selectedFilter ==
            'Tersedia') {
          matchesFilter =
              menu.available;
        }

        if (_selectedFilter ==
            'Habis') {
          matchesFilter =
              !menu.available;
        }

        return matchesSearch &&
            matchesFilter;
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final canteen =
        ref.watch(ownerCanteenProvider);

    final menus =
        _getFilteredMenus(
      canteen.menus,
    );

    return SafeArea(
      child: Column(
        children: [
          // =======================================================
          // HEADER
          // =======================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              8,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Menu',
                    style: theme
                        .textTheme
                        .headlineLarge,
                  ),
                ),

                // Pengaturan stan
                IconButton(
                  tooltip:
                      'Pengaturan stan',
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const OwnerStallSettingsPage();
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_outlined,
                  ),
                ),
              ],
            ),
          ),

          // =======================================================
          // ISI
          // =======================================================

          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24,
              ),
              children: [
                // =================================================
                // SEARCH
                // =================================================

                TextField(
                  controller:
                      _searchController,

                  onChanged: (value) {
                    setState(() {});
                  },

                  decoration:
                      const InputDecoration(
                    hintText: 'Cari menu',
                    prefixIcon: Icon(
                      Icons.search,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // FILTER
                // =================================================

                SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,
                  child: Row(
                    children:
                        _filters.map(
                      (filter) {
                        return OwnerMenuFilterChip(
                          label: filter,

                          selected:
                              _selectedFilter ==
                                  filter,

                          onTap: () {
                            setState(() {
                              _selectedFilter =
                                  filter;
                            });
                          },
                        );
                      },
                    ).toList(),
                  ),
                ),

                const SizedBox(height: 4),

                // =================================================
                // DAFTAR MENU
                // =================================================

                if (menus.isEmpty)
                  _EmptyMenuResult(
                    query:
                        _searchController
                            .text,
                  )
                else
                  ...menus.map(
                    (menu) {
                      return OwnerMenuCard(
                        menu: menu,

                        onAvailabilityChanged:
                            (available) {
                          ref
                              .read(
                                ownerCanteenProvider
                                    .notifier,
                              )
                              .updateMenuAvailability(
                                menu.id,
                                available,
                              );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// HASIL PENCARIAN KOSONG
// =================================================================

class _EmptyMenuResult
    extends StatelessWidget {
  const _EmptyMenuResult({
    required this.query,
  });

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 46,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),

          const SizedBox(height: 14),

          Text(
            'Menu tidak ditemukan',
            style:
                theme.textTheme.titleMedium,
          ),

          const SizedBox(height: 6),

          Text(
            query.trim().isEmpty
                ? 'Tidak ada menu pada kategori ini.'
                : 'Tidak ada menu yang sesuai dengan "$query".',
            style:
                theme.textTheme.bodySmall
                    ?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}