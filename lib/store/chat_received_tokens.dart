part of 'p.dart';

const Duration _visibleReceivedTokensInterval = Duration(milliseconds: 33);

extension $ChatReceivedTokens on _Chat {
  void _setReceivedTokens(String value, {bool immediateUi = false}) {
    receivedTokens.q = value;
    _latestVisibleReceivedTokens = value;
    if (immediateUi) {
      _flushVisibleReceivedTokens();
      return;
    }
    if (_visibleReceivedTokensTimer != null) return;
    _visibleReceivedTokensTimer = Timer(_visibleReceivedTokensInterval, _flushVisibleReceivedTokens);
  }

  void _flushVisibleReceivedTokens() {
    _visibleReceivedTokensTimer?.cancel();
    _visibleReceivedTokensTimer = null;
    final value = _latestVisibleReceivedTokens;
    if (visibleReceivedTokens.q == value) return;
    visibleReceivedTokens.q = value;
  }
}
