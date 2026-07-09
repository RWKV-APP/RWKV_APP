// Flutter imports:
import 'package:flutter/material.dart';

ThemeData webDemoGrayscaleTheme(ThemeData theme) {
  final scheme = webDemoGrayscaleScheme(theme.brightness);
  final overlay = scheme.onSurface.withValues(alpha: .08);
  final selectedOverlay = scheme.onSurface.withValues(alpha: .12);
  final disabledForeground = scheme.onSurfaceVariant.withValues(alpha: .42);
  final disabledBackground = scheme.surfaceContainerHighest.withValues(alpha: .72);

  return theme.copyWith(
    brightness: scheme.brightness,
    colorScheme: scheme,
    primaryColor: scheme.primary,
    primaryColorLight: scheme.primaryContainer,
    primaryColorDark: scheme.onSurface,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    cardColor: scheme.surfaceContainerLow,
    dividerColor: scheme.outlineVariant,
    disabledColor: disabledForeground,
    focusColor: selectedOverlay,
    highlightColor: overlay,
    hoverColor: overlay,
    splashColor: selectedOverlay,
    shadowColor: scheme.shadow,
    bottomSheetTheme: theme.bottomSheetTheme.copyWith(
      backgroundColor: scheme.surface,
      modalBackgroundColor: scheme.surface,
      modalBarrierColor: scheme.scrim.withValues(alpha: .44),
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: theme.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.primaryContainer,
      disabledColor: disabledBackground,
      secondarySelectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      labelStyle: theme.chipTheme.labelStyle?.copyWith(color: scheme.onSurface),
      secondaryLabelStyle: theme.chipTheme.secondaryLabelStyle?.copyWith(color: scheme.onPrimaryContainer),
      side: BorderSide(color: scheme.outlineVariant, width: .5),
    ),
    dropdownMenuTheme: theme.dropdownMenuTheme.copyWith(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(scheme.shadow),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledBackground;
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledForeground;
          return scheme.onPrimary;
        }),
        overlayColor: WidgetStatePropertyAll(scheme.onPrimary.withValues(alpha: .12)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledForeground;
          return scheme.onSurface;
        }),
        overlayColor: WidgetStatePropertyAll(selectedOverlay),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return BorderSide(color: scheme.outlineVariant.withValues(alpha: .7), width: .5);
          return BorderSide(color: scheme.outline, width: .8);
        }),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledForeground;
          return scheme.onSurface;
        }),
        overlayColor: WidgetStatePropertyAll(selectedOverlay),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledForeground;
          return scheme.onSurface;
        }),
        overlayColor: WidgetStatePropertyAll(selectedOverlay),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledBackground;
          if (states.contains(WidgetState.selected)) return scheme.primaryContainer;
          return scheme.surfaceContainerLow;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledForeground;
          if (states.contains(WidgetState.selected)) return scheme.onPrimaryContainer;
          return scheme.onSurface;
        }),
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledForeground;
          if (states.contains(WidgetState.selected)) return scheme.onPrimaryContainer;
          return scheme.onSurfaceVariant;
        }),
        overlayColor: WidgetStatePropertyAll(selectedOverlay),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant, width: .5)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    sliderTheme: theme.sliderTheme.copyWith(
      activeTrackColor: scheme.onSurface,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      secondaryActiveTrackColor: scheme.onSurfaceVariant,
      disabledActiveTrackColor: disabledForeground,
      disabledInactiveTrackColor: disabledBackground,
      thumbColor: scheme.onSurface,
      disabledThumbColor: disabledForeground,
      overlayColor: selectedOverlay,
      valueIndicatorColor: scheme.onSurface,
      valueIndicatorTextStyle: theme.textTheme.labelSmall?.copyWith(color: scheme.surface),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.onSurface,
      circularTrackColor: scheme.surfaceContainerHighest,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      focusColor: selectedOverlay,
      hoverColor: overlay,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(scheme.shadow),
      ),
    ),
    popupMenuTheme: theme.popupMenuTheme.copyWith(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      textStyle: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.onSurface,
      selectionColor: scheme.onSurface.withValues(alpha: .18),
      selectionHandleColor: scheme.onSurface,
    ),
  );
}

