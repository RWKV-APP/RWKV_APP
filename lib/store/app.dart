part of 'p.dart';

class _App extends RawApp {
  // ===========================================================================
  // Instance
  // ===========================================================================

  late final db.AppDatabase _db;

  // ===========================================================================
  // Getters
  // ===========================================================================

  SystemUiOverlayStyle get systemOverlayStyleLight {
    return const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
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

  final _pageKey = qs<PageKey>(.first);

  /// 当前正在运行的任务
  late final demoType = qs<DemoType>(.chat);

  late final shareChatQrCodeZh = qs<String?>(null);
  late final shareChatQrCodeEn = qs<String?>(null);

  /// 全部的配置信息, 包含所有功能种类的权重
  late final _config = qs<Map<String, dynamic>?>(null);

  final _isDesktop = qs(false);
  final _isMobile = qs(true);

  late final featureRollout = qs<FeatureRollout>(const FeatureRollout());

  /// 当前应用的主题
  late final customTheme = qs<custom_theme.CustomTheme>(custom_theme.Light());

  late final tabIndex = qs(0);

  /// Windows-specific documents directory using AppData (for sandbox-like behavior)
  late final _windowsDocumentsDir = qs<Directory?>(null);

  /// Get the effective documents directory for the current platform
  /// On Windows, returns AppData directory; on other platforms, returns the standard documentsDir
  // TODO: 这里的 AI 简直在写狗屎代码，要重构 @wangce
  late final effectiveDocumentsDir = qp<Directory?>((ref) {
    if (Platform.isWindows) {
      final windowsDir = ref.watch(_windowsDocumentsDir);
      // On Windows, always prefer AppData directory if available
      if (windowsDir != null) {
        return windowsDir;
      }
      // If _windowsDocumentsDir is null on Windows, it means initialization hasn't completed yet
      // or initialization failed. In either case, we should NOT use documentsDir as it's not sandboxed.
      // Return null to indicate the directory is not ready yet.
      // This will cause callers to handle the null case appropriately.
      return null;
    }
    final documentsDir = ref.watch(this.documentsDir);
    return documentsDir;
  });

  late final checkingLatestVersion = qs(false);
  late final latestVersionInfo = qs<VersionInfo?>(null);
  late final releaseNotesContent = qs<({String? content, String? version})?>(null);

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
    await P.remote.syncAvailableModels();
    await P.remote.checkLocal();

    if (Args.disableRemoteConfig) {
      qqw("Remote config is disabled");
      return;
    }

    await 17.msLater;

    final allConfig = await _getRemoteConfig();
    if (allConfig == null) {
      qqe("Can not get remote config, skip sync");
      return;
    }

    _config.q = allConfig;
    await sp.setString(_configForAllDemosKey, jsonEncode(allConfig));
    deleteOutdatedConfigInPreference();
    await _parseConfigForDemoSpecificData(allConfig[demoType.q.name]);
    await P.remote.syncAvailableModels();
    await P.remote.checkLocal();
    await P.remote.removeFilesNotInConfig();
  }

  void deleteOutdatedConfigInPreference() async {
    final sp = await SharedPreferences.getInstance();
    sp.getKeys().forEach((key) {
      if (key.startsWith("configForAllDemosKey_") && key != _configForAllDemosKey) {
        sp.remove(key);
      }
    });
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
    await 100.msLater;
    if (customTheme.q.light) {
      _statusBarToLightMode();
    } else {
      _statusBarToDarkMode();
    }
  }

  void checkUpdates({bool manually = false}) async {
    qr;
    checkingLatestVersion.q = true;
    VersionInfo? latestVersionInfo;
    try {
      latestVersionInfo = await _getLatestVersionInfo();
    } catch (e) {
      qqe(e);
      if (manually) Alert.error(S.current.failed_to_check_for_updates);
      Sentry.captureException(e, stackTrace: StackTrace.current);
    } finally {
      checkingLatestVersion.q = false;
    }

    qqr("latest version info: $latestVersionInfo");
    if (latestVersionInfo == null) {
      if (manually) Alert.info(S.current.app_is_already_up_to_date);
      if (manually) await VersionInfoPanel.show(isLatest: true);
      return;
    }

    this.latestVersionInfo.q = latestVersionInfo;

    final latestBuild = latestVersionInfo.build;

    if (!Args.forceShowNewVersionPanel) {
      if (latestBuild <= int.parse(buildNumber.q)) {
        if (manually) Alert.info(S.current.app_is_already_up_to_date);
        if (manually) await VersionInfoPanel.show(isLatest: true);
        return;
      }
    }

    Alert.success(S.current.new_version_available);

    getReleaseNotes(build: latestBuild, version: latestVersionInfo.version);

    await VersionInfoPanel.show();
  }

