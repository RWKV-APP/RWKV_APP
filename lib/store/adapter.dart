part of 'p.dart';

class _Adapter {
  // ===========================================================================
  // Instance
  // ===========================================================================

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

  /// Android SoC 检测
  ///
  /// - 仅在 Android 上生效，其它平台直接返回 null
  /// - Native 侧返回形如:
  ///   { "socName": "sm8550", "socBrand": "snapdragon" }
  Future<(String, SocBrand)?> detectSocInfo() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod<dynamic>(ToNative.detectSocInfo.name);
      if (result is! Map) return null;

      final rawName = result["socName"]?.toString() ?? "";
      final rawBrand = result["socBrand"]?.toString() ?? "";

      final name = rawName.trim();
      final brandString = rawBrand.trim();

      if (name.isEmpty && brandString.isEmpty) return null;

      final brand = SocBrand.fromString(brandString.isEmpty ? "unknown" : brandString);
      return (name, brand);
    } catch (e, st) {
      qqe("$e");
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: st);
      }
      return null;
    }
  }

  Future<void> _onCall(MethodCall call) async {
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
  Future<void> _init() async {
    _channel.setMethodCallHandler(_onCall);
  }
}
