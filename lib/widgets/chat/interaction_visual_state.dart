import 'package:flutter/material.dart';
import 'package:zone/model/app_theme.dart';

enum InteractionVisualState {
  unavailable,
  enabled,
  available,
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
  return switch (state) {
    .unavailable => InteractionVisualColors(
      background: Color.lerp(appTheme.g1, appTheme.scaffoldBg, .33) ?? appTheme.g1,
      foreground: Color.lerp(appTheme.g5, appTheme.scaffoldBg, .33) ?? appTheme.g5,
      border: Color.lerp(appTheme.g2, appTheme.scaffoldBg, .33) ?? appTheme.g2,
    ),
    .available => InteractionVisualColors(
      background: appTheme.qb144,
      foreground: appTheme.qb4,
      border: appTheme.qb11,
    ),
    .enabled => InteractionVisualColors(
      background: appTheme.qb5,
      foreground: appTheme.g1,
      border: appTheme.qb5,
    ),
  };
}
