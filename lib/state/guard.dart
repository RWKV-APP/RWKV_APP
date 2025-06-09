part of 'p.dart';

class _Guard {
  late final _blockedWords = qs<List<String>>([]);
}

/// Public methods
extension $Guard on _Guard {
  Future<bool> isSensitive(String text) async {
    final blockedWords = _blockedWords.q;
    if (blockedWords.isEmpty) return false;
    final res = await compute((args) {
      final (text, blockedWords) = args;
      for (final word in blockedWords) {
        final contains = text.contains(word);
        if (contains) return true;
      }
      return false;
    }, (text, blockedWords));
    return res;
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
    await _loadFilter();
  }

  FV _loadFilter() async {
    qq;

    final start = HF.milliseconds;
    final filter = await rootBundle.loadString("assets/filter.txt");
    final res = await compute((filter) async {
      final lines = filter.split("\n");
      return lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }, filter);
    final end = HF.milliseconds;
    _blockedWords.q = res;
    qqw("加载敏感词耗时: ${end - start}ms");
  }
}
