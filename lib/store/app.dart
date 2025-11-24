part of 'p.dart';

class _App extends RawApp {
  // ===========================================================================
  // Instance
  // ===========================================================================

  late final db.AppDatabase _db;

  DownloadTask? _appUpdateTask;

  // ===========================================================================
  // Getters
  // ===========================================================================

  SystemUiOverlayStyle get systemOverlayStyleLight {
    final scaffold = customTheme.q.scaffold;
    return SystemUiOverlayStyle(
      systemNavigationBarColor: scaffold,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );
  }

  SystemUiOverlayStyle get systemOverlayStyleDark {
    final scaffold = customTheme.q.scaffold;
    return SystemUiOverlayStyle(
      systemNavigationBarColor: scaffold,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
  }

  String get _configForAllDemosKey => "configForAllDemosKey_${buildNumber.q}";

  @override
  BuildContext? get context => getContext();

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  final _pageKey = qs(PageKey.first);

  /// 当前正在运行的任务
  late final demoType = qs(DemoType.chat);

  late final _latestBuild = qs(-1);
  late final _latestBuildIos = qs(-1);
  late final _noteZh = qs<List<String>>([]);
  late final _noteEn = qs<List<String>>([]);
  late final _androidUrl = qs<String?>(null);
  late final _androidApkUrl = qs<String?>(null);
  late final _iosUrl = qs<String?>(null);
  late final shareChatQrCodeZh = qs<String?>(null);
  late final shareChatQrCodeEn = qs<String?>(null);

  /// 全部的配置信息, 包含所有功能种类的权重
  late final _config = qs<Map<String, dynamic>?>(null);

  late final _newVersionDialogShown = qs(false);

  final _isDesktop = qs(false);
  final _isMobile = qs(true);

  late final featureRollout = qs<FeatureRollout>(const FeatureRollout());

  /// 当前应用的主题
  late final customTheme = qs<custom_theme.CustomTheme>(custom_theme.Light());

  late final tabIndex = qs(0);

  late final apkDownloadState = qs<TaskUpdate?>(null);

  // ===========================================================================
  // Provider
  // ===========================================================================

  late final pageKey = qp((ref) => ref.watch(_pageKey));

  late final isDesktop = qp((ref) => ref.watch(_isDesktop));
  late final isMobile = qp((ref) => ref.watch(_isMobile));
}

/// Public methods
extension $App on _App {
  /// # 同步配置
  ///
  /// 1. 先从 sandbox 中同步配置, 如果 sandbox 中没有, 则从应用包中加载, 并存储到本地沙盒中
  /// 2. 再从服务器同步配置
  Future<void> syncConfig() async {
    qq;

    final (config, sp) = await _loadConfigFromLocal();
    _config.q = config;
    await _parseConfigForDemoSpecificData(config[demoType.q.name]);
    await P.fileManager.syncAvailableModels();
    await P.fileManager.checkLocal();

    if (Args.disableRemoteConfig) {
      qqw("Remote config is disabled");
      return;
    }

    await Future.delayed(const Duration(milliseconds: 17));

    final allConfig = await _getRemoteConfig();
    if (allConfig == null) {
      qqe("Can not get remote config, skip sync");
      return;
    }

    _config.q = allConfig;
    await sp.setString(_configForAllDemosKey, jsonEncode(allConfig));
    await _parseConfigForDemoSpecificData(allConfig[demoType.q.name]);
    await P.fileManager.syncAvailableModels();
    await P.fileManager.checkLocal();
    await P.fileManager.removeFilesNotInConfig();
  }

  void hapticLight() {
    if (_isMobile.q) Gaimon.light();
  }

  void hapticSoft() {
    if (_isMobile.q) Gaimon.soft();
  }

  void hapticMedium() {
    if (_isMobile.q) Gaimon.medium();
  }

  Future<void> customThemeChanged() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (customTheme.q.light) {
      _statusBarToLightMode();
    } else {
      _statusBarToDarkMode();
    }
  }

