part of 'p.dart';

final rc = ProviderContainer();

StateProvider<V> qs<V>(V v) => StateProvider<V>((_) => v);

Provider<V> qp<V>(V Function(Ref<V> ref) createFn) => Provider<V>(createFn);

StateProviderFamily<V, K> qsf<K, V>(V v) => StateProvider.family<V, K>((_, _) => v);

StateProviderFamily<V, K> qsff<K, V>(V Function(Ref<V> ref, K arg) createFn) => StateProvider.family<V, K>(createFn);

extension RiverpodProviderListenableX<V> on ProviderListenable<V> {
  V get q => rc.read(this);

  void l(void Function(V next) listener, {bool fireImmediately = false}) {
    rc.listen(this, (_, V next) => listener(next), fireImmediately: fireImmediately);
  }

  void lv(void Function() listener, {bool fireImmediately = false}) {
    rc.listen(this, (_, _) => listener(), fireImmediately: fireImmediately);
  }

  void lb(void Function(V? previous, V next) listener, {bool fireImmediately = false}) {
    rc.listen(this, (previous, next) => listener(previous, next), fireImmediately: fireImmediately);
  }
}

extension RiverpodStateProviderX<V> on StateProvider<V> {
  V get q => rc.read(this);

  set q(V value) {
    rc.read(notifier).state = value;
  }
}

extension RiverpodNullableStateProviderX<V> on StateProvider<V?> {
  void uc() {
    q = null;
  }
}

class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(container: rc, child: child);
  }
}

abstract class RawApp with WidgetsBindingObserver {
  final version = qs("");
  final buildNumber = qs("");

  final isPortrait = qs(true);

  final screenHeight = qs(0.0);
  final screenWidth = qs(0.0);

  late final systemBrightness = qp((ref) {
    return ref.watch(_systemBrightness);
  });

  late final light = qp((ref) {
    final preferredThemeMode = ref.watch(this.preferredThemeMode);
    if (preferredThemeMode == ThemeMode.light) return true;
    if (preferredThemeMode == ThemeMode.dark) return false;
    return ref.watch(systemBrightness) == Brightness.light;
  });

  late final dark = qp((ref) {
    return !ref.watch(light);
  });

  final qw = qs(const Color(0xFFFFFFFF));
  final qb = qs(const Color(0xFF000000));

  late final lifecycleState = qp((ref) {
    return ref.watch(_lifecycleState);
  });
  final _lifecycleState = qs(AppLifecycleState.resumed);

  final preferredThemeMode = qs(ThemeMode.system);
  final _systemBrightness = qs(Brightness.light);

  final paddingBottom = qs(0.0);
  final paddingLeft = qs(0.0);
  final paddingRight = qs(0.0);
  final paddingTop = qs(0.0);
  final viewInsetBottomIsZero = qs(false);
  final viewInsetsBottom = qs(0.0);
  final viewInsetsLeft = qs(0.0);
  final viewInsetsRight = qs(0.0);
  final viewInsetsTop = qs(0.0);
  final viewPaddingBottom = qs(0.0);
  final viewPaddingLeft = qs(0.0);
  final viewPaddingRight = qs(0.0);
  final viewPaddingTop = qs(0.0);

  final quantized33PaddingBottom = qs(0.0);
  final quantizedHalfPaddingBottom = qs(0.0);
  final quantizedQuarterPaddingBottom = qs(0.0);
  final quantizedIntPaddingBottom = qs(0.0);

