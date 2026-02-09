// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:zone/gen/l10n.dart';

enum AppTheme {
  /// 浅色主题
  light(
    isLight: true,

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
  });

  /// 是否为浅色主题
  final bool isLight;

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
