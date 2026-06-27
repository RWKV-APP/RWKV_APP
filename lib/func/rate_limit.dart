import 'dart:async';

class Debouncer {
  final int milliseconds;
  void Function()? _action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void call(void Function() action) {
    final duration = Duration(milliseconds: milliseconds);
    _timer?.cancel();
    _action = action;
    _timer = Timer(duration, () {
      _action?.call();
    });
  }
}

class Throttler {
  final int milliseconds;
  final bool trailing;
  Function? _pendingCall;
  Timer? _timer;
  bool _isReady = true;

  Throttler({required this.milliseconds, this.trailing = false});

  Throttler.duration(Duration duration, {this.trailing = false}) : milliseconds = duration.inMilliseconds;

  void call(Function action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(Duration(milliseconds: milliseconds), _onTimerComplete);
      return;
    }
    if (!trailing) return;
    _pendingCall = action;
  }

  void _onTimerComplete() {
    _isReady = true;
    if (!trailing) return;
    if (_pendingCall == null) return;
    final pendingCall = _pendingCall;
    _pendingCall = null;
    _isReady = false;
    pendingCall!();
    _timer = Timer(Duration(milliseconds: milliseconds), _onTimerComplete);
  }

  void cancel() {
    _timer?.cancel();
    _pendingCall = null;
    _isReady = true;
  }
}