  void checkUpdates() async {
    final allConfig = await _getRemoteConfig();
    final config = allConfig?[demoType.q.name];
    if (config == null) {
      qqe("config is null, demoType: ${demoType.q.name}");
      return;
    }
    _latestBuild.q = config["latest_build"] as int;
    _latestBuildIos.q = config["latest_build_ios"] as int;
    if (Platform.isIOS && _latestBuildIos.q <= int.parse(buildNumber.q)) {
      Alert.info(S.current.app_is_already_up_to_date);
      return;
    }
    if (_latestBuild.q <= int.parse(buildNumber.q)) {
      Alert.info(S.current.app_is_already_up_to_date);
      return;
    }
    await _showNewVersionDialogIfNeeded();
  }

  void onTabSelected(int index) {
    tabIndex.q = index;
    replace(PageKey.tabs[index]);
  }
}

/// Private methods
extension _$App on _App {
  Future<void> _init() async {
    qq;

    _initDB();

    _isDesktop.q = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    _isMobile.q = Platform.isAndroid || Platform.isIOS;

    await init();

    late final String name;
    if (kDebugMode) {
      name = (Args.demoType).replaceAll("__", "");
    } else {
      name = "__chat__".replaceAll("__", "");
    }
    demoType.q = DemoType.values.byName(name);

    kRouter.routerDelegate.addListener(_routerListener);

    if (kDebugMode) {
      final context = getContext();
      Future.delayed(const Duration(seconds: 1), () {
        if (context != null && context.mounted) {
          FocusScope.of(context).unfocus();
        }
      });
    }

    WidgetsBinding.instance.addObserver(this);

    syncConfig().then((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      _showNewVersionDialogIfNeeded();
    });

    lifecycleState.lv(_onLifecycleStateChanged);

    final latency = Platform.isWindows ? 2500 : 1750;

    // 目前下面四种 demo 需要选择模型
    switch (demoType.q) {
      case DemoType.sudoku:
      case DemoType.tts:
      case DemoType.world:
        HF.wait(latency).then((_) {
          final loaded = P.rwkv.loaded.q;
          if (loaded) return;
          if (!Args.disableAutoShowOfWeightsPanel) ModelSelector.show();
        });
      case DemoType.fifthteenPuzzle:
      // Other demos don't need to select model, weights are already built in
      case DemoType.chat:
      case DemoType.othello:
        break;
    }

    if (Args.debuggingThemes) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        final theme = customTheme.q;
        switch (theme) {
          case custom_theme.Light():
            customTheme.q = P.preference.preferredDarkCustomTheme.q;
          case custom_theme.Dim():
          case custom_theme.LightsOut():
            customTheme.q = custom_theme.Light();
        }
        preferredThemeMode.q = customTheme.q.light ? ThemeMode.light : ThemeMode.dark;
      });
    }

    preferredThemeMode.q = P.preference.themeMode.q;
    customTheme.q = P.preference.preferredDarkCustomTheme.q;
    customTheme.lv(customThemeChanged, fireImmediately: true);
    preferredThemeMode.lv(_syncTheme, fireImmediately: true);
    light.lv(_syncTheme, fireImmediately: true);
    P.preference.preferredDarkCustomTheme.lv(_syncTheme, fireImmediately: true);

    if (Args.autoShowTranslator) {
      Future.delayed(const Duration(milliseconds: 1500)).then((_) {
        push(PageKey.translator);
      });
    }
  }

  void _initDB() async {
    try {
      _db = db.AppDatabase();
    } catch (e) {
      qqe("Failed to open database");
      qqe(e);
    }
  }

  Future<void> _syncTheme() async {
    final light = this.light.q;
    final preferredThemeMode = this.preferredThemeMode.q;
    final preferredDarkCustomTheme = P.preference.preferredDarkCustomTheme.q;
    switch (preferredThemeMode) {
      case ThemeMode.light:
        customTheme.q = custom_theme.Light();
      case ThemeMode.dark:
        customTheme.q = preferredDarkCustomTheme;
      case ThemeMode.system:
        switch (light) {
          case true:
            customTheme.q = custom_theme.Light();
          case false:
            customTheme.q = preferredDarkCustomTheme;
        }
    }
  }

  Future<void> _statusBarToLightMode() async {
    SystemChrome.setSystemUIOverlayStyle(systemOverlayStyleLight);
  }

  Future<void> _statusBarToDarkMode() async {
    qq;
    SystemChrome.setSystemUIOverlayStyle(systemOverlayStyleDark);
  }

  Future<void> _onLifecycleStateChanged() async {}

  Future<void> _showNewVersionDialogIfNeeded() async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    if (Platform.isAndroid && _latestBuild.q <= int.parse(buildNumber.q)) return;
    if (Platform.isIOS && _latestBuildIos.q <= int.parse(buildNumber.q)) return;

    qq;

    final androidUrl = _androidUrl.q ?? '';
    final androidApkUrl = _androidApkUrl.q ?? '';
    final iosUrl = _iosUrl.q;

    if (Platform.isAndroid && (androidUrl.isEmpty)) return;

    if (Platform.isIOS && (iosUrl == null || iosUrl.isEmpty)) return;

    await Future.delayed(const Duration(milliseconds: 1));

    final noteZh = _noteZh.q;
    final noteEn = _noteEn.q;

    final currentLocale = Intl.getCurrentLocale();
    final useEn = currentLocale.startsWith("en");

    final message = useEn ? noteEn.join("\n") : noteZh.join("\n");

    final showInAppUpdate = Platform.isAndroid && androidApkUrl.isNotEmpty;

    qqq('app update: \n$androidUrl\n$androidApkUrl\n$iosUrl\n$message');

    _newVersionDialogShown.q = true;
    final res = await showAlertDialog(
      context: getContext()!,
      title: S.current.new_version_found,
      message: message,
      // okLabel: S.current.update_now,
      actions: [
        AlertDialogAction(key: 1, label: S.current.cancel_update),
        if (showInAppUpdate)
          AlertDialogAction(
            key: 2,
            label: S.current.download_from_browser,
          ),
        AlertDialogAction(key: 3, label: S.current.update_now),
      ],
      // cancelLabel: S.current.cancel_update,
    );
    _newVersionDialogShown.q = false;

    if (res == 1 || res == null) return;

    if (Platform.isAndroid) {
      if (res == 3 && showInAppUpdate) {
        _startInAppUpdate(androidApkUrl);
      } else {
        launchUrl(Uri.parse(androidUrl), mode: LaunchMode.externalApplication);
      }
    }

    if (Platform.isIOS) {
      if (iosUrl == null) {
        qqe("iosUrl is null");
        return;
      }
      launchUrl(Uri.parse(iosUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// 解析配置, 只解析 demo 相关的数据, 不解析所有数据
  Future<void> _parseConfigForDemoSpecificData(Map<String, dynamic>? json) async {
    if (json == null) {
      qqe("json is null");
      return;
    }

    final build = json["latest_build"];
    final buildIos = json["latest_build_ios"];

    if (build is! num) {
      qqe("build is not an num, build: $build");
      Sentry.captureException(Exception("build is not an num, build: $build"), stackTrace: StackTrace.current);
      return;
    }

    if (buildIos is! num) {
      qqe("buildIos is not an num, buildIos: $buildIos");
      Sentry.captureException(Exception("buildIos is not an num, buildIos: $buildIos"), stackTrace: StackTrace.current);
      return;
    }

    _latestBuild.q = build.toInt();
    _latestBuildIos.q = buildIos.toInt();
    _noteZh.q = (json["note_zh"] as List<dynamic>).m((e) => e.toString());
    _noteEn.q = (json["note_en"] as List<dynamic>).m((e) => e.toString());
    _androidUrl.q = json["android_url"];
    _androidApkUrl.q = json["android_apk_url"];
    shareChatQrCodeEn.q = json["share_chat_qrcode_en"];
    shareChatQrCodeZh.q = json["share_chat_qrcode_zh"];
    _iosUrl.q = json["ios_url"].toString();
    featureRollout.q =
        FeatureRollout.fromMap(json["controlled_rollout"]) // merge with dev options
            .merge(P.preference.featureRollout);
  }

  void _routerListener() {
    final currentConfiguration = kRouter.routerDelegate.currentConfiguration;
    final matchedLocation = currentConfiguration.last.matchedLocation;
    final pageKey = PageKey.values.byName(matchedLocation.replaceAll("/", ""));
    qqr("navigate to page: ${pageKey.toString().split(".").last}");
    Future.delayed(const Duration(milliseconds: 0)).then((_) {
      _pageKey.q = pageKey;
    });
  }

  /// 从服务器获取远程配置
  Future<Map<String, dynamic>?> _getRemoteConfig() async {
    try {
      final res = await _get("get-demo-config", timeout: 10000.ms);
      if (res is! Map) return null;
      final success = res["success"];
      final message = res["message"];
      final data = res["data"];
      if (success != true) throw "success is false, success: $success, message: $message";
      if (data is! Map) throw "data is not a Map, data: ${data.runtimeType}";
      qqr("pull remote config success");
      return HF.json(data);
    } catch (e) {
      qe;
      qqe(e);
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
    }
    return null;
  }

  /// 从本地沙盒中加载配置, 如果本地沙盒中没有, 则从应用包中加载, 并存储到本地沙盒中
  Future<(Map<String, dynamic> json, SharedPreferences sp)> _loadConfigFromLocal() async {
    qr;

    final startTime = HF.milliseconds;

    final sp = await SharedPreferences.getInstance();
    final contains = sp.containsKey(_configForAllDemosKey);

    // 如果禁用了远程配置, 则强制从应用包中加载
    final forceRefreshFromBundle = Args.disableRemoteConfig;
    if (forceRefreshFromBundle) {
      qqw("force refresh from bundle");
      final jsonPath = "remote/latest.json";
      final jsonStringInBundle = await rootBundle.loadString(jsonPath);
      await sp.setString(_configForAllDemosKey, jsonStringInBundle);
    }

    if (contains) {
      qqq("latest config data already stored in sandbox");
    } else {
      qqq("latest config data not stored in sandbox");
      qqq("load latest config from application bundle");
      final jsonPath = "remote/latest.json";
      final jsonStringInBundle = await rootBundle.loadString(jsonPath);
      await sp.setString(_configForAllDemosKey, jsonStringInBundle);
    }

    final jsonString = sp.getString(_configForAllDemosKey);
    final rawJSON = jsonDecode(jsonString!);
    final json = HF.json(rawJSON);

    final endTime = HF.milliseconds;
    qqw("load config from local sandbox and bundle time: ${endTime - startTime}ms");

    return (json, sp);
  }

  void _startInAppUpdate(String url) async {
    final cacheDir = await getApplicationCacheDirectory();
    final apkPath = '${cacheDir.path}/rwkv_chat_${_latestBuild.q}.apk';
    if (await File(apkPath).exists()) {
      _installApk(apkPath);
      return;
    }
    _appUpdateTask = await DownloadTask.create(url: url, path: apkPath);
    _appUpdateTask!
        .events() //
        .throttleTime(const Duration(milliseconds: 1000), trailing: true, leading: false)
        .listen(
          (event) async {
            qqq(
              'download update: ${event.progress.toStringAsFixed(1)}% '
              'speed:${event.speedInMB.toStringAsFixed(2)}MB/s',
            );
            if (event.state == TaskState.stopped) {
              _appUpdateTask = null;
            }
            if (event.state == TaskState.completed) {
              _appUpdateTask = null;
              _installApk(apkPath);
            }
            switch (event.state) {
              case TaskState.running:
                apkDownloadState.q = event;
                break;
              default:
                apkDownloadState.q = null;
            }
          },
          onDone: () async {
            _appUpdateTask = null;
            apkDownloadState.q = null;
          },
          onError: (e) {
            qqe(e);
            _appUpdateTask = null;
            apkDownloadState.q = null;
          },
        );
    try {
      await _appUpdateTask!.start();
      Alert.success(S.current.start_download_updates_);
    } catch (e) {
      qqe(e);
      Alert.error(S.current.download_failed);
    }
  }

  void _installApk(String apkPath) async {
    try {
      final utils = const MethodChannel("utils");
      await utils.invokeMethod('installApk', {"path": apkPath});
    } catch (e) {
      qqe(e);
    }
  }
}
