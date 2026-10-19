part of 'p.dart';

class _Adapter {
  // ===========================================================================
  // Instance
  // ===========================================================================

  late final _channel = const MethodChannel("channel");
  bool? _inferenceActivityApplied;
  bool _inferenceActivitySyncing = false;

  late final _inferenceActive = qp((ref) {
    final generating = ref.watch(P.rwkvGeneration.generating);
    final loading = ref.watch(P.rwkvModel.loading);
    final preparingChat = ref.watch(P.rwkvModel._chatLoadsInProgress) > 0;
    return generating || loading || preparingChat;
  });

  final Map<FromNative, List<void Function(dynamic arguments)>> _registry = {};
}

/// Public methods
extension $Adapter on _Adapter {
  Future<ResultT?> call<ResultT>(ToNative toNative, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod<ResultT>(toNative.name, arguments);
    } catch (e) {
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<ResultT?> callStrict<ResultT>(ToNative toNative, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod<ResultT>(toNative.name, arguments);
    } catch (e, st) {
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: st);
      }
      rethrow;
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
    if (Platform.isMacOS) {
      _inferenceActive.lv(_syncInferenceActivity, fireImmediately: true);
    }
  }

  Future<void> _syncInferenceActivity() async {
    if (_inferenceActivitySyncing) return;
    _inferenceActivitySyncing = true;
    try {
      while (true) {
        final active = _inferenceActive.q;
        if (_inferenceActivityApplied == active) return;
        await _channel.invokeMethod<void>(ToNative.setInferenceActive.name, active);
        _inferenceActivityApplied = active;
      }
    } catch (e) {
      qqw("Failed to update macOS inference activity: $e");
    } finally {
      _inferenceActivitySyncing = false;
    }
  }
}
