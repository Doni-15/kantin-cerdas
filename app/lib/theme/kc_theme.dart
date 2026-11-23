import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_sizes.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/theme/kc_typography.dart';

abstract final class KcTheme {
  static final ThemeData light = _build(KcColors.light, KcStatusColors.light);

  static final ThemeData dark = _build(KcColors.dark, KcStatusColors.dark);

  static ThemeData _build(ColorScheme colors, KcStatusColors statusColors) {
    final isDark = colors.brightness == Brightness.dark;
    final controlRadius = BorderRadius.circular(KcRadius.control);

    final base = ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      fontFamily: KcTypography.fontFamily,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = KcTypography.apply(
      base.textTheme,
    ).apply(bodyColor: colors.onSurface, displayColor: colors.onSurface);

    final controlShape = RoundedRectangleBorder(borderRadius: controlRadius);

    final disabledColor = colors.onSurface.withValues(alpha: 0.38);

    const minimumTouchTargetSize = Size(
      KcSizes.minimumTouchTarget,
      KcSizes.minimumTouchTarget,
    );

    const buttonPadding = EdgeInsets.symmetric(
      horizontal: KcSpacing.lg,
      vertical: KcSpacing.sm,
    );

    const textButtonPadding = EdgeInsets.symmetric(
      horizontal: KcSpacing.md,
      vertical: KcSpacing.sm,
    );

    Color inputForeground(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledColor;
      }

      if (states.contains(WidgetState.error)) {
        return colors.error;
      }

      if (states.contains(WidgetState.focused)) {
        return colors.primary;
      }

      return colors.onSurfaceVariant;
    }

    final inputLabelStyle = WidgetStateTextStyle.resolveWith((states) {
      return textTheme.bodyLarge!.copyWith(color: inputForeground(states));
    });

    final inputIconColor = WidgetStateColor.resolveWith(inputForeground);

    final chipLabelStyle = textTheme.labelLarge!.copyWith(
      color: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return disabledColor;
        }

        if (states.contains(WidgetState.selected)) {
          return colors.onSecondaryContainer;
        }

        return colors.onSurfaceVariant;
      }),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[statusColors],

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,

        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: colors.brightness,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KcRadius.card),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainer,
        contentPadding: const EdgeInsets.all(KcSpacing.md),

        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colors.onSurfaceVariant,
        ),

        labelStyle: inputLabelStyle,
        floatingLabelStyle: inputLabelStyle,

        helperStyle: textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),

        errorStyle: textTheme.bodySmall?.copyWith(color: colors.error),

        errorMaxLines: 3,
        prefixIconColor: inputIconColor,
        suffixIconColor: inputIconColor,
        border: inputBorder(colors.outline),
        enabledBorder: inputBorder(colors.outline),
        disabledBorder: inputBorder(colors.outlineVariant),
        focusedBorder: inputBorder(colors.primary, 2),
        errorBorder: inputBorder(colors.error),
        focusedErrorBorder: inputBorder(colors.error, 2),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minimumTouchTargetSize,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minimumTouchTargetSize,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minimumTouchTargetSize,
          padding: textButtonPadding,
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: minimumTouchTargetSize,
          padding: const EdgeInsets.all(KcSpacing.xs),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(alpha: 0.12);
          }

          if (states.contains(WidgetState.selected)) {
            return colors.secondaryContainer;
          }

          return colors.surfaceContainer;
        }),

        labelStyle: chipLabelStyle,
        secondaryLabelStyle: chipLabelStyle,
        checkmarkColor: colors.onSecondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KcRadius.small),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.disabled)) {
            return IconThemeData(color: disabledColor);
          }

          final selected = states.contains(WidgetState.selected);

          return IconThemeData(
            color: selected
                ? colors.onSecondaryContainer
                : colors.onSurfaceVariant,
          );
        }),

        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.disabled)) {
            return textTheme.labelMedium!.copyWith(
              color: disabledColor,
              fontWeight: FontWeight.w500,
            );
          }

          final selected = states.contains(WidgetState.selected);

          return textTheme.labelMedium!.copyWith(
            color: selected ? colors.onSurface : colors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLow,
        modalBackgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: colors.onSurfaceVariant,

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KcRadius.modal),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KcRadius.modal),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        actionTextColor: colors.inversePrimary,
        shape: controlShape,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
        circularTrackColor: colors.surfaceContainerHighest,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.25),
        selectionHandleColor: colors.primary,
      ),
    );
  }
}
