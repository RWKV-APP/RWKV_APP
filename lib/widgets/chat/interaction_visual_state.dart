// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zone/model/app_theme.dart';

enum InteractionVisualState {
  unavailable,
  idleInteractive,
  available,
  enabled,
}

class InteractionVisualColors {
  const InteractionVisualColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

InteractionVisualColors interactionVisualColors({
  required AppTheme appTheme,
  required InteractionVisualState state,
}) {
  final qw = appTheme.isLight ? Colors.white : Colors.black;

  final unavailableColors = InteractionVisualColors(
    // background: Color.lerp(appTheme.g1, appTheme.scaffoldBg, .33) ?? appTheme.g1,
    // background: Colors.transparent,
    background: qw,
    foreground: Color.lerp(appTheme.g5, appTheme.scaffoldBg, .33) ?? appTheme.g5,
    border: Color.lerp(appTheme.g2, appTheme.scaffoldBg, .33) ?? appTheme.g2,
  );

  final availableColors = InteractionVisualColors(
    // background: appTheme.qb144,
    // background: Colors.transparent,
    background: qw,
    foreground: appTheme.qb4,
    border: appTheme.qb11,
  );

  return switch (state) {
    .unavailable => unavailableColors,
    .idleInteractive => InteractionVisualColors(
      // background: Color.lerp(unavailableColors.background, availableColors.background, .55) ?? availableColors.background,
      // background: appTheme.isLight ? Colors.white : Colors.black,
      background: qw,
      foreground: Color.lerp(unavailableColors.foreground, availableColors.foreground, .45) ?? availableColors.foreground,
      border: Color.lerp(unavailableColors.border, availableColors.border, .5) ?? availableColors.border,
    ),
    .available => availableColors,
    .enabled => InteractionVisualColors(
      background: appTheme.qb5,
      // background: Colors.transparent,
      foreground: appTheme.g1,
      border: appTheme.qb5,
    ),
  };
}
