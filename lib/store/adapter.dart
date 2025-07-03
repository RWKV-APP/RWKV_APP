part of 'p.dart';

class _Adapter {
  late final _channel = const MethodChannel("channel");

  final Map<FromNative, List<void Function(dynamic arguments)>> _registry = {};
}

/// Public methods
extension $Adapter on _Adapter {
  Future<T?> call<T>(ToNative toNative, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod<T>(toNative.name, arguments);
    } catch (e) {
      qqe("$e");
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
      return null;
    }
  }

  FV _onCall(MethodCall call) async {
    final method = FromNative.values.byName(call.method);
    if (kDebugMode && !_registry.containsKey(method)) {
      qqw("Engine: HUD: Native calling received but there is no listener in adapter");
      qqw("`$method` is the name of method");
      return;
    }

    final list = _registry[method] ?? [];
    if (list.isEmpty) return;
    for (var function in list) {
      final arguments = call.arguments;
      function(arguments);
    }
  }

  void register(FromNative fromNative, void Function(dynamic arguments) f) {
    final list = _registry[fromNative];
    if (list == null) {
      _registry[fromNative] = [f];
      return;
    }
    list.add(f);
  }
}

/// Private methods
extension _$Adapter on _Adapter {
  FV _init() async {
    _channel.setMethodCallHandler(_onCall);
  }
}