ColorScheme webDemoGrayscaleScheme(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFE6E6E6),
      onPrimary: Color(0xFF111111),
      primaryContainer: Color(0xFF3A3A3A),
      onPrimaryContainer: Color(0xFFF2F2F2),
      primaryFixed: Color(0xFFE8E8E8),
      primaryFixedDim: Color(0xFFC8C8C8),
      onPrimaryFixed: Color(0xFF111111),
      onPrimaryFixedVariant: Color(0xFF3A3A3A),
      secondary: Color(0xFFD2D2D2),
      onSecondary: Color(0xFF111111),
      secondaryContainer: Color(0xFF333333),
      onSecondaryContainer: Color(0xFFEAEAEA),
      secondaryFixed: Color(0xFFDADADA),
      secondaryFixedDim: Color(0xFFBDBDBD),
      onSecondaryFixed: Color(0xFF111111),
      onSecondaryFixedVariant: Color(0xFF3A3A3A),
      tertiary: Color(0xFFD2D2D2),
      onTertiary: Color(0xFF111111),
      tertiaryContainer: Color(0xFF333333),
      onTertiaryContainer: Color(0xFFEAEAEA),
      tertiaryFixed: Color(0xFFDADADA),
      tertiaryFixedDim: Color(0xFFBDBDBD),
      onTertiaryFixed: Color(0xFF111111),
      onTertiaryFixedVariant: Color(0xFF3A3A3A),
      error: Color(0xFFE0E0E0),
      onError: Color(0xFF111111),
      errorContainer: Color(0xFF343434),
      onErrorContainer: Color(0xFFF0F0F0),
      surface: Color(0xFF151515),
      onSurface: Color(0xFFF2F2F2),
      surfaceDim: Color(0xFF0F0F0F),
      surfaceBright: Color(0xFF2A2A2A),
      surfaceContainerLowest: Color(0xFF0A0A0A),
      surfaceContainerLow: Color(0xFF1D1D1D),
      surfaceContainer: Color(0xFF242424),
      surfaceContainerHigh: Color(0xFF2E2E2E),
      surfaceContainerHighest: Color(0xFF383838),
      onSurfaceVariant: Color(0xFFC8C8C8),
      outline: Color(0xFF7A7A7A),
      outlineVariant: Color(0xFF444444),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFEAEAEA),
      onInverseSurface: Color(0xFF202020),
      inversePrimary: Color(0xFF404040),
      surfaceTint: Colors.transparent,
    );
  }

  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF262626),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE2E2E2),
    onPrimaryContainer: Color(0xFF202020),
    primaryFixed: Color(0xFFE6E6E6),
    primaryFixedDim: Color(0xFFCFCFCF),
    onPrimaryFixed: Color(0xFF202020),
    onPrimaryFixedVariant: Color(0xFF555555),
    secondary: Color(0xFF565656),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE6E6E6),
    onSecondaryContainer: Color(0xFF202020),
    secondaryFixed: Color(0xFFEAEAEA),
    secondaryFixedDim: Color(0xFFD0D0D0),
    onSecondaryFixed: Color(0xFF202020),
    onSecondaryFixedVariant: Color(0xFF555555),
    tertiary: Color(0xFF565656),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6E6E6),
    onTertiaryContainer: Color(0xFF202020),
    tertiaryFixed: Color(0xFFEAEAEA),
    tertiaryFixedDim: Color(0xFFD0D0D0),
    onTertiaryFixed: Color(0xFF202020),
    onTertiaryFixedVariant: Color(0xFF555555),
    error: Color(0xFF202020),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFE5E5E5),
    onErrorContainer: Color(0xFF202020),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF202020),
    surfaceDim: Color(0xFFE6E6E6),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F7F7),
    surfaceContainer: Color(0xFFF0F0F0),
    surfaceContainerHigh: Color(0xFFE9E9E9),
    surfaceContainerHighest: Color(0xFFE0E0E0),
    onSurfaceVariant: Color(0xFF666666),
    outline: Color(0xFF888888),
    outlineVariant: Color(0xFFC8C8C8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2A2A2A),
    onInverseSurface: Color(0xFFF2F2F2),
    inversePrimary: Color(0xFFD0D0D0),
    surfaceTint: Colors.transparent,
  );
}
