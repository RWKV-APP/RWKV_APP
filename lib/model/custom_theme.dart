import 'dart:ui';

import 'package:zone/gen/l10n.dart';

enum CustomTheme {
  /// 浅色主题
  light(
    isLight: true,
    scaffold: Color(0xFFFFFFFF),
    setting: Color(0xFFF5F5F5),
    settingItem: Color(0xFFFFFFFF),
    pagerDim: Color(0xFF000000),
  ),

  /// 深色主题, 中对比度
  dim(
    isLight: false,
    scaffold: Color(0xFF151515),
    setting: Color(0xFF252525),
    settingItem: Color(0xFF353535),
    pagerDim: Color(0xFFFFFFFF),
  ),

  /// 全黑主题, 高对比度
  lightsOut(
    isLight: false,
    scaffold: Color(0xFF000000),
    setting: Color(0xFF000000),
    settingItem: Color(0xFF121212),
    pagerDim: Color(0xFFFFFFFF),
  )
  ;

  const CustomTheme({
    required this.isLight,
    required this.scaffold,
    required this.setting,
    required this.settingItem,
    required this.pagerDim,
  });

  /// 是否为浅色主题
  final bool isLight;
  final Color scaffold;
  final Color setting;
  final Color settingItem;
  final Color pagerDim;

  /// displayName 不能作为 const 构造参数，
  /// 因为 S.current 是运行时获取的（非 const），所以必须写成 getter。
  String get displayName {
    final s = S.current;
    return switch (this) {
      .light => s.theme_light,
      .dim => s.theme_dim,
      .lightsOut => s.theme_lights_out,
    };
  }

  /// 替代原本的 fromString，兼容旧的 "Light"/"Dim"/"LightsOut" 字符串。
  static CustomTheme? fromString(String name) {
    return switch (name) {
      "Light" => .light,
      "Dim" => .dim,
      "LightsOut" => .lightsOut,
      _ => null,
    };
  }

  /// 维持与旧实现兼容的字符串表示（"Light"/"Dim"/"LightsOut"）。
  @override
  String toString() {
    return switch (this) {
      .light => "Light",
      .dim => "Dim",
      .lightsOut => "LightsOut",
    };
  }
}