  late final cacheDir = qs<Directory?>(null);
  late final documentsDir = qs<Directory?>(null);
  late final downloadsDir = qs<Directory?>(null);
  late final libraryDir = qs<Directory?>(null);
  late final supportDir = qs<Directory?>(null);
  late final tempDir = qs<Directory?>(null);

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows) registerWindowsExitHandler();

    final packageInfo = await PackageInfo.fromPlatform();
    version.q = packageInfo.version;
    buildNumber.q = packageInfo.buildNumber;

    if (kDebugMode) {
      Future.delayed(const Duration(seconds: 1), () {
        final context = this.context;
        if (context == null) return;
        if (context.mounted) FocusScope.of(context).unfocus();
      });
    }

    light.lv(_onLightChanged);

    await _syncAllDir();
  }

  void registerWindowsExitHandler() {
    const BasicMessageChannel<Object?>('com.rwkvzone.chat/lifecycle', StandardMessageCodec()).setMessageHandler((message) async {
      if (message != 'requestAppExit') return ui.AppExitResponse.cancel.name;
      return (await WidgetsBinding.instance.handleRequestAppExit()).name;
    });
  }

  void _onLightChanged() {
    final isLight = light.q;
    qw.q = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    qb.q = isLight ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  Future<void> _syncAllDir() async {
    final results = await Future.wait<Directory?>([
      _getAppDirectory(() async => getApplicationCacheDirectory(), mark: "cacheDir"),
      _getAppDirectory(() async => getApplicationDocumentsDirectory(), mark: "documentsDir"),
      _getAppDirectory(() async => getDownloadsDirectory(), mark: "downloadsDir"),
      Platform.isIOS || Platform.isMacOS
          ? _getAppDirectory(() async => getLibraryDirectory(), mark: "libraryDir")
          : Future<Directory?>.value(null),
      _getAppDirectory(() async => getApplicationSupportDirectory(), mark: "supportDir"),
      _getAppDirectory(() async => getTemporaryDirectory(), mark: "tempDir"),
    ]);

    cacheDir.q = results[0];
    documentsDir.q = results[1];
    downloadsDir.q = results[2];
    if (Platform.isIOS || Platform.isMacOS) {
      libraryDir.q = results[3];
    }
    supportDir.q = results[4];
    tempDir.q = results[5];
  }

  Future<Directory?> _getAppDirectory(Future<Directory?> Function() createFn, {required String mark}) async {
    try {
      return await createFn();
    } catch (e) {
      if (kDebugMode) print("RawApp.init");
      if (kDebugMode) print("warning $mark $e");
      return null;
    }
  }

  Future<void> firstContextGot(BuildContext context) async {
    await Future.delayed(Duration.zero);
    // ignore: use_build_context_synchronously
    _contextGot(context);
  }

  void _contextGot(BuildContext? context) {
    if (context == null) return;
    if (!context.mounted) return;

    final window = View.of(context);
    final dpi = window.devicePixelRatio;
    final rawViewPadding = window.viewPadding;
    final rawViewInsets = window.viewInsets;
    final rawPadding = window.padding;

    final size = window.physicalSize / dpi;
    final height = _roundToDecimalPlaceOptimized(window.physicalSize.height / dpi, 2);
    final width = _roundToDecimalPlaceOptimized(window.physicalSize.width / dpi, 2);
    final isPortrait = height > width;

    final paddingTop = _roundToDecimalPlaceOptimized(rawPadding.top / dpi, 2);
    final paddingBottom = _roundToDecimalPlaceOptimized(rawPadding.bottom / dpi, 2);
    final paddingLeft = _roundToDecimalPlaceOptimized(rawPadding.left / dpi, 2);
    final paddingRight = _roundToDecimalPlaceOptimized(rawPadding.right / dpi, 2);

    this.paddingTop.q = paddingTop;
    this.paddingBottom.q = paddingBottom;
    this.paddingLeft.q = paddingLeft;
    this.paddingRight.q = paddingRight;

    quantized33PaddingBottom.q = (paddingBottom / 0.3333).round() * 0.3333;
    quantizedHalfPaddingBottom.q = (paddingBottom / 0.5).round() * 0.5;
    quantizedQuarterPaddingBottom.q = (paddingBottom / 0.25).round() * 0.25;
    quantizedIntPaddingBottom.q = paddingBottom.round().toDouble();

    screenWidth.q = size.width;
    screenHeight.q = size.height;

    final viewPaddingTop = _roundToDecimalPlaceOptimized(rawViewPadding.top / dpi, 2);
    final viewPaddingBottom = _roundToDecimalPlaceOptimized(rawViewPadding.bottom / dpi, 2);
    final viewPaddingLeft = _roundToDecimalPlaceOptimized(rawViewPadding.left / dpi, 2);
    final viewPaddingRight = _roundToDecimalPlaceOptimized(rawViewPadding.right / dpi, 2);

    this.viewPaddingTop.q = viewPaddingTop;
    this.viewPaddingBottom.q = viewPaddingBottom;
    this.viewPaddingLeft.q = viewPaddingLeft;
    this.viewPaddingRight.q = viewPaddingRight;

    final viewInsetsTop = _roundToDecimalPlaceOptimized(rawViewInsets.top / dpi, 2);
    final viewInsetsBottom = _roundToDecimalPlaceOptimized(rawViewInsets.bottom / dpi, 2);
    final viewInsetsLeft = _roundToDecimalPlaceOptimized(rawViewInsets.left / dpi, 2);
    final viewInsetsRight = _roundToDecimalPlaceOptimized(rawViewInsets.right / dpi, 2);

    viewInsetBottomIsZero.q = viewInsetsBottom == 0;

    this.viewInsetsTop.q = viewInsetsTop;
    this.viewInsetsBottom.q = viewInsetsBottom;
    this.viewInsetsLeft.q = viewInsetsLeft;
    this.viewInsetsRight.q = viewInsetsRight;

    final brightness = View.of(context).platformDispatcher.platformBrightness;
    _systemBrightness.q = brightness;

    _onLightChanged();

    this.isPortrait.q = isPortrait;
  }

  BuildContext? get context;

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _contextGot(context);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _contextGot(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lifecycleState.q = state;
  }
}

double _roundToDecimalPlaceOptimized(double value, int decimalPlaces) {
  final factor = math.pow(10, decimalPlaces).toDouble();
  return (value * factor).round() / factor;
}
