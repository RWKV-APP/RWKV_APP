import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 字体信息类
class FontInfo {
  final String name;
  final bool isMonospace;

  FontInfo({required this.name, required this.isMonospace});

  factory FontInfo.fromMap(Map<dynamic, dynamic> map) {
    return FontInfo(
      name: map['name'] as String,
      isMonospace: map['isMonospace'] as bool? ?? false,
    );
  }
}

class FontService {
  static const String _channelName = 'com.rwkvzone.chat/fonts';
  static const String _uiFontPreferenceKey = 'selected_ui_font_family';
  static const String _monospaceFontPreferenceKey = 'selected_monospace_font_family';
  static const MethodChannel _channel = MethodChannel(_channelName);

  // 获取系统字体列表（包含等宽信息）
  static Future<List<FontInfo>> getSystemFontsWithInfo() async {
    try {
      final List<dynamic> fontsData = await _channel.invokeMethod('getSystemFonts');
      return fontsData.map((font) => FontInfo.fromMap(font as Map<dynamic, dynamic>)).toList();
    } catch (e) {
      // 如果平台通道失败，返回默认字体列表（使用名称推断）
      return getDefaultFonts()
          .map(
            (name) => FontInfo(
              name: name,
              isMonospace: inferMonospaceFromName(name),
            ),
          )
          .toList();
    }
  }

  // 获取系统字体列表（仅名称，保持向后兼容）
  static Future<List<String>> getSystemFonts() async {
    try {
      final fonts = await getSystemFontsWithInfo();
      return fonts.map((f) => f.name).toList();
    } catch (e) {
      return getDefaultFonts();
    }
  }

  // 从字体名称推断是否为等宽字体（作为后备方案）
  static bool inferMonospaceFromName(String fontName) {
    final lowerName = fontName.toLowerCase();
    return lowerName.contains('mono') ||
        lowerName.contains('courier') ||
        lowerName == 'monospace' ||
        lowerName.contains('console') ||
        lowerName.contains('terminal') ||
        lowerName.contains('code') ||
        lowerName.contains('menlo') ||
        lowerName.contains('consolas') ||
        lowerName.contains('source code') ||
        lowerName.contains('fira code') ||
        lowerName.contains('jetbrains mono');
  }

  // 获取默认字体列表（用于桌面平台或平台通道失败时）
  static List<String> getDefaultFonts() {
    return [
      'System',
      'Roboto',
      'Arial',
      'Helvetica',
      'Times New Roman',
      'Courier New',
      'Verdana',
      'Georgia',
      'Palatino',
      'Garamond',
      'Bookman',
      'Comic Sans MS',
      'Trebuchet MS',
      'Arial Black',
      'Impact',
      'Lucida Console',
      'Tahoma',
      'Courier',
      'sans-serif',
      'serif',
      'monospace',
    ];
  }

  // 获取用户选择的 UI 字体
  static Future<String?> getSelectedUIFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_uiFontPreferenceKey);
    } catch (e) {
      return null;
    }
  }

  // 保存用户选择的 UI 字体
  static Future<bool> setSelectedUIFont(String? fontFamily) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (fontFamily == null || fontFamily.isEmpty || fontFamily == 'System') {
        return await prefs.remove(_uiFontPreferenceKey);
      }
      return await prefs.setString(_uiFontPreferenceKey, fontFamily);
    } catch (e) {
      return false;
    }
  }

  // 清除 UI 字体设置（恢复默认）
  static Future<bool> clearSelectedUIFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_uiFontPreferenceKey);
    } catch (e) {
      return false;
    }
  }

  // 获取用户选择的等宽字体
  static Future<String?> getSelectedMonospaceFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_monospaceFontPreferenceKey);
    } catch (e) {
      return null;
    }
  }

  // 保存用户选择的等宽字体
  static Future<bool> setSelectedMonospaceFont(String? fontFamily) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (fontFamily == null || fontFamily.isEmpty || fontFamily == 'System') {
        return await prefs.remove(_monospaceFontPreferenceKey);
      }
      return await prefs.setString(_monospaceFontPreferenceKey, fontFamily);
    } catch (e) {
      return false;
    }
  }

  // 清除等宽字体设置（恢复默认）
  static Future<bool> clearSelectedMonospaceFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_monospaceFontPreferenceKey);
    } catch (e) {
      return false;
    }
  }

  // 根据选择的字体创建ThemeData
  static ThemeData applyFontToTheme(ThemeData baseTheme, String? uiFontFamily, String? monospaceFontFamily) {
    ThemeData result = baseTheme;

    // 应用 UI 字体
    if (uiFontFamily != null && uiFontFamily.isNotEmpty && uiFontFamily != 'System') {
      result = result.copyWith(
        textTheme: result.textTheme.apply(
          fontFamily: uiFontFamily,
        ),
        primaryTextTheme: result.primaryTextTheme.apply(
          fontFamily: uiFontFamily,
        ),
        // Typography 不支持直接 apply 字体
        typography: Typography.material2018(),
      );
    }

    // 应用等宽字体（主要用于代码块等）
    if (monospaceFontFamily != null && monospaceFontFamily.isNotEmpty && monospaceFontFamily != 'System') {
      // 为代码相关的文本样式应用等宽字体
      result = result.copyWith(
        textTheme: result.textTheme.copyWith(
          bodySmall: result.textTheme.bodySmall?.copyWith(
            fontFamily: monospaceFontFamily,
          ),
        ),
      );
    }

    return result;
  }

  // 获取当前应该使用的等宽字体
  // 如果用户选择了字体，返回用户选择的字体；否则返回 'monospace'
  static String getEffectiveMonospaceFont(String? userSelectedFont) {
    if (userSelectedFont != null && userSelectedFont.isNotEmpty && userSelectedFont != 'System') {
      return userSelectedFont;
    }
    return 'monospace';
  }
}
