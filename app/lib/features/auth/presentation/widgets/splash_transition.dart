import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/splash_screen.dart';

class SplashTransition extends StatefulWidget {
  const SplashTransition({super.key, required this.screen});

  final Widget screen;

  @override
  State<SplashTransition> createState() => _SplashTransitionState();
}

class _SplashTransitionState extends State<SplashTransition> {
  static const _minimumDuration = Duration(milliseconds: 3000);
  static const _fadeOutDuration = Duration(milliseconds: 460);
  Timer? _minimumTimer;
  var _minimumElapsed = false;

  @override
  void initState() {
    super.initState();
    // Count from the first splash frame, after platform and engine startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _minimumTimer = Timer(_minimumDuration, () {
        setState(() => _minimumElapsed = true);
      });
    });
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final screen = widget.screen;
    final loading = screen is SplashScreen;
    final showingSplash = loading || !_minimumElapsed;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: showingSplash ? const SizedBox.shrink() : screen,
        ),
        IgnorePointer(
          ignoring: !showingSplash,
          child: ExcludeSemantics(
            excluding: !showingSplash,
            child: AnimatedSwitcher(
              duration: animate ? _fadeOutDuration : Duration.zero,
              switchOutCurve: Curves.easeInOutCubic,
              child: loading
                  ? screen
                  : !_minimumElapsed
                  ? const SplashScreen(phase: SplashPhase.ready)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
