import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/customer/data/datasources/customer_dummy_data.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart_summary_bar.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/menu_item_card.dart';

class CustomerSearchPage
    extends StatefulWidget {
  const CustomerSearchPage({
    super.key,
  });

  @override
  State<CustomerSearchPage>
      createState() =>
          _CustomerSearchPageState();
}

class _CustomerSearchPageState
    extends State<CustomerSearchPage> {
  final TextEditingController
      _searchController =
      TextEditingController();

  int? maxPrice = 20000;
  int? maxWaitMinutes = 10;
  bool onlyAvailable = true;

  @override
  void initState() {
    super.initState();

    _searchController
        .addListener(
      _refreshSearch,
    );
  }

  void _refreshSearch() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController
        .removeListener(
      _refreshSearch,
    );

    _searchController.dispose();

    super.dispose();
  }

  int _getMaximumWaitTime(
    String waitTime,
  ) {
    final matches =
        RegExp(r'\d+')
            .allMatches(waitTime);

    if (matches.isEmpty) {
      return 0;
    }

    final numbers =
        matches.map(
      (match) {
        return int.parse(
          match.group(0)!,
        );
      },
    ).toList();

    return numbers.last;
  }

  List<MenuItem> get filteredMenus {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    return CustomerDummyData
        .semuaMenu
        .where(
      (menu) {
        final matchesSearch =
            menu.name
                    .toLowerCase()
                    .contains(query) ||
                menu.stallName
                    .toLowerCase()
                    .contains(query);

        final matchesPrice =
            maxPrice == null ||
                menu.price <=
                    maxPrice!;

        final waitMinutes =
            _getMaximumWaitTime(
          menu.waitTime,
        );

        final matchesWait =
            maxWaitMinutes ==
                    null ||
                waitMinutes <=
                    maxWaitMinutes!;

        final matchesAvailable =
            !onlyAvailable ||
                menu.available;

        return matchesSearch &&
            matchesPrice &&
            matchesWait &&
            matchesAvailable;
      },
    ).toList();
  }

  String get priceFilterText {
    if (maxPrice == null) {
      return 'Tanpa batas harga';
    }

    return 'Maks. ${formatRupiah(maxPrice!)}';
  }

  int get activeFilterCount {
    int count = 0;

    if (maxPrice != null) {
      count++;
    }

    if (maxWaitMinutes != null) {
      count++;
    }

    if (onlyAvailable) {
      count++;
    }

    return count;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final menus =
        filteredMenus;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme
                        .colorScheme
                        .outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                  ),

                  const SizedBox(
                    width: 4,
                  ),

                  Text(
                    'Cari menu',
                    style: theme
                        .textTheme
                        .headlineSmall,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                children: [
                  TextField(
                    controller:
                        _searchController,
                    autofocus: true,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Cari menu atau stan',
                      prefixIcon:
                          const Icon(
                        Icons.search,
                      ),
                      suffixIcon:
                          _searchController
                                  .text
                                  .isNotEmpty
                              ? IconButton(
                                  onPressed:
                                      () {
                                    _searchController
                                        .clear();
                                  },
                                  icon:
                                      const Icon(
                                    Icons.close,
                                  ),
                                )
                              : null,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  SingleChildScrollView(
                    scrollDirection:
                        Axis.horizontal,
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _showFilter();
                          },
                          child: Text(
                            priceFilterText,
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        OutlinedButton
                            .icon(
                          onPressed: () {
                            _showFilter();
                          },
                          icon: const Icon(
                            Icons
                                .filter_alt_outlined,
                          ),
                          label: Text(
                            activeFilterCount >
                                    0
                                ? 'Filter ($activeFilterCount)'
                                : 'Filter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Text(
                    '${menus.length} menu ditemukan',
                    style: theme
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (menus.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 40,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            'Menu tidak ditemukan',
                            style: theme
                                .textTheme
                                .titleMedium,
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Coba ubah kata pencarian atau filter.',
                            textAlign:
                                TextAlign
                                    .center,
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ...menus.map(
                    (menu) {
                      return MenuItemCard(
                        menu: menu,
                      );
                    },
                  ),
                ],
              ),
            ),

            const CartSummaryBar(),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilter() async {
    final result =
        await showModalBottomSheet<
            _MenuFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return _FilterMenuSheet(
          initialPrice:
              maxPrice,
          initialWaitMinutes:
              maxWaitMinutes,
          initialOnlyAvailable:
              onlyAvailable,
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      maxPrice =
          result.maxPrice;

      maxWaitMinutes =
          result.maxWaitMinutes;

      onlyAvailable =
          result.onlyAvailable;
    });
  }
}

class _MenuFilterResult {
  const _MenuFilterResult({
    required this.maxPrice,
    required this.maxWaitMinutes,
    required this.onlyAvailable,
  });

  final int? maxPrice;
  final int? maxWaitMinutes;
  final bool onlyAvailable;
}

class _FilterMenuSheet
    extends StatefulWidget {
  const _FilterMenuSheet({
    required this.initialPrice,
    required this.initialWaitMinutes,
    required this.initialOnlyAvailable,
  });

  final int? initialPrice;
  final int? initialWaitMinutes;
  final bool initialOnlyAvailable;

  @override
  State<_FilterMenuSheet>
      createState() =>
          _FilterMenuSheetState();
}

class _FilterMenuSheetState
    extends State<_FilterMenuSheet> {
  int? selectedPrice;
  int? selectedWaitMinutes;

  bool onlyAvailable =
      false;

  @override
  void initState() {
    super.initState();

    selectedPrice =
        widget.initialPrice;

    selectedWaitMinutes =
        widget.initialWaitMinutes;

    onlyAvailable =
        widget.initialOnlyAvailable;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        20,
      ),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration:
                    BoxDecoration(
                  color: theme
                      .colorScheme
                      .outlineVariant,
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              children: [
                Text(
                  'Filter menu',
                  style: theme
                      .textTheme
                      .headlineSmall,
                ),

                const Spacer(),

                IconButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'Batas harga',
              style: theme
                  .textTheme
                  .titleSmall,
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                _FilterChoice(
                  label:
                      'Rp15.000',
                  selected:
                      selectedPrice ==
                          15000,
                  onTap: () {
                    setState(() {
                      selectedPrice =
                          15000;
                    });
                  },
                ),

                const SizedBox(
                  width: 8,
                ),

                _FilterChoice(
                  label:
                      'Rp20.000',
                  selected:
                      selectedPrice ==
                          20000,
                  onTap: () {
                    setState(() {
                      selectedPrice =
                          20000;
                    });
                  },
                ),

                const SizedBox(
                  width: 8,
                ),

                _FilterChoice(
                  label:
                      'Tanpa batas',
                  selected:
                      selectedPrice ==
                          null,
                  onTap: () {
                    setState(() {
                      selectedPrice =
                          null;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              'Waktu tunggu',
              style: theme
                  .textTheme
                  .titleSmall,
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                _FilterChoice(
                  label:
                      '10 menit',
                  selected:
                      selectedWaitMinutes ==
                          10,
                  onTap: () {
                    setState(() {
                      selectedWaitMinutes =
                          10;
                    });
                  },
                ),

                const SizedBox(
                  width: 8,
                ),

                _FilterChoice(
                  label:
                      '20 menit',
                  selected:
                      selectedWaitMinutes ==
                          20,
                  onTap: () {
                    setState(() {
                      selectedWaitMinutes =
                          20;
                    });
                  },
                ),

                const SizedBox(
                  width: 8,
                ),

                _FilterChoice(
                  label:
                      'Tanpa batas',
                  selected:
                      selectedWaitMinutes ==
                          null,
                  onTap: () {
                    setState(() {
                      selectedWaitMinutes =
                          null;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            CheckboxListTile(
              value:
                  onlyAvailable,
              contentPadding:
                  EdgeInsets.zero,
              controlAffinity:
                  ListTileControlAffinity
                      .leading,
              title:
                  const Text(
                'Hanya menu tersedia',
              ),
              onChanged:
                  (value) {
                setState(() {
                  onlyAvailable =
                      value ??
                          false;
                });
              },
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width:
                  double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _MenuFilterResult(
                      maxPrice:
                          selectedPrice,
                      maxWaitMinutes:
                          selectedWaitMinutes,
                      onlyAvailable:
                          onlyAvailable,
                    ),
                  );
                },
                child: const Text(
                  'Tampilkan menu',
                ),
              ),
            ),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    selectedPrice =
                        null;

                    selectedWaitMinutes =
                        null;

                    onlyAvailable =
                        false;
                  });
                },
                child: const Text(
                  'Reset filter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChoice
    extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style:
            OutlinedButton.styleFrom(
          backgroundColor: selected
              ? theme
                  .colorScheme
                  .primaryContainer
              : theme
                  .colorScheme
                  .surfaceContainer,
          foregroundColor: selected
              ? theme
                  .colorScheme
                  .primary
              : theme
                  .colorScheme
                  .onSurface,
          side: BorderSide(
            color: selected
                ? theme
                    .colorScheme
                    .primary
                : Colors.transparent,
          ),
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 5,
            vertical: 12,
          ),
        ),
        child: Text(
          selected
              ? '✓ $label'
              : label,
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}