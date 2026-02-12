// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:zone/gen/l10n.dart';

enum AppTheme {
  /// 浅色主题
  light(
    isLight: true,
    primary: Color(0xFF0F968A),
    themePrimary: Color(0xFF404040),

    g1: Color(0xFFEEEEEE),
    g2: Color(0xFFDDDDDD),
    g3: Color(0xFFCCCCCC),
    g4: Color(0xFFBBBBBB),
    g5: Color(0xFFAAAAAA),
    g6: Color(0xFF999999),
    g7: Color(0xFF888888),

    qb1: Color(0xFF111111),
    qb2: Color(0xFF222222),
    qb3: Color(0xFF333333),
    qb4: Color(0xFF444444),
    qb5: Color(0xFF555555),
    qb6: Color(0xFF666666),
    qb7: Color(0xFF777777),
    qb8: Color(0xFF888888),
    qb9: Color(0xFF999999),
    qb10: Color(0xFFAAAAAA),
    qb11: Color(0xFFBBBBBB),
    qb12: Color(0xFFCCCCCC),
    qb13: Color(0xFFDDDDDD),
    qb14: Color(0xFFEEEEEE),

    scaffoldBg: Color(0xFFFFFFFF),
    settingBg: Color(0xFFF5F5F5),

    appBarBgC: Color(0xFFFFFFFF),
    settingItem: Color(0xFFFFFFFF),
    pagerDim: Color(0xFF000000),
    textInputShadowC: Color(0x22000000),
    textInputBorderC: Color(0x2A000000),
    textInputBgC: Color(0xFFFFFFFF),
    sendingButtonC: Color(0xFF000000),
    stopButtonC: Color(0xFF000000),
    generatingIndicatorC: Color(0xFF000000),
    botMsgBg: Color(0xFFFFFFFF),
    userMsgBg: Color(0xFFF5F5F5),
  ),

  /// 深色主题, 中对比度
  dim(
    isLight: false,
    primary: Color(0xFF0D9488),
    themePrimary: Color(0xFFAAAAAA),

    g1: Color(0xFF111111),
    g2: Color(0xFF222222),
    g3: Color(0xFF333333),
    g4: Color(0xFF444444),
    g5: Color(0xFF555555),
    g6: Color(0xFF666666),
    g7: Color(0xFF777777),

    qb14: Color(0xFF101010),
    qb13: Color(0xFF202020),
    qb12: Color(0xFF303030),
    qb11: Color(0xFF404040),
    qb10: Color(0xFF505050),
    qb9: Color(0xFF606060),
    qb8: Color(0xFF707070),
    qb7: Color(0xFF808080),
    qb6: Color(0xFF909090),
    qb5: Color(0xFFA0A0A0),
    qb4: Color(0xFFB0B0B0),
    qb3: Color(0xFFC0C0C0),
    qb2: Color(0xFFD0D0D0),
    qb1: Color(0xFFE0E0E0),

    scaffoldBg: Color(0xFF151515),
    settingBg: Color(0xFF252525),

    appBarBgC: Color(0xFF151515),
    settingItem: Color(0xFF353535),
    pagerDim: Color(0xFFFFFFFF),
    textInputShadowC: Color(0x22000000),
    textInputBorderC: Color(0x11FFFFFF),
    textInputBgC: Color(0xFF303030),
    sendingButtonC: Color(0xFFFFFFFF),
    stopButtonC: Color(0xFF000000),
    generatingIndicatorC: Color(0xFF000000),
    botMsgBg: Color(0xFF151515),
    userMsgBg: Color(0xFF303030),
  ),

  /// 全黑主题, 高对比度
  lightsOut(
    isLight: false,
    primary: Color(0xFF0D9488),
    themePrimary: Color(0xFFCCCCCC),

    g1: Color(0xFF101010),
    g2: Color(0xFF202020),
    g3: Color(0xFF303030),
    g4: Color(0xFF404040),
    g5: Color(0xFF505050),
    g6: Color(0xFF606060),
    g7: Color(0xFF707070),

    qb14: Color(0xFF111111),
    qb13: Color(0xFF222222),
    qb12: Color(0xFF333333),
    qb11: Color(0xFF444444),
    qb10: Color(0xFF555555),
    qb9: Color(0xFF666666),
    qb8: Color(0xFF777777),
    qb7: Color(0xFF888888),
    qb6: Color(0xFF999999),
    qb5: Color(0xFFAAAAAA),
    qb4: Color(0xFFBBBBBB),
    qb3: Color(0xFFCCCCCC),
    qb2: Color(0xFFDDDDDD),
    qb1: Color(0xFFEEEEEE),

    scaffoldBg: Color(0xFF000000),
    settingBg: Color(0xFF000000),

    appBarBgC: Color(0xFF000000),
    settingItem: Color(0xFF121212),
    pagerDim: Color(0xFFFFFFFF),
    textInputShadowC: Color(0x22000000),
    textInputBorderC: Color(0x11FFFFFF),
    textInputBgC: Color(0xFF141414),
    sendingButtonC: Color(0xFFFFFFFF),
    stopButtonC: Color(0xFF000000),
    generatingIndicatorC: Color(0xFF000000),
    botMsgBg: Color(0xFF000000),
    userMsgBg: Color(0xFF121212),
  ),
  ;

