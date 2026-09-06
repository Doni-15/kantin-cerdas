import 'package:flutter/material.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_colors.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_elevation.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_radius.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_size.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_spacing.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_typography.dart';

abstract final class KantinCerdasTheme {
  static ThemeData get light => _build(
    colorScheme: KantinCerdasColors.lightScheme,
    backgroundColor: KantinCerdasColors.lightBackground,
    disabledColor: KantinCerdasColors.lightDisabled,
  );

  static ThemeData get dark => _build(
    colorScheme: KantinCerdasColors.darkScheme,
    backgroundColor: KantinCerdasColors.darkBackground,
    disabledColor: KantinCerdasColors.darkDisabled,
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color backgroundColor,
    required Color disabledColor,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
    );

    final textTheme = KantinCerdasTypography.applyTo(baseTheme.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final componentShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KantinCerdasRadius.medium),
    );
    const minimumButtonSize = Size(
      KantinCerdasSize.minimumTouchTarget,
      KantinCerdasSize.minimumTouchTarget,
    );
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: KantinCerdasSpacing.space4,
      vertical: KantinCerdasSpacing.space3,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(KantinCerdasRadius.medium),
      // Batas input aktif memakai token yang cukup kontras.
      borderSide: BorderSide(color: colorScheme.onSurfaceVariant),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      disabledColor: disabledColor,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: backgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: KantinCerdasElevation.flat,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: disabledColor,
          minimumSize: minimumButtonSize,
          padding: buttonPadding,
          shape: componentShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.primary,
              disabledForegroundColor: disabledColor,
              minimumSize: minimumButtonSize,
              padding: buttonPadding,
              shape: componentShape,
              textStyle: textTheme.labelLarge,
            ).copyWith(
              side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                return BorderSide(
                  color: states.contains(WidgetState.disabled)
                      ? colorScheme.outlineVariant
                      : colorScheme.primary,
                );
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: disabledColor,
          minimumSize: minimumButtonSize,
          padding: buttonPadding,
          shape: componentShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.all(KantinCerdasSpacing.space4),
        constraints: const BoxConstraints(
          minHeight: KantinCerdasSize.minimumTouchTarget,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: KantinCerdasElevation.flat,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          return textTheme.labelLarge?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: KantinCerdasElevation.modal,
        modalElevation: KantinCerdasElevation.modal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KantinCerdasRadius.extraLarge),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: KantinCerdasElevation.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KantinCerdasRadius.large),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        elevation: KantinCerdasElevation.floating,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}
