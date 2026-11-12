import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/stall/customer_stall_info.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/stall/customer_stall_menu_card.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerStallContent extends StatefulWidget {
  const CustomerStallContent({super.key, required this.stall});

  final Stall stall;

  @override
  State<CustomerStallContent> createState() => _CustomerStallContentState();
}

class _CustomerStallContentState extends State<CustomerStallContent> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void didUpdateWidget(covariant CustomerStallContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectedCategory = _selectedCategory;

    if (selectedCategory != null &&
        !widget.stall.menus.any((menu) => menu.category == selectedCategory)) {
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stall = widget.stall;
    final query = _searchController.text.trim().toLowerCase();

    final categories =
        stall.menus
            .map((menu) => menu.category)
            .where((category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final menus = stall.menus
        .where((menu) {
          final matchesQuery = menu.name.toLowerCase().contains(query);
          final matchesCategory =
              _selectedCategory == null || menu.category == _selectedCategory;

          return matchesQuery && matchesCategory;
        })
        .toList(growable: false);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: KcSpacing.pageHorizontal,
            vertical: KcSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomerStallInfo(stall: stall),
                const SizedBox(height: KcSpacing.lg),
                KcTextField(
                  label: 'Cari menu di stan ini',
                  hint: 'Masukkan nama menu',
                  controller: _searchController,
                  maxLength: CustomerInputLimits.maxSearchLength,
                  prefixIcon: Icons.search,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: KcSpacing.sm),
                  Wrap(
                    spacing: KcSpacing.xs,
                    runSpacing: KcSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = null);
                          }
                        },
                      ),
                      for (final category in categories)
                        ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = category);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: KcSpacing.pageHorizontal,
          ),
          sliver: SliverList.builder(
            itemCount: menus.isEmpty ? 2 : menus.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: KcSpacing.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      '${menus.length} menu ditemukan',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              if (menus.isEmpty) {
                return KcStatusPanel(
                  icon: Icons.restaurant_menu,
                  title: stall.menus.isEmpty
                      ? 'Belum ada menu'
                      : 'Menu tidak ditemukan',
                  message: stall.menus.isEmpty
                      ? 'Menu stan akan ditampilkan saat tersedia.'
                      : 'Coba ubah kata pencarian atau kategori.',
                );
              }

              final menu = menus[index - 1];

              return Padding(
                padding: const EdgeInsets.only(bottom: KcSpacing.sm),
                child: CustomerStallMenuCard(
                  menu: menu,
                  isStallOpen: stall.isOpen,
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KcSpacing.lg)),
      ],
    );
  }
}
