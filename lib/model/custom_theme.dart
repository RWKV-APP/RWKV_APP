import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:zone/gen/l10n.dart';

sealed class CustomTheme extends Equatable {
  abstract final String displayName;
  abstract final Color scaffold;
  abstract final Color setting;
  abstract final Color settingItem;
  abstract final Color pagerDim;
  abstract final bool light;

  @override
  List<Object?> get props => [displayName, scaffold, setting, settingItem, pagerDim];

  static CustomTheme? fromString(String name) {
    switch (name) {
      case "Light":
        return Light();
      case "Dim":
        return Dim();
      case "LightsOut":
        return LightsOut();
    }
    return null;
  }

  @override
  String toString() {
    return runtimeType.toString();
  }
}

final class Light extends CustomTheme {
  @override
  String get displayName => S.current.theme_light;

  @override
  final bool light = true;

  @override
  final Color scaffold = const Color(0xFFFFFFFF); // Apple System Background

  @override
  final Color setting = const Color(0xFFF2F2F7); // Apple Secondary System Background

  @override
  final Color settingItem = const Color(0xFFFFFFFF); // Apple Grouped Background

  @override
  final Color pagerDim = const Color(0xFF000000);
}

final class Dim extends CustomTheme {
  @override
  String get displayName => S.current.theme_dim;

  @override
  final bool light = false;

  @override
  final Color scaffold = const Color(0xFF1C1C1E); // Apple System Background (Dark)

  @override
  final Color setting = const Color(0xFF2C2C2E); // Apple Secondary System Background (Dark)

  @override
  final Color settingItem = const Color(0xFF3A3A3C); // Apple Tertiary System Background (Dark)

  @override
  final Color pagerDim = const Color(0xFFFFFFFF);
}

final class LightsOut extends CustomTheme {
  @override
  String get displayName => S.current.theme_lights_out;

  @override
  final bool light = false;

  @override
  final Color scaffold = const Color(0xFF000000); // Pure black for OLED

  @override
  final Color setting = const Color(0xFF000000); // Pure black

  @override
  final Color settingItem = const Color(0xFF1C1C1E); // Apple Dark elevated surface

  @override
  final Color pagerDim = const Color(0xFFFFFFFF);
}
