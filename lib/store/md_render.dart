part of 'p.dart';

class _MDRender {
  static const supportedCodeLanguages = [
    "css",
    "dart",
    "go",
    "html",
    "java",
    "javascript",
    "json",
    "kotlin",
    "python",
    "rust",
    "serverpod_protocol",
    "sql",
    "swift",
    "typescript",
    "yaml",
  ];

  late final defaultCodeLanguage = "python";

  late final highlighters = qsf<String, Highlighter?>(null);
  late final darkHighlighters = qsf<String, Highlighter?>(null);

  late final _darkTheme = qs<HighlighterTheme?>(null);
  late final _lightTheme = qs<HighlighterTheme?>(null);
}

/// Private methods
extension _$MDRender on _MDRender {
  Future<void> _init() async {
    _initHighlighters();
  }

  Future<void> _initHighlighters() async {
    await Highlighter.initialize([]);

    _lightTheme.q = await HighlighterTheme.loadLightTheme();
    _darkTheme.q = await HighlighterTheme.loadDarkTheme();

    final loaded = await tryToLoadLanguageHighlighter(defaultCodeLanguage);
    if (!loaded) {
      qqe("Failed to load default code language highlighter: $defaultCodeLanguage");
      return;
    }
  }
}

/// Public methods
extension $MDRender on _MDRender {
  Future<bool> tryToLoadLanguageHighlighter(String language) async {
    final contains = _MDRender.supportedCodeLanguages.contains(language);
    if (!contains) {
      qqw("Language $language is not supported");
      return false;
    }
    final grammarFileContent = await rootBundle.loadString(
      "assets/config/code_highlights/$language.json",
    );
    Highlighter.addLanguage(language, grammarFileContent);
    highlighters(language).q = Highlighter(language: language, theme: _lightTheme.q!);
    darkHighlighters(language).q = Highlighter(language: language, theme: _darkTheme.q!);
    return true;
  }
}
