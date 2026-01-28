part of 'p.dart';

class _Font {
  // ===========================================================================
  // StateProvider
  // ===========================================================================

  /// 已加载的字体集合
  late final loadedFonts = qs<Set<String>>({});

  /// 系统字体列表缓存
  late final systemFontCache = qs<List<FontInfo>>([]);

  late final finalMonospaceFontFamily = qp((ref) {
    final preferredMonospaceFont = ref.watch(P.preference.preferredMonospaceFont);
    if (preferredMonospaceFont != null && preferredMonospaceFont.isNotEmpty && preferredMonospaceFont != 'System') {
      return preferredMonospaceFont;
    }
    return 'monospace';
  });
}

extension _$Font on _Font {
  Future<void> _init() async {}
}

extension $Font on _Font {
  Future<List<FontInfo>> getSystemFontsWithInfo({bool forceRefresh = false}) async {
    if (systemFontCache.q.isNotEmpty && !forceRefresh) {
      return systemFontCache.q;
    }

    try {
      final List<dynamic>? fontsData = await P.adapter.call<List<dynamic>>(ToNative.getSystemFonts);
      if (fontsData == null) throw Exception("Failed to get fonts data from native");
      final allFonts = fontsData.map((font) => FontInfo.fromMap(font as Map<dynamic, dynamic>)).toList();

      // 过滤掉名称相同的字体，保留第一个出现的
      final seenNames = <String>{};
      final result = <FontInfo>[];
      for (final font in allFonts) {
        if (!seenNames.contains(font.name)) {
          seenNames.add(font.name);
          result.add(font);
        }
      }

      systemFontCache.q = result;
      return result;
    } catch (e) {
      // 如果平台通道失败，返回默认字体列表（使用名称推断）
      final defaultList = getDefaultFonts()
          .map(
            (name) => FontInfo(
              name: name,
              isMonospace: inferMonospaceFromName(name),
            ),
          )
          .toList();
      systemFontCache.q = defaultList;
      return defaultList;
    }
  }

  Future<void> loadFont(String familyName, String path) async {
    if (loadedFonts.q.contains(familyName)) return;

    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('Font file not found: $path');
        return;
      }

      final bytes = await file.readAsBytes();
      final fontLoader = FontLoader(familyName);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();

      // Update state
      final newSet = Set<String>.from(loadedFonts.q);
      newSet.add(familyName);
      loadedFonts.q = newSet;
    } catch (e) {
      debugPrint('Error loading font $familyName from $path: $e');
    }
  }

  Future<void> loadFontByName(String familyName) async {
    if (loadedFonts.q.contains(familyName)) return;

    // 如果是系统默认或通用字体族，不需要加载
    if (familyName == 'System' || getDefaultFonts().contains(familyName)) return;

    try {
      // 使用缓存的字体列表，如果为空则尝试获取
      var fonts = systemFontCache.q;
      if (fonts.isEmpty) {
        fonts = await getSystemFontsWithInfo();
      }

      final font = fonts.firstWhere(
        (f) => f.name == familyName,
        orElse: () => FontInfo(name: '', isMonospace: false),
      );

      if (font.name.isNotEmpty && font.path != null) {
        await loadFont(familyName, font.path!);
      }
    } catch (e) {
      debugPrint('Error loading font by name $familyName: $e');
    }
  }

  bool inferMonospaceFromName(String fontName) {
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
        lowerName.contains('jetbrains mono') ||
        lowerName.contains('sarasa');
  }

  List<String> getDefaultFonts() {
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

  ThemeData applyFontToTheme(ThemeData baseTheme) {
    final uiFontFamily = P.preference.preferredUIFont.q;
    final monospaceFontFamily = P.preference.preferredMonospaceFont.q;

    ThemeData result = baseTheme;

    // 应用 UI 字体
    if (uiFontFamily != null && uiFontFamily.isNotEmpty && uiFontFamily != 'System') {
      result = result.copyWith(
        textTheme: result.textTheme.apply(fontFamily: uiFontFamily),
        primaryTextTheme: result.primaryTextTheme.apply(fontFamily: uiFontFamily),
        // Typography 不支持直接 apply 字体
        typography: Typography.material2018(),
      );
    }

    if (monospaceFontFamily != null && monospaceFontFamily.isNotEmpty && monospaceFontFamily != 'System') {
      result = result.copyWith(
        textTheme: result.textTheme.copyWith(
          bodySmall: result.textTheme.bodySmall?.copyWith(fontFamily: monospaceFontFamily),
        ),
      );
    }

    return result;
  }
}
