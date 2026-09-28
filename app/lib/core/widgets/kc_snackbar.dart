import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';

enum KcSnackBarType {
  success,
  error,
  warning,
  info,
}

abstract final class KcSnackBar {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    KcSnackBarType type = KcSnackBarType.info,
  }) {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColors = KcStatusColors.of(context);

    _currentEntry?.remove();
    _currentEntry = null;

    final (
      Color backgroundColor,
      Color foregroundColor,
      IconData icon,
    ) = switch (type) {
      KcSnackBarType.success => (
          statusColors.successContainer,
          statusColors.success,
          Icons.check_circle_outline,
        ),
      KcSnackBarType.error => (
          colors.errorContainer,
          colors.onErrorContainer,
          Icons.error_outline,
        ),
      KcSnackBarType.warning => (
          statusColors.warningContainer,
          statusColors.warning,
          Icons.warning_amber_outlined,
        ),
      KcSnackBarType.info => (
          statusColors.infoContainer,
          statusColors.info,
          Icons.info_outline,
        ),
    };

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _KcSnackBarOverlay(
          message: message,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          icon: icon,
          textStyle: theme.textTheme.bodyMedium,
          onDismissed: () {
            if (identical(_currentEntry, entry)) {
              _currentEntry = null;
            }

            entry.remove();
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void success(
    BuildContext context,
    String message,
  ) {
    show(
      context,
      message: message,
      type: KcSnackBarType.success,
    );
  }

  static void error(
    BuildContext context,
    String message,
  ) {
    show(
      context,
      message: message,
      type: KcSnackBarType.error,
    );
  }

  static void warning(
    BuildContext context,
    String message,
  ) {
    show(
      context,
      message: message,
      type: KcSnackBarType.warning,
    );
  }

  static void info(
    BuildContext context,
    String message,
  ) {
    show(
      context,
      message: message,
      type: KcSnackBarType.info,
    );
  }
}

class _KcSnackBarOverlay extends StatefulWidget {
  const _KcSnackBarOverlay({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.textStyle,
    required this.onDismissed,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final TextStyle? textStyle;
  final VoidCallback onDismissed;

  @override
  State<_KcSnackBarOverlay> createState() => _KcSnackBarOverlayState();
}

class _KcSnackBarOverlayState extends State<_KcSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    _dismissAutomatically();
  }

  Future<void> _dismissAutomatically() async {
    await Future<void>.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) {
      return;
    }

    await _controller.reverse();

    if (!mounted) {
      return;
    }

    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 12,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.foregroundColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: widget.textStyle?.copyWith(
                          color: widget.foregroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}