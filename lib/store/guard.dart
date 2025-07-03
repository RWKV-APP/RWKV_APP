part of 'p.dart';

class _Guard {
  late final _blockedWords = qs<Set<String>>({});
  late final checkingLatency = qs<int>(0);
  var _maxLength = 1;
}

/// Public methods
extension $Guard on _Guard {
  Future<bool> isSensitive(String text) async {
    if (_maxLength == 0) return false;
    // only use substring to check long words, from the end
    final index = text.length - _maxLength;
    final subString = index >= 0 ? text.substring(index) : text;
    final blockedWords = _blockedWords.q;
    if (blockedWords.isEmpty) return false;
    final start = HF.milliseconds;
    final res = await compute((args) {
      final (text, blockedWords) = args;
      for (final word in blockedWords) {
        final contains = text.contains(word);
        if (contains) qqw(word);
        if (contains) return true;
      }
      return false;
    }, (subString, blockedWords));
    final end = HF.milliseconds;
    checkingLatency.q = end - start;
    return res;
  }

  bool isSensitiveSync(String text) {
    final blockedWords = _blockedWords.q;
    if (blockedWords.isEmpty) return false;
    for (final word in blockedWords) {
      final contains = text.contains(word);
      if (contains) qqw(word);
      if (contains) return true;
    }
    return false;
  }
}

/// Private methods
extension _$Guard on _Guard {
  FV _init() async {
    switch (P.app.demoType.q) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        return;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
    }
    qq;
    try {
      await _loadFilter();
    } catch (_) {
      qqw('sensitive words load failed');
    }
  }

  FV _loadFilter() async {
    qq;

    final start = HF.milliseconds;
    final filter = await rootBundle.loadString("assets/filter.txt");
    final (res, maxLength) = await compute((filter) async {
      final lines = filter.split("\n");
      final words = lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
      if (words.isEmpty) return (words, 0);
      final maxLength = words.map((e) => e.length).reduce((a, b) => a > b ? a : b);
      return (words, maxLength);
    }, filter);
    final end = HF.milliseconds;
    _maxLength = maxLength;
    _blockedWords.q = res;
    qqw("加载敏感词耗时: ${end - start}ms, 最大长度: $_maxLength");
  }
}
