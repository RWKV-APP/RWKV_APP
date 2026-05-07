part of 'p.dart';

class _RWKVDebug {
  late final argumentsPanelShown = qs(false);
  late final logPanelShown = qs(false);
  late final statePanelShown = qs(false);
  late final renderNewlineDirectly = qs(false);
  late final renderSpaceSymbol = qs(false);
  late final showPrefillLogOnly = qs(true);

  late final runtimeLog = qs<List<LogItem>>([]);
  late final stateLogList = qs<List<StateLog>>([]);
}

extension $RWKVDebug on _RWKVDebug {
  Future<void> refreshRuntimeLog() async {
    P.rwkvBridge.send(to_rwkv.DumpLog());
  }

  Future<void> refreshStatePanel() async {
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID != null) P.rwkvBridge.send(to_rwkv.DumpStateInfo(modelID: modelID));
  }

  Future<void> setRenderNewlineDirectly(bool value) async {
    if (renderNewlineDirectly.q == value) {
      return;
    }

    renderNewlineDirectly.q = value;
    await P.preference.saveDebugRenderNewlineDirectly(value);
  }

  Future<void> toggleRenderNewlineDirectly() async {
    await setRenderNewlineDirectly(!renderNewlineDirectly.q);
  }

  Future<void> setRenderSpaceSymbol(bool value) async {
    if (renderSpaceSymbol.q == value) {
      return;
    }

    renderSpaceSymbol.q = value;
    await P.preference.saveDebugRenderSpaceSymbol(value);
  }

  Future<void> toggleRenderSpaceSymbol() async {
    await setRenderSpaceSymbol(!renderSpaceSymbol.q);
  }

  Future<void> setShowPrefillLogOnly(bool value) async {
    if (showPrefillLogOnly.q == value) {
      return;
    }

    showPrefillLogOnly.q = value;
    await P.preference.saveDebugShowPrefillLogOnly(value);
  }

  Future<void> toggleShowPrefillLogOnly() async {
    await setShowPrefillLogOnly(!showPrefillLogOnly.q);
  }

  /// 解析运行时日志，按 [INFO]、[DEBUG]、[WARN] 等标签分割
  List<LogItem> _parseRuntimeLog(String runtimeLog) {
    if (runtimeLog.isEmpty) return [];

    final logItems = <LogItem>[];
    final regex = RegExp(r'\[(INFO|DEBUG|WARN|ERROR|TRACE|FATAL)\]');
    final matches = regex.allMatches(runtimeLog);
    final timeRegex = RegExp(r'\[\d{4}-\d{2}-\d{2} (\d{2}:\d{2}:\d{2}\.\d+)\]');
    final dateRegex = RegExp(r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+\]');

    for (int i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);
      final tag = match.group(1) ?? 'UNKNOWN';

      // 获取当前标签到下一个标签之间的内容
      final start = match.end;
      final end = i + 1 < matches.length ? matches.elementAt(i + 1).start : runtimeLog.length;

      String content = runtimeLog.substring(start, end).trim();
      final timeDisplayString = timeRegex.firstMatch(content)?.group(1) ?? "";
      final dateDisplayString = dateRegex.firstMatch(content)?.group(0) ?? "";
      content = content.replaceAll(dateDisplayString, "");
      final isPrefill = content.startsWith("new text to prefill");

      if (content.isNotEmpty) {
        logItems.add(
          LogItem(
            tag: tag,
            content: content.trim(),
            isPrefill: isPrefill,
            dateTimeString: timeDisplayString.trim(),
          ),
        );
      }
    }

    return logItems;
  }
}
