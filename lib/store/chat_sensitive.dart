part of 'p.dart';

extension $ChatSensitive on _Chat {
  Future<void> _checkSensitive(String content) async {
    final id = receiveId.q;
    if (!_shouldCheckSensitiveForReceiveId(id)) return;

    _pendingSensitiveContent = content;
    _pendingSensitiveReceiveId = id;
    if (_sensitiveCheckRunning) return;

    unawaited(_drainSensitiveChecks());
  }

  bool _shouldCheckSensitiveForReceiveId(int? id) {
    if (id == null) return false;
    if (id == Config.chatPrefillId) return false;
    if (id == Config.seePrefillId) return false;
    return true;
  }

  List<String> _filterSensitiveBatchContents({
    required List<String> contents,
    required int? messageId,
  }) {
    if (!_shouldCheckSensitiveForReceiveId(messageId)) return contents;
    if (contents.isEmpty) return contents;

    if (_sensitiveBatchReceiveId != messageId) {
      _sensitiveBatchReceiveId = messageId;
      _sensitiveBatchSlotIndexes = const <int>{};
      _sensitiveBatchLastCheckedContents = <int, String>{};
    }

    final result = filterSensitiveBatchContents(
      contents: contents,
      isSensitive: (int index, String content) {
        if (_sensitiveBatchLastCheckedContents[index] == content) return false;
        _sensitiveBatchLastCheckedContents[index] = content;
        return P.guard.isSensitiveSync(content);
      },
      replacement: S.current.filter,
      sensitiveIndexes: _sensitiveBatchSlotIndexes,
    );
    _sensitiveBatchSlotIndexes = result.sensitiveIndexes;
    for (final index in result.sensitiveIndexes) {
      _sensitiveBatchLastCheckedContents.remove(index);
    }
    return result.contents;
  }

  Future<void> _drainSensitiveChecks() async {
    _sensitiveCheckRunning = true;
    try {
      while (_pendingSensitiveContent != null) {
        final content = _pendingSensitiveContent;
        final id = _pendingSensitiveReceiveId;
        _pendingSensitiveContent = null;
        _pendingSensitiveReceiveId = null;
        if (content == null) continue;
        if (!_shouldCheckSensitiveForReceiveId(id)) continue;

        final isSensitive = await P.guard.isSensitive(content);
        if (!isSensitive) continue;
        if (receiveId.q != id) continue;

        await 1.msLater;
        if (receiveId.q != id) continue;

        _pendingSensitiveContent = null;
        _pendingSensitiveReceiveId = null;
        _pauseMessageById(id: id!, isSensitive: true);
        return;
      }
    } finally {
      _sensitiveCheckRunning = false;
    }
  }
}
