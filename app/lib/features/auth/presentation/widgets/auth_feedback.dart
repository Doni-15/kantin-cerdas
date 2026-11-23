import 'package:flutter/material.dart';

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.centered = false,
  });
  final String title;
  final String subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: centered
                  ? theme.textTheme.headlineLarge
                  : theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthNotice extends StatelessWidget {
  const AuthNotice(this.text, {super.key, this.isError = true});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isError ? colors.errorContainer : colors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              text,
              style: TextStyle(
                color: isError
                    ? colors.onErrorContainer
                    : colors.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
