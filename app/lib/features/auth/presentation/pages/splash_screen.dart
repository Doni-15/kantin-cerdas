import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/splash_emblem_rings.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/splash_status_card.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_brand.dart';

export 'package:kantin_cerdas/features/auth/presentation/widgets/splash_status_card.dart'
    show SplashPhase;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.phase});

  final SplashPhase phase;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 620);
  static const _logoViewportFraction = 0.36;
  static const _minLogoSize = 72.0;
  static const _maxLogoSize = 152.0;

  late final _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final _logoScale = _intro
      .drive(
        CurveTween(curve: const Interval(0, 0.77, curve: Curves.easeOutCubic)),
      )
      .drive(Tween(begin: 0.76, end: 1.0));
  late final _titleRise = _intro
      .drive(
        CurveTween(
          curve: const Interval(0.12, 0.86, curve: Curves.easeOutCubic),
        ),
      )
      .drive(Tween(begin: const Offset(0, 0.34), end: Offset.zero));
  late final _titleOpacity = _intro
      .drive(CurveTween(curve: const Interval(0.12, 0.78)))
      .drive(Tween(begin: 0.32, end: 1.0));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: colors.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0, 0.53, 1],
              colors: [
                Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.12),
                  colors.surface,
                ),
                colors.surface,
                Color.alphaBlend(
                  colors.secondary.withValues(alpha: 0.10),
                  colors.surface,
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final logoSize =
                    (constraints.biggest.shortestSide * _logoViewportFraction)
                        .clamp(_minLogoSize, _maxLogoSize);

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: KcSpacing.md,
                      horizontal: KcSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: SplashEmblemRingsPainter(
                              _intro,
                              colors.primary,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: KcAppLogo(
                                  key: const ValueKey('launch-logo'),
                                  size: logoSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: KcSpacing.sm),
                        SlideTransition(
                          position: _titleRise,
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: KcBrandName(
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 38,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: KcSpacing.lg),
                        SplashStatusCard(
                          phase: widget.phase,
                          animate: !disableAnimations,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