  void onTabSelected(int index) {
    tabIndex.q = index;
    replace(.tabs[index]);
  }

  void skipThisVersion() {
    final latestVersionInfo = this.latestVersionInfo.q;
    if (latestVersionInfo == null) {
      qqe("latestVersionInfo is null");
      return;
    }
    final build = latestVersionInfo.build;
    P.preference.saveLatestSkippedBuildNumber(build);
    pop();
  }

  Future<void> onDownloadNowClicked() async {
    final latestVersionInfo = this.latestVersionInfo.q;

    if (latestVersionInfo == null) {
      qqe("latestVersionInfo is null");
      Alert.error(S.current.no_latest_version_info);
      return;
    }

    try {
      await launchUrl(
        Uri.parse("https://rwkv.halowang.cloud/"),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      qqe(e);
      // Alert.error(S.current.failed_to_open_url);
      // Sentry.captureException(e, stackTrace: StackTrace.current);
    }
  }

  /// Convert Language enum to locale string for API
  String _languageToLocaleString(Language language) {
    final resolved = language.resolved;
    final locale = resolved.locale;

    // Convert to API locale format
    if (resolved == Language.zh_Hans) {
      return 'zh-CN';
    } else if (resolved == Language.zh_Hant) {
      return 'zh-TW';
    } else {
      // For other languages, use languageCode directly
      return locale.languageCode;
    }
  }

  Future<void> getReleaseNotes({required int build, String? version}) async {
    // Get current language preference and convert to locale string
    final currentLanguage = P.preference.preferredLanguage.q;
    final locale = _languageToLocaleString(currentLanguage);

    final baseUrl = "${Config.apiv2}/distributions/release-notes";
    var fullUrl = "$baseUrl?build=$build&locale=${Uri.encodeComponent(locale)}";
    if (version != null && version.isNotEmpty) {
      fullUrl = "$fullUrl&version=${Uri.encodeComponent(version)}";
    }
    try {
      final res = await _get(fullUrl, timeout: 2000.ms);
      if (res is! Map) {
        releaseNotesContent.q = null;
        return;
      }
      final content = res['content'];
      final versionFromResponse = res['version'];
      if (content is String) {
        releaseNotesContent.q = (
          content: content.isEmpty ? null : content,
          version: versionFromResponse is String ? versionFromResponse : null,
        );
      } else {
        releaseNotesContent.q = null;
      }
    } catch (e) {
      qqe("Error fetching release notes: $e");
      releaseNotesContent.q = null;
    }
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

    // On Windows, use AppData instead of Documents for sandbox-like behavior
    if (Platform.isWindows) {
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        _windowsDocumentsDir.q = appSupportDir;
        qqq("Windows: Using AppData directory: ${appSupportDir.path}");
        // Verify the path is actually in AppData, not Documents
        final path = appSupportDir.path.toLowerCase();
        if (path.contains('documents') && !path.contains('appdata')) {
          qqw("WARNING: getApplicationSupportDirectory returned Documents path instead of AppData: ${appSupportDir.path}");
        }
      } catch (e) {
        qqe("Failed to get Windows AppData directory: $e");
        // On Windows, we should NOT fallback to documentsDir as it's not sandboxed
        // Instead, leave _windowsDocumentsDir as null, which will cause effectiveDocumentsDir to return null
        // This will force callers to handle the error appropriately
        qqw("Windows: AppData directory initialization failed, effectiveDocumentsDir will return null");
      }
    }

    late final String name;
    if (kDebugMode) {
      name = (Args.demoType).replaceAll("__", "");
    } else {
      name = "__chat__".replaceAll("__", "");
    }
    demoType.q = .values.byName(name);

    kRouter.routerDelegate.addListener(_routerListener);

    if (kDebugMode) {
      final context = getContext();
      1000.msLater.then((_) {
        if (context != null && context.mounted) {
          FocusScope.of(context).unfocus();
        }
      });

      if (Args.testingSeeQueue) P.see.autoTest();
    }

    WidgetsBinding.instance.addObserver(this);

    lifecycleState.lv(_onLifecycleStateChanged);

    final latency = Platform.isWindows ? 2500 : 1750;

    // 目前下面四种 demo 需要选择模型
    switch (demoType.q) {
      case .sudoku:
      case .tts:
      case .see:
        latency.msLater.then((_) {
          final loaded = P.rwkv.loaded.q;
          if (loaded) return;
          if (!Args.disableAutoShowOfWeightsPanel) ModelSelector.show();
        });
      case .fifthteenPuzzle:
      // Other demos don't need to select model, weights are already built in
      case .chat:
      case .othello:
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
      1500.msLater.then((_) {
        push(.translator);
      });
    }

    1000.msLater.then((_) {
      syncConfig();
    });

    await Highlighter.initialize(['dart', 'yaml', 'sql', 'python', "javascript"]);
    1000.msLater.then((_) async {
      qqr("load light theme");
      final theme = await HighlighterTheme.loadDarkTheme();
      Highlighter(
        language: 'javascript',
        theme: theme,
      );
    });

    2500.msLater.then((_) {
      checkUpdates();
    });

    deleteOutdatedConfigInPreference();
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

  /// 解析配置, 只解析 demo 相关的数据, 不解析所有数据
  Future<void> _parseConfigForDemoSpecificData(Map<String, dynamic>? json) async {
    if (json == null) {
      qqe("json is null");
      return;
    }

    shareChatQrCodeEn.q = json["share_chat_qrcode_en"];
    shareChatQrCodeZh.q = json["share_chat_qrcode_zh"];
    featureRollout.q =
        FeatureRollout.fromMap(json["controlled_rollout"]) // merge with dev options
            .merge(P.preference.featureRollout);
  }

  void _routerListener() {
    final currentConfiguration = kRouter.routerDelegate.currentConfiguration;
    final matchedLocation = currentConfiguration.last.matchedLocation;
    final pageKey = PageKey.values.byName(matchedLocation.replaceAll("/", ""));
    qqr("navigate to page: ${pageKey.toString().split(".").last}");
    0.msLater.then((_) {
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

  /// 根据运行环境获取对应的 distribution keys
  Future<List<String>> _getDistributionKeysForPlatform() async {
    if (Platform.isMacOS) {
      return [
        'macosGR',
        'macosHF',
        'macosAF',
        'macosHFM',
      ];
    } else if (Platform.isWindows) {
      try {
        // 检测 Windows 架构
        // 在 Windows 上，可以通过环境变量 PROCESSOR_ARCHITECTURE 来判断
        final processorArch = Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase() ?? '';
        final processorArchW6432 = Platform.environment['PROCESSOR_ARCHITEW6432']?.toUpperCase() ?? '';

        // ARM64 架构会显示为 ARM64
        final isArm64 = processorArch == 'ARM64' || processorArchW6432 == 'ARM64';

        if (isArm64) {
          return [
            'winArm64GR',
            'winArm64ZipGR',
            'winArm64HF',
            'winArm64AF',
            'winArm64HFM',
            'winArm64ZipHF',
            'winArm64ZipAF',
            'winArm64ZipHFM',
          ];
        } else {
          // 默认使用 x64 keys
          return [
            'winZipGR',
            'winHF',
            'winAF',
            'winGR',
            'winHFM',
            'winZipHF',
            'winZipAF',
            'winZipHFM',
          ];
        }
      } catch (e) {
        qqe("Failed to detect Windows architecture: $e");
        // 默认返回 x64 keys
        return [
          'winGR',
          'winZipGR',
          'winHF',
          'winAF',
          'winHFM',
          'winZipHF',
          'winZipAF',
          'winZipHFM',
        ];
      }
    } else if (Platform.isLinux) {
      return [
        'linuxGR',
        'linuxHF',
        'linuxAF',
        'linuxHFM',
      ];
    } else if (Platform.isAndroid) {
      // Android 平台：请求所有可用的分发渠道
      return [
        'androidGR',
        'androidHF',
        'androidAF',
        'androidHFM',
        'androidPgyerAPK',
        'androidPgyer',
        'androidGooglePlay',
      ];
    } else if (Platform.isIOS) {
      // iOS 平台：请求 TestFlight 和 App Store
      return [
        'iOSTF',
        'iOSAS',
      ];
    } else {
      // 其他未知平台
      return [];
    }
  }

  /// 获取最新的版本信息, 返回 false 代表无需更新
  Future<VersionInfo?> _getLatestVersionInfo() async {
    qr;

    await 500.msLater;

    // 根据运行环境获取对应的 keys
    final keys = await _getDistributionKeysForPlatform();

    if (keys.isEmpty) return null;

    // 构建查询参数，使用 List 来支持多个相同的 key
    // NestJS 的 @Query('key') 可以接受数组，格式为 ?key=value1&key=value2
    final queryParts = keys.map((key) => 'key=${Uri.encodeComponent(key)}').toList();
    final queryString = queryParts.join('&');

    // 构建完整的 URL，包含查询参数
    final baseUrl = "${Config.apiv2}/distributions/latest";
    final fullUrl = "$baseUrl?$queryString";

    final res = await _get(fullUrl, timeout: 2000.ms);

    if (res is! Map) {
      qqe("res is not a Map, res: $res");
      return null;
    }

    // 从返回的数据中找到 build 号最高的那个
    int? highestBuild;
    Map<String, dynamic>? highestBuildRecord;
    String? highestBuildKey;

    for (final entry in res.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) continue;

      if (value is Map) {
        final build = value['build'];
        if (build is int) {
          if (highestBuild == null || build > highestBuild) {
            highestBuild = build;
            highestBuildRecord = Map<String, dynamic>.from(value);
            highestBuildKey = key;
          }

          if (build == highestBuild && key.endsWith('GR')) {
            highestBuild = build;
            highestBuildRecord = Map<String, dynamic>.from(value);
            highestBuildKey = key;
          }
        }
      }
    }

    if (highestBuildRecord == null || highestBuildKey == null) {
      // 这里可以将结果存储到状态中或执行其他操作
      // 例如：_latestBuild.q = highestBuild;
      // 例如：_latestDownloadUrl.q = highestBuildRecord['url'];
      return null;
    }

    if (highestBuild == null) return null;

    return .fromJson(highestBuildRecord);
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

  // void _startInAppUpdate(String url) async {
  //   final cacheDir = await getApplicationCacheDirectory();
  //   final apkPath = '${cacheDir.path}/rwkv_chat_${_latestBuild.q}.apk';
  //   if (await File(apkPath).exists()) {
  //     _installApk(apkPath);
  //     return;
  //   }
  //   _appUpdateTask = await DownloadTask.create(url: url, path: apkPath);
  //   _appUpdateTask!
  //       .events() //
  //       .throttleTime(const Duration(milliseconds: 1000), trailing: true, leading: false)
  //       .listen(
  //         (event) async {
  //           qqq(
  //             'download update: ${event.progress.toStringAsFixed(1)}% '
  //             'speed:${event.speedInMB.toStringAsFixed(2)}MB/s',
  //           );
  //           if (event.state == TaskState.stopped) {
  //             _appUpdateTask = null;
  //           }
  //           if (event.state == TaskState.completed) {
  //             _appUpdateTask = null;
  //             _installApk(apkPath);
  //           }
  //           switch (event.state) {
  //             case TaskState.running:
  //               apkDownloadState.q = event;
  //               break;
  //             default:
  //               apkDownloadState.q = null;
  //           }
  //         },
  //         onDone: () async {
  //           _appUpdateTask = null;
  //           apkDownloadState.q = null;
  //         },
  //         onError: (e) {
  //           qqe(e);
  //           _appUpdateTask = null;
  //           apkDownloadState.q = null;
  //         },
  //       );
  //   try {
  //     await _appUpdateTask!.start();
  //     Alert.success(S.current.start_download_updates_);
  //   } catch (e) {
  //     qqe(e);
  //     Alert.error(S.current.download_failed);
  //     Sentry.captureException(e, stackTrace: StackTrace.current);
  //   }
  // }

  // void _installApk(String apkPath) async {
  //   try {
  //     final utils = const MethodChannel("utils");
  //     await utils.invokeMethod('installApk', {"path": apkPath});
  //   } catch (e) {
  //     qqe(e);
  //   }
  // }
}
