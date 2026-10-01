import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart_summary_bar.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/category_filter_chip.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/menu_item_card.dart';

class CustomerStallDetailPage
    extends StatefulWidget {
  const CustomerStallDetailPage({
    super.key,
    required this.stall,
  });

  final Stall stall;

  @override
  State<CustomerStallDetailPage>
      createState() =>
          _CustomerStallDetailPageState();
}

class _CustomerStallDetailPageState
    extends State<CustomerStallDetailPage> {
  final TextEditingController
      _searchController =
      TextEditingController();

  String selectedCategory =
      'Semua';

  final List<String> categories = [
    'Semua',
    'Makanan',
    'Minuman',
  ];

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

  List<MenuItem> get filteredMenus {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    return widget.stall.menus.where(
      (menu) {
        final matchesSearch =
            menu.name
                .toLowerCase()
                .contains(query);

        final matchesCategory =
            selectedCategory ==
                    'Semua' ||
                (selectedCategory ==
                        'Makanan' &&
                    menu.category !=
                        'Minuman') ||
                (selectedCategory ==
                        'Minuman' &&
                    menu.category ==
                        'Minuman');

        return matchesSearch &&
            matchesCategory;
      },
    ).toList();
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
      appBar: AppBar(
        title: const Text(
          'Detail stan',
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              children: [
                // FOTO STAN
                Container(
                  height: 140,
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons
                          .storefront_outlined,
                      size: 52,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Text(
                  widget.stall.name,
                  style: theme
                      .textTheme
                      .headlineMedium,
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: widget
                                .stall
                                .isOpen
                            ? theme
                                .colorScheme
                                .tertiaryContainer
                            : theme
                                .colorScheme
                                .errorContainer,
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        widget.stall
                                .isOpen
                            ? 'Buka'
                            : 'Tutup',
                        style: theme
                            .textTheme
                            .bodySmall,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        '${widget.stall.block}'
                        ' · ${widget.stall.waitTime}',
                        style: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 16,
                ),

                Text(
                  widget.stall
                      .description,
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
                  height: 20,
                ),

                // SEARCH
                TextField(
                  controller:
                      _searchController,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Cari menu di stan',
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

                // CATEGORY
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection:
                        Axis.horizontal,
                    children:
                        categories.map(
                      (category) {
                        return CategoryFilterChip(
                          label:
                              category,
                          selected:
                              selectedCategory ==
                                  category,
                          onTap: () {
                            setState(() {
                              selectedCategory =
                                  category;
                            });
                          },
                        );
                      },
                    ).toList(),
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
                      vertical: 32,
                    ),
                    child: Center(
                      child: Text(
                        'Menu tidak ditemukan',
                        style: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                ...menus.map(
                  (menu) {
                    return MenuItemCard(
                      menu: menu,
                      showStallName:
                          false,
                    );
                  },
                ),
              ],
            ),
          ),

          const CartSummaryBar(),
        ],
      ),
    );
  }
}