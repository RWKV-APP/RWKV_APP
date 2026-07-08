part of 'p.dart';

class _Guard {
  // ===========================================================================
  // Instance
  // ===========================================================================

  int _maxLength = 1;

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final _blockedRules = qs<SensitiveFilterRules>(emptySensitiveFilterRules);
  late final checkingLatency = qs<int>(0);
}

/// Public methods
extension $Guard on _Guard {
  Future<bool> isSensitive(String text) async {
    if (_maxLength == 0) return false;
    final rules = _blockedRules.q;
    if (isSensitiveFilterRulesEmpty(rules)) return false;
    final start = DateTime.now().millisecondsSinceEpoch;
    final matchedRule = findSensitiveFilterMatchInWindows(
      (
        index: rules.index,
        maxLength: _maxLength,
        text: text,
      ),
    );
    if (matchedRule != null) qqw(matchedRule);
    final end = DateTime.now().millisecondsSinceEpoch;
    checkingLatency.q = end - start;
    return matchedRule != null;
  }

  bool isSensitiveSync(String text) {
    final rules = _blockedRules.q;
    if (isSensitiveFilterRulesEmpty(rules)) return false;
    final matchedRule = findSensitiveFilterMatchInWindows(
      (
        index: rules.index,
        maxLength: _maxLength,
        text: text,
      ),
    );
    if (matchedRule == null) return false;
    qqw(matchedRule);
    return true;
  }
}

/// Private methods
extension _$Guard on _Guard {
  Future<void> _init() async {
    switch (P.app.demoType.q) {
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
        return;
      case .chat:
      case .tts:
      case .see:
    }
    qq;
    try {
      await _loadFilter();
    } catch (_) {
      qqw('sensitive words load failed');
    }
  }

  Future<void> _loadFilter() async {
    qq;

    final start = DateTime.now().millisecondsSinceEpoch;
    final filter = await rootBundle.loadString("assets/filter.txt");
    final rules = await compute(parseSensitiveFilterRules, filter);
    final end = DateTime.now().millisecondsSinceEpoch;
    _maxLength = rules.maxLength;
    _blockedRules.q = rules;
    qqw("加载敏感词耗时: ${end - start}ms, 最大长度: $_maxLength");
  }
}
