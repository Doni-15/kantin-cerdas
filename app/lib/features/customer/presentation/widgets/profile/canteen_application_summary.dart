import 'package:flutter/material.dart';

class CanteenApplicationSummary extends StatelessWidget {
  const CanteenApplicationSummary({
    super.key,
    required this.name,
    required this.description,
    required this.address,
  });

  final String name;
  final String description;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pengajuan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _SummaryItem(
              icon: Icons.storefront_outlined,
              label: 'Nama Kantin',
              value: name,
            ),
            const SizedBox(height: 16),
            _SummaryItem(
              icon: Icons.description_outlined,
              label: 'Deskripsi',
              value: description,
            ),
            const SizedBox(height: 16),
            _SummaryItem(
              icon: Icons.location_on_outlined,
              label: 'Alamat',
              value: address,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}