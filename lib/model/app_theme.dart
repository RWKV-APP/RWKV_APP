// ignore_for_file: unused_element_parameter

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';

final class AppTheme {
  /// 浅色主题
  static const light = AppTheme._(
    storageId: 'Light',
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

    qb0: Color(0xFF000000),
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
    qb144: Color(0xFFF3F3F3),
    qb15: Color(0xFFFFFFFF),

    inlineCodeBackgroundColor: Color(0xFFEEEEEE),

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
  );

  /// 深色主题, 中对比度
  static const dim = AppTheme._(
    storageId: 'Dim',
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

    qb0: Color(0xFFFFFFFF),
    qb1: Color(0xFFF5F5F5),
    qb2: Color(0xFFE5E5E5),
    qb3: Color(0xFFD5D5D5),
    qb4: Color(0xFFC5C5C5),
    qb5: Color(0xFFB5B5B5),
    qb6: Color(0xFFA5A5A5),
    qb7: Color(0xFF959595),
    qb8: Color(0xFF858585),
    qb9: Color(0xFF757575),
    qb10: Color(0xFF656565),
    qb11: Color(0xFF555555),
    qb12: Color(0xFF454545),
    qb13: Color(0xFF353535),
    qb14: Color(0xFF252525),
    qb144: Color(0xFF1D1D1D),
    qb15: Color(0xFF151515),

    inlineCodeBackgroundColor: Color(0xFF353535),

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
  );

  /// 全黑主题, 高对比度
  static const lightsOut = AppTheme._(
    storageId: 'LightsOut',
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

    qb0: Color(0xFFFFFFFF),
    qb1: Color(0xFFEEEEEE),
    qb2: Color(0xFFDDDDDD),
    qb3: Color(0xFFCCCCCC),
    qb4: Color(0xFFBBBBBB),
    qb5: Color(0xFFAAAAAA),
    qb6: Color(0xFF999999),
    qb7: Color(0xFF888888),
    qb8: Color(0xFF777777),
    qb9: Color(0xFF666666),
    qb10: Color(0xFF555555),
    qb11: Color(0xFF444444),
    qb12: Color(0xFF333333),
    qb13: Color(0xFF222222),
    qb14: Color(0xFF111111),
    qb144: Color(0xFF101010),
    qb15: Color(0xFF000000),

    inlineCodeBackgroundColor: Color(0xFF222222),

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
  );

  static const paper = AppTheme.tinted(
    storageId: 'Paper',
    isLight: true,
    accent: Color(0xFF865128),
    canvas: Color(0xFFFCF6E9),
    panel: Color(0xFFF0E5D5),
    card: Color(0xFFFFF9EF),
    bubble: Color(0xFFEEDCC4),
  );
  static const glacier = AppTheme.tinted(
    storageId: 'Glacier',
    isLight: true,
    accent: Color(0xFF1F5CA9),
    canvas: Color(0xFFF1F7FD),
    panel: Color(0xFFE2EDF8),
    card: Color(0xFFF8FBFF),
    bubble: Color(0xFFD9E9FA),
  );
  static const midnight = AppTheme.tinted(
    storageId: 'Midnight',
    isLight: false,
    accent: Color(0xFFA7B9FF),
    canvas: Color(0xFF0F1629),
    panel: Color(0xFF141D34),
    card: Color(0xFF1A2642),
    bubble: Color(0xFF26395D),
  );
  static const forest = AppTheme.tinted(
    storageId: 'Forest',
    isLight: false,
    accent: Color(0xFFA2D7AC),
    canvas: Color(0xFF101D19),
    panel: Color(0xFF172721),
    card: Color(0xFF1F342A),
    bubble: Color(0xFF2B4638),
  );

  static const values = [light, dim, lightsOut, paper, glacier, midnight, forest];

