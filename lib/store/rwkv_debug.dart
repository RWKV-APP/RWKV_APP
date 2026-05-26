part of 'p.dart';

class _RWKVDebug {
  late final argumentsPanelShown = qs(false);
  late final logPanelShown = qs(false);
  late final statePanelShown = qs(false);
  late final renderNewlineDirectly = qs(false);
  late final renderSpaceSymbol = qs(false);
  late final showPrefillLogOnly = qs(true);

  late final rawRuntimeLog = qs("");
  late final rawStateInfo = qs("");
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

  Future<void> exportDebugPanelsToTxt() async {
    final s = S.current;

    try {
      final runtimeLogText = await _requestLatestRawRuntimeLog();
      final stateInfoText = await _requestLatestRawStateInfo();
      if (!hasDebugPanelsExportData(runtimeLog: runtimeLogText, stateInfo: stateInfoText)) {
        Alert.warning(s.no_data);
        return;
      }

      final content = buildDebugPanelsExportContent(
        runtimeLogTitle: s.runtime_log_panel,
        statePanelTitle: s.state_panel,
        runtimeLog: runtimeLogText,
        stateInfo: stateInfoText,
      );
      final file = await _writeDebugPanelsExportFile(content);
      final xFile = XFile(file.path, mimeType: 'text/plain');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: basename(file.path),
          title: s.export_debug_panels_to_txt,
        ),
      );
    } catch (e, stackTrace) {
      qqe("Export debug panels failed: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
      Alert.error(s.export_failed);
    }
  }

  Future<String> _requestLatestRawRuntimeLog() async {
    if (P.rwkvBridge.sendPort == null) {
      return rawRuntimeLog.q;
    }

    final request = to_rwkv.DumpLog();
    final responseFuture = P.rwkvBridge.broadcastStream
        .whereType<from_rwkv.RuntimeLog>()
        .where((from_rwkv.RuntimeLog event) => event.req?.requestId == request.requestId)
        .first
        .timeout(const Duration(seconds: 3));
    P.rwkvBridge.send(request);

    try {
      final response = await responseFuture;
      return response.runtimeLog;
    } catch (_) {
      return rawRuntimeLog.q;
    }
  }

  Future<String> _requestLatestRawStateInfo() async {
    if (P.rwkvBridge.sendPort == null) {
      return "";
    }

    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return "";
    }

    final request = to_rwkv.DumpStateInfo(modelID: modelID);
    final responseFuture = P.rwkvBridge.broadcastStream
        .whereType<from_rwkv.StateInfo>()
        .where((from_rwkv.StateInfo event) => event.req?.requestId == request.requestId)
        .first
        .timeout(const Duration(seconds: 3));
    P.rwkvBridge.send(request);

    try {
      final response = await responseFuture;
      return response.stateInfo;
    } catch (_) {
      return rawStateInfo.q;
    }
  }

  Future<File> _writeDebugPanelsExportFile(String content) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = buildDebugPanelsExportFileName(now: DateTime.now());
    final file = File(join(tempDir.path, fileName));
    await file.writeAsString(content, encoding: utf8);
    return file;
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

bool hasDebugPanelsExportData({
  required String runtimeLog,
  required String stateInfo,
}) {
  return runtimeLog.trim().isNotEmpty || stateInfo.trim().isNotEmpty;
}

String buildDebugPanelsExportContent({
  required String runtimeLogTitle,
  required String statePanelTitle,
  required String runtimeLog,
  required String stateInfo,
}) {
  final buffer = StringBuffer()
    ..writeln('===== $runtimeLogTitle =====')
    ..writeln()
    ..write(runtimeLog);
  if (runtimeLog.isNotEmpty && !runtimeLog.endsWith('\n')) {
    buffer.writeln();
  }

  buffer
    ..writeln()
    ..writeln('===== $statePanelTitle =====')
    ..writeln()
    ..write(stateInfo);
  if (stateInfo.isNotEmpty && !stateInfo.endsWith('\n')) {
    buffer.writeln();
  }

  return buffer.toString();
}

String buildDebugPanelsExportFileName({required DateTime now}) {
  return 'rwkv_debug_panels_${_formatDebugPanelsExportTimestamp(now)}.txt';
}

String _formatDebugPanelsExportTimestamp(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');
  return '$year$month${day}_$hour$minute$second';
}
