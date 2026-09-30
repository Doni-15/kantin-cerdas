import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/customer/data/datasources/customer_dummy_data.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_search_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_stall_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart_summary_bar.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/category_filter_chip.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/menu_item_card.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/stall_card.dart';

class CustomerHomePage
    extends StatefulWidget {
  const CustomerHomePage({
    super.key,
  });

  @override
  State<CustomerHomePage> createState() =>
      _CustomerHomePageState();
}

class _CustomerHomePageState
    extends State<CustomerHomePage> {
  String selectedCategory =
      'Semua';

  final List<String> categories = [
    'Semua',
    'Nasi',
    'Mi',
    'Minuman',
    'Camilan',
  ];

  List<MenuItem> get filteredMenus {
    if (selectedCategory ==
        'Semua') {
      return CustomerDummyData
          .homeMenus;
    }

    return CustomerDummyData
        .homeMenus
        .where(
      (menu) {
        return menu.category ==
            selectedCategory;
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

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24,
              ),
              children: [
                // HEADER
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons
                                    .location_on_outlined,
                                size: 16,
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),

                              const SizedBox(
                                width: 6,
                              ),

                              Text(
                                'Kantin Kampus',
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

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            'Selamat siang',
                            style: theme
                                .textTheme
                                .headlineMedium,
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 48,
                      height: 48,
                      alignment:
                          Alignment.center,
                      decoration:
                          BoxDecoration(
                        color: theme
                            .colorScheme
                            .primaryContainer,
                        shape:
                            BoxShape.circle,
                      ),
                      child: Text(
                        'D',
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // SEARCH
                TextField(
                  readOnly: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) {
                          return const CustomerSearchPage();
                        },
                      ),
                    );
                  },
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Cari menu atau stan',
                    prefixIcon:
                        Icon(
                      Icons.search,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
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
                  height: 26,
                ),

                // MENU CEPAT
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Text(
                      'Menu cepat siap',
                      style: theme
                          .textTheme
                          .titleLarge,
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder:
                                (context) {
                              return const CustomerSearchPage();
                            },
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat semua',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 6,
                ),

                if (menus.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 30,
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
                    );
                  },
                ),

                const SizedBox(
                  height: 24,
                ),

                // STAN
                Text(
                  'Stan yang buka',
                  style: theme
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(
                  height: 8,
                ),

                ...CustomerDummyData
                    .stalls
                    .where(
                      (stall) =>
                          stall.isOpen,
                    )
                    .map(
                  (stall) {
                    return StallCard(
                      stall: stall,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder:
                                (context) {
                              return CustomerStallDetailPage(
                                stall:
                                    stall,
                              );
                            },
                          ),
                        );
                      },
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