  const AppTheme.tinted({
    required String storageId,
    required bool isLight,
    required Color accent,
    required Color canvas,
    required Color panel,
    required Color card,
    required Color bubble,
  }) : this._(
         storageId: storageId,
         tinted: true,
         isLight: isLight,
         primary: accent,
         themePrimary: accent,
         g1: panel,
         g2: bubble,
         g3: isLight ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
         g4: isLight ? const Color(0xFFBBBBBB) : const Color(0xFF444444),
         g5: isLight ? const Color(0xFFAAAAAA) : const Color(0xFF555555),
         g6: isLight ? const Color(0xFF999999) : const Color(0xFF666666),
         g7: isLight ? const Color(0xFF888888) : const Color(0xFF777777),
         qb0: isLight ? Colors.black : Colors.white,
         qb1: isLight ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
         qb2: isLight ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
         qb3: isLight ? const Color(0xFF333333) : const Color(0xFFD5D5D5),
         qb4: isLight ? const Color(0xFF444444) : const Color(0xFFC5C5C5),
         qb5: isLight ? const Color(0xFF555555) : const Color(0xFFB5B5B5),
         qb6: isLight ? const Color(0xFF666666) : const Color(0xFFA5A5A5),
         qb7: isLight ? const Color(0xFF777777) : const Color(0xFF959595),
         qb8: isLight ? const Color(0xFF888888) : const Color(0xFF858585),
         qb9: isLight ? const Color(0xFF999999) : const Color(0xFF757575),
         qb10: isLight ? const Color(0xFFAAAAAA) : const Color(0xFF656565),
         qb11: isLight ? const Color(0xFFBBBBBB) : const Color(0xFF555555),
         qb12: isLight ? const Color(0xFFCCCCCC) : const Color(0xFF454545),
         qb13: isLight ? const Color(0xFFDDDDDD) : const Color(0xFF353535),
         qb14: bubble,
         qb144: panel,
         qb15: canvas,
         inlineCodeBackgroundColor: bubble,
         scaffoldBg: canvas,
         settingBg: panel,
         appBarBgC: canvas,
         settingItem: card,
         pagerDim: isLight ? Colors.black : Colors.white,
         textInputShadowC: const Color(0x22000000),
         textInputBorderC: isLight ? const Color(0x2A000000) : const Color(0x33FFFFFF),
         textInputBgC: card,
         sendingButtonC: accent,
         stopButtonC: Colors.black,
         generatingIndicatorC: accent,
         botMsgBg: canvas,
         userMsgBg: bubble,
       );

  const AppTheme._({
    required this.storageId,
    bool tinted = false,
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
    required this.qb0,
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
    required this.qb144,
    required this.qb15,
    required this.inlineCodeBackgroundColor,
  }) : _tintedColors = tinted;

  final String storageId;
  final bool _tintedColors;

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

  final Color qb0;
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
  final Color qb144;
  final Color qb15;

  final Color inlineCodeBackgroundColor;

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
  final EdgeInsets chatUserMsgBubblePadding = const .only(left: 12, top: 12, right: 12, bottom: 12);
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

  final double inputBarInteractionsIconSize = 18;

  ColorScheme get colorScheme {
    final brightness = isLight ? Brightness.light : Brightness.dark;
    final seeded = ColorScheme.fromSeed(
      seedColor: themePrimary,
      brightness: brightness,
    );
    if (!_tintedColors) return seeded.copyWith(primary: themePrimary);
    return seeded.copyWith(
      primary: themePrimary,
      onPrimary: isLight ? Colors.white : Colors.black,
      surface: scaffoldBg,
      onSurface: qb1,
      onSurfaceVariant: qb5,
      surfaceContainerLowest: scaffoldBg,
      surfaceContainerLow: settingBg,
      surfaceContainer: settingItem,
      surfaceContainerHigh: userMsgBg,
      surfaceContainerHighest: userMsgBg,
    );
  }

  String displayName(S s) {
    return switch (this) {
      .light => s.theme_light,
      .dim => s.theme_dim,
      .lightsOut => s.theme_lights_out,
      .paper => s.theme_paper,
      .glacier => s.theme_glacier,
      .midnight => s.theme_midnight,
      .forest => s.theme_forest,
      _ => isLight ? s.light_mode : s.dark_mode,
    };
  }

  static AppTheme? fromString(String? id) {
    for (final theme in values) {
      if (theme.storageId == id) return theme;
    }
    return null;
  }

  @override
  String toString() => storageId;
}
