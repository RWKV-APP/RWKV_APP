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
      background: appTheme.g1,
      foreground: appTheme.g5,
      border: appTheme.g2,
    ),
    .available => InteractionVisualColors(
      background: appTheme.qb14,
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
