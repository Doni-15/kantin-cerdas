import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';

/// One pulse controller per loading section, not per placeholder.
/// Use only while reading data; this widget never controls request timing.
class KcSkeleton extends StatefulWidget {
  const KcSkeleton({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<KcSkeleton> createState() => _KcSkeletonState();
}

class _KcSkeletonState extends State<KcSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.55,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceAnimation =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceAnimation || !TickerMode.valuesOf(context).enabled) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: FadeTransition(opacity: _pulse, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Decorative shape with theme-aware color; never represents actual data.
class KcSkeletonBlock extends StatelessWidget {
  const KcSkeletonBlock({super.key, this.width, this.height = 14});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(KcRadius.small),
        ),
      ),
    );
  }
}
