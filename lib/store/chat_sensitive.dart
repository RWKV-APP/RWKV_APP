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
