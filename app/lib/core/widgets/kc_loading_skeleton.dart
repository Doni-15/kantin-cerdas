import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_skeleton.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

enum KcSkeletonLayout { list, catalog, detail, form, summary }

/// Bounded placeholders that follow the parent scroll view.
/// Put this in AsyncValue.when(loading: ...); keep empty/error branches separate.
class KcLoadingSkeleton extends StatelessWidget {
  const KcLoadingSkeleton({
    super.key,
    required this.label,
    this.layout = KcSkeletonLayout.list,
  });

  final String label;
  final KcSkeletonLayout layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: KcSpacing.sm),
        KcSkeleton(
          label: label,
          child: switch (layout) {
            KcSkeletonLayout.list => const _SkeletonList(),
            KcSkeletonLayout.catalog => const _SkeletonList(thumbnail: true),
            KcSkeletonLayout.detail => const _SkeletonDetail(),
            KcSkeletonLayout.form => const _SkeletonForm(),
            KcSkeletonLayout.summary => const _SkeletonSummary(),
          },
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(KcSpacing.md), child: child),
  );
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.fraction = 1, this.height = 14});

  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: fraction,
    child: KcSkeletonBlock(height: height),
  );
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({this.thumbnail = false});

  final bool thumbnail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < 3; index++) ...[
        if (index > 0) const SizedBox(height: KcSpacing.sm),
        _SkeletonCard(
          child: Row(
            children: [
              if (thumbnail) ...[
                const KcSkeletonBlock(width: 48, height: 56),
                const SizedBox(width: KcSpacing.sm),
              ],
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SkeletonLine(fraction: 0.7, height: 18),
                    SizedBox(height: KcSpacing.sm),
                    _SkeletonLine(),
                    SizedBox(height: KcSpacing.xs),
                    _SkeletonLine(fraction: 0.4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _SkeletonDetail extends StatelessWidget {
  const _SkeletonDetail();

  @override
  Widget build(BuildContext context) => const _SkeletonCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonLine(fraction: 0.7, height: 24),
        SizedBox(height: KcSpacing.sm),
        _SkeletonLine(fraction: 0.4),
        SizedBox(height: KcSpacing.lg),
        KcSkeletonBlock(height: 80),
        SizedBox(height: KcSpacing.lg),
        _SkeletonLine(),
        SizedBox(height: KcSpacing.sm),
        _SkeletonLine(fraction: 0.8),
        SizedBox(height: KcSpacing.sm),
        _SkeletonLine(fraction: 0.5),
      ],
    ),
  );
}

class _SkeletonForm extends StatelessWidget {
  const _SkeletonForm();

  @override
  Widget build(BuildContext context) => _SkeletonCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const SizedBox(height: KcSpacing.lg),
          const _SkeletonLine(fraction: 0.45),
          const SizedBox(height: KcSpacing.xs),
          const KcSkeletonBlock(height: 48),
        ],
      ],
    ),
  );
}

class _SkeletonSummary extends StatelessWidget {
  const _SkeletonSummary();

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 && scale <= 1.3
            ? 3
            : constraints.maxWidth >= 420 && scale <= 1.5
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - KcSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: KcSpacing.sm,
          runSpacing: KcSpacing.sm,
          children: [
            for (var index = 0; index < 5; index++)
              SizedBox(
                width: width,
                child: const _SkeletonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SkeletonLine(fraction: 0.25, height: 24),
                      SizedBox(height: KcSpacing.sm),
                      _SkeletonLine(fraction: 0.4, height: 28),
                      SizedBox(height: KcSpacing.xs),
                      _SkeletonLine(fraction: 0.8),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