  const AppTheme({
    required this.primary,
    required this.themePrimary,
    required this.textInputBorderC,
    required this.textInputShadowC,
    required this.isLight,
    required this.pagerDim,
    required this.scaffoldBg,
    required this.settingBg,
    required this.settingItem,
    required this.textInputBgC,
    required this.sendingButtonC,
    required this.stopButtonC,
    required this.generatingIndicatorC,
    required this.botMsgBg,
    required this.userMsgBg,
    required this.appBarBgC,
    required this.g1,
    required this.g2,
    required this.g3,
    required this.g4,
    required this.g5,
    required this.g6,
    required this.g7,
    required this.qb1,
    required this.qb2,
    required this.qb3,
    required this.qb4,
    required this.qb5,
    required this.qb6,
    required this.qb7,
    required this.qb8,
    required this.qb9,
    required this.qb10,
    required this.qb11,
    required this.qb12,
    required this.qb13,
    required this.qb14,
  });

  /// 是否为浅色主题
  final bool isLight;

  /// RWKV Chat 专属主题色
  final Color primary;

  /// 提供给 Material Design 的主题色
  final Color themePrimary;

  final Color g1;
  final Color g2;
  final Color g3;
  final Color g4;
  final Color g5;
  final Color g6;
  final Color g7;

  final Color qb1;
  final Color qb2;
  final Color qb3;
  final Color qb4;
  final Color qb5;
  final Color qb6;
  final Color qb7;
  final Color qb8;
  final Color qb9;
  final Color qb10;
  final Color qb11;
  final Color qb12;
  final Color qb13;
  final Color qb14;

  final Color scaffoldBg;

  final Color appBarBgC;
  final double appBarBottomLineHeight = 0.5;

  final Color settingBg;
  final Color settingItem;
  final Color pagerDim;

  final double inputBarHorizontalPadding = 12.0;
  final double inputBarMinPaddingBottom = 8;
  final double inputBarTopDistance = 8;

  final Size sendingButtonTouchMinSize = const Size(44, 48);
  final Size sendingButtonVisualSize = const Size(38, 38);
  final Size sendingButtonIconSize = const Size(24, 24);

  final Color sendingButtonC;
  final double sendingButtonDisabledOpacity = 0.5;

  final Color stopButtonC;
  final Color generatingIndicatorC;

  final double msgListMarginLeft = 12.0;
  final double msgListMarginRight = 12.0;
  final double msgListMarginTop = 0;
  final double msgListMarginBottom = 0;

  final Color botMsgBg;
  final Color userMsgBg;
  final EdgeInsets msgDefaultPadding = const .only(left: 12, top: 12, right: 12);
  final EdgeInsets chatUserMsgBubblePadding = const .only(left: 12, top: 12, right: 4, bottom: 0);
  final EdgeInsets chatBotMsgBubblePadding = const .only(left: 0, top: 0, right: 0, bottom: 0);

  final Color textInputShadowC;
  final double inputBarShadowRadius = 8.0;
  final Offset inputBarShadowOffset = const Offset(0, 3);
  final Color textInputBorderC;
  final Color textInputBgC;
  final double inputBarBorderRadius = 25;

  final double settingsSectionTitleLeftSpace = 12;
  final double settingsSectionTitleBottomSpace = 20;
  final double settingsSectionTitleTopSpace = 12;
  final double settingVersionOpacity = 0.8;

  final double tabBarHeight = 60;
  final double tabBarBorderRadius = 100;
  final double tabBarBorderWidth = 0.5;
  final double tabBarRightPadding = 12;
  final double tabBarLeftPadding = 12;

  final double startButtonRadius = 4.0;

  ColorScheme get colorScheme {
    final Brightness brightness = isLight ? Brightness.light : Brightness.dark;
    final ColorScheme seeded = ColorScheme.fromSeed(
      seedColor: themePrimary,
      brightness: brightness,
    );
    return seeded.copyWith(
      primary: themePrimary,
    );
  }

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
  static AppTheme? fromString(String name) {
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
