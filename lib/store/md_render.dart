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

  late final codeFontFamilyFallback = [
    'Menlo', // iOS, macOS
    'Roboto Mono', // Android
    'Consolas', // Windows
    'DejaVu Sans Mono', // Linux
    'Courier New', // Fallback
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
    if (language.trim() == "") return true;
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

  String normalizeLatexForMarkdown(String raw) {
    final normalizedRaw = raw.replaceAll("\r\n", "\n");
    if (normalizedRaw.trim().isEmpty) return normalizedRaw;

    final lines = normalizedRaw.split("\n");
    final output = <String>[];
    final pendingMathLines = <String>[];
    bool insideFence = false;
    int displayBalance = 0;
    int inlineBalance = 0;

    void flushPendingMathLines() {
      if (pendingMathLines.isEmpty) return;
      output.add(r"\[");
      output.addAll(pendingMathLines);
      output.add(r"\]");
      pendingMathLines.clear();
    }

    for (final String line in lines) {
      final trimmedLine = line.trim();

      if (_isCodeFenceLine(trimmedLine)) {
        flushPendingMathLines();
        insideFence = !insideFence;
        output.add(line);
        continue;
      }

      if (insideFence) {
        output.add(line);
        continue;
      }

      if (displayBalance == 0 && inlineBalance == 0 && _shouldWrapBareLatexLine(trimmedLine)) {
        pendingMathLines.add(trimmedLine);
        continue;
      }

      flushPendingMathLines();
      output.add(line);

      displayBalance = _nextLatexBalance(
        currentBalance: displayBalance,
        line: line,
        openExp: RegExp(r'(?<!\\)\\\['),
        closeExp: RegExp(r'(?<!\\)\\\]'),
      );

      if (displayBalance > 0) continue;

      inlineBalance = _nextLatexBalance(
        currentBalance: inlineBalance,
        line: line,
        openExp: RegExp(r'(?<!\\)\\\('),
        closeExp: RegExp(r'(?<!\\)\\\)'),
      );
    }

    flushPendingMathLines();

    String result = output.join("\n");
    if (displayBalance > 0) {
      final closingBlock = List<String>.filled(displayBalance, r"\]").join("\n");
      if (result.isNotEmpty && !result.endsWith("\n")) {
        result = "$result\n$closingBlock";
      } else {
        result = "$result$closingBlock";
      }
    }

    if (inlineBalance > 0) {
      final closingInline = List<String>.filled(inlineBalance, r"\)").join();
      result = "$result$closingInline";
    }

    return result;
  }

  int _nextLatexBalance({
    required int currentBalance,
    required String line,
    required RegExp openExp,
    required RegExp closeExp,
  }) {
    final opens = openExp.allMatches(line).length;
    final closes = closeExp.allMatches(line).length;
    final nextBalance = currentBalance + opens - closes;
    if (nextBalance < 0) return 0;
    return nextBalance;
  }

  bool _isCodeFenceLine(String line) {
    if (line.isEmpty) return false;
    return RegExp(r"^(```|~~~)").hasMatch(line);
  }

  bool _shouldWrapBareLatexLine(String line) {
    if (line.isEmpty) return false;
    if (_isMarkdownLine(line)) return false;
    if (line.contains("`")) return false;
    if (_hasLatexDelimiter(line)) return false;
    if (RegExp(r"[\u3400-\u9FFF]").hasMatch(line)) return false;

    final hasLatexCommand = RegExp(r"\\[A-Za-z]+").hasMatch(line);
    final hasSuperscriptOrSubscript = line.contains("^") || line.contains("_");
    final hasEquationSignal = RegExp(r"[=+\-*/<>]").hasMatch(line);
    final hasGrouping = RegExp(r"[{}()\[\]]").hasMatch(line);
    final score =
        (hasLatexCommand ? 2 : 0) +
        (hasSuperscriptOrSubscript ? 2 : 0) +
        (hasEquationSignal ? 1 : 0) +
        (hasGrouping ? 1 : 0) +
        (line.contains("&") ? 1 : 0);

    if (!hasLatexCommand && !(hasSuperscriptOrSubscript && hasEquationSignal)) return false;

    return score >= 3;
  }

  bool _hasLatexDelimiter(String line) {
    if (RegExp(r'(?<!\\)\\\[').hasMatch(line)) return true;
    if (RegExp(r'(?<!\\)\\\]').hasMatch(line)) return true;
    if (RegExp(r'(?<!\\)\\\(').hasMatch(line)) return true;
    if (RegExp(r'(?<!\\)\\\)').hasMatch(line)) return true;
    if (RegExp(r'(?<!\\)\$\$').hasMatch(line)) return true;
    return RegExp(r'(?<!\\)\$').hasMatch(line);
  }

  bool _isMarkdownLine(String line) {
    if (line.startsWith("#")) return true;
    if (line.startsWith(">")) return true;
    if (line.startsWith("|")) return true;
    if (line.startsWith("- ")) return true;
    if (line.startsWith("* ")) return true;
    if (line.startsWith("+ ")) return true;
    if (RegExp(r"^\d+\.\s").hasMatch(line)) return true;
    return false;
  }
}
