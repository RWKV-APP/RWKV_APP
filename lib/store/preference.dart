part of 'p.dart';

const String _debugRenderNewlineDirectlyPreferenceKey = "halo_state.debug.renderNewlineDirectly";
const String _legacyDebugRenderNewlineDirectlyPreferenceKey = "halo_state.debug.renderEscapeDirectly";
const String _debugRenderSpaceSymbolPreferenceKey = "halo_state.debug.renderSpaceSymbol";
const String _legacyDebugRenderSpaceSymbolPreferenceKey = "halo_state.debug.showSpaceSymbols";
const String _debugShowPrefillLogOnlyPreferenceKey = "halo_state.debug.showPrefillLogOnly";
const String _messageLineHeightPreferenceKey = "halo_state.messageLineHeight";
const String _fakeBatchInferenceBenchmarkPreferenceKey = "halo_state.fakeBatchInferenceBenchmarkEnabled";
const String _batchViewportWidthPreferenceKey = "halo_state.batchViewportWidth";
const String _renderMarkdownAndLatexPreferenceKey = "halo_state.renderMarkdownAndLatex";
const String _thinkingModePreferenceKey = "halo_state.thinkingMode";

class _Preference {
  // ===========================================================================
  // Static
  // ===========================================================================

  final textScaleFactorSystem = -1.0;
  final messageLineHeightDefault = 0.0;

  // ===========================================================================
  // Instance
  // ===========================================================================

  bool _enableSystemProxy = true;

  bool get enableSystemProxy => _enableSystemProxy;

  bool _showBatteryOptimization = true;

  var featureRollout = const FeatureRollout();

  bool fakeBatchInferenceBenchmarkEnabled = false;
  bool renderMarkdownAndLatex = true;

  var promptTemplate = PromptTemplate.empty();

  // ===========================================================================
  // Getters
  // ===========================================================================

  // late final availableTextScaleFactors = [_textScaleFactorSystem, .8, .9, 1.0, 1.1, 1.2, 1.3, 1.4];
  // late final availableTextScaleNames = [
  //   "跟随系统",
  //   "很小（80%）",
  //   "小（90%）",
  //   "默认（100%）",
  //   "中（110%）",
  //   "大（120%）",
  //   "超大（130%）",
  //   "特别大（140%）",
  // ];
  Map<double, String> get textScalePairs => {
    textScaleFactorSystem: S.current.follow_system,
    .8: S.current.very_small,
    .9: S.current.small,
    1.0: S.current.font_size_default,
    1.1: S.current.medium,
    1.2: S.current.large,
    1.3: S.current.extra_large,
    1.4: S.current.ultra_large,
  };

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  /// 空表示根据系统当前的 locale，在可选的 locale 中选择一个
  ///
  /// 非空表示使用指定的 locale
  late final preferredLanguage = qs<Language>(Language.none);

  late final userType = qs<UserType>(.powerUser);

  /// 空表示根据系统当前的 textScaleFactor 来设置应用的 textScaleFactor
  ///
  /// 非空表示使用指定的 textScaleFactor
  late final preferredTextScaleFactor = qs<double>(-1.0);

  /// 偏好的消息气泡行距；0 表示使用默认行高
  late final preferredMessageLineHeight = qs<double>(0.0);
  late final renderMarkdownAndLatexEnabled = qs(true);

  late final preferredThinkingMode = qs<thinking_mode.ThinkingMode>(.fast);

  /// 偏好的主题模式设置，跟随系统、深色模式、浅色模式
  late final themeMode = qs<ThemeMode>(ThemeMode.system);

  /// 偏好的深色模式主题
  late final preferredDarkCustomTheme = qs<app_theme.AppTheme>(.lightsOut);

  late final lastWorldModel = qs<Map<String, dynamic>?>(null);

  late final lastChatModel = qs<Map<String, dynamic>?>(null);

  @Deprecated("This is not used anymore")
  late final latestRuntimeAddress = qs<int>(0);

  late final dumpping = qs(false);

  /// Custom directory for storing models (Desktop only)
  late final customModelsDir = qs<String?>(null);

  /// macOS security-scoped bookmark for custom models directory
  late final customModelsDirBookmark = qs<String?>(null);

  /// Whether the weights migration to weights folder has been completed
  late final weightsMigrationCompleted = qs<bool>(false);

  /// 偏好的 UI 字体（null 表示使用系统默认）
  late final preferredUIFont = qs<String?>(null);

  /// 偏好的等宽字体（null 表示使用系统默认）
  late final preferredMonospaceFont = qs<String?>(null);

  /// 如果检测到最新版本为 100, 且, latestSkippedBuildNumber = 50, 那么显示版本更新信息, 认为用户没有点击过 "跳过这个版本"
  ///
  /// 如果检测到最新版本为 100, 且, latestSkippedBuildNumber = 100, 那么不显示版本更新信息, 认为用户点击过 "跳过这个版本"
  ///
  /// 如果检测到最新版本为 100, 且, latestSkippedBuildNumber = 101, 那么不显示版本更新信息, 认为用户点击过 "跳过这个版本"
  ///
  /// 跳过版本仅用于自动检查更新, 如果用户手动点击检查更新, 我们依然会显示新版本的弹窗
  late final latestSkippedBuildNumber = qs<int>(0);

  /// Pth 文件夹列表；macOS 上可含 security-scoped bookmark 以持久化访问权限
  late final pthFolderEntries = qs<List<PthFolderEntry>>([]);

  bool hasUnlinkDefaultModelsDirOnce = false;

  // ===========================================================================
  // Provider
  // ===========================================================================

  late final currentLangIsZh = qp((ref) {
    final preferredLanguage = ref.watch(P.preference.preferredLanguage);
    return preferredLanguage.resolved.locale.languageCode == "zh";
  });

  late final effectiveMessageLineHeight = qp<double?>((ref) {
    final preferredMessageLineHeight = ref.watch(P.preference.preferredMessageLineHeight);
    if (preferredMessageLineHeight <= 0) {
      return null;
    }
    return preferredMessageLineHeight;
  });
}

/// Private methods
extension _$Preference on _Preference {
  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();

    _showBatteryOptimization = sp.getBool("halo_state.showBatteryOptimizationDialog") ?? true;
    _enableSystemProxy = sp.getBool("halo_state.enableSystemProxy") ?? true;

    final language = sp.getString("halo_state.language");
    if (language != null) {
      final r = Language.values.firstWhereOrNull((e) => e.name == language) ?? Language.none;
      qqq("language: $language, r: $r");
      preferredLanguage.q = r;
      Locale local = Language.en.locale;
      if (r == Language.zh_Hans || r == Language.zh_Hant) {
        local = Language.zh_Hans.locale;
      }
      RoleplayManage.changeLocale(local);
    } else {
      preferredLanguage.q = Language.none;
    }

    await S.load(preferredLanguage.q.resolved.locale);

    final textScaleFactor = sp.getDouble("halo_state.textScaleFactor");
    if (textScaleFactor != null) {
      preferredTextScaleFactor.q = textScaleFactor;
    } else {
      preferredTextScaleFactor.q = -1;
    }

    final messageLineHeight = sp.getDouble(_messageLineHeightPreferenceKey);
    if (messageLineHeight != null && messageLineHeight > 0) {
      preferredMessageLineHeight.q = messageLineHeight;
    } else {
      preferredMessageLineHeight.q = messageLineHeightDefault;
    }

    final userType = sp.getInt("halo_state.user_type");
    if (userType != null) {
      this.userType.q = .values.firstWhereOrNull((e) => e.index == userType) ?? .user;
    }

    final latestRuntimeAddress = sp.getInt("halo_state.latestRuntimeAddress");
    if (latestRuntimeAddress != null) this.latestRuntimeAddress.q = latestRuntimeAddress;

    if (Platform.isAndroid && P.app.demoType.q == .see) {
      final status = await Permission.storage.status;
      if (status.isGranted) {
        final dumpping = sp.getBool("halo_state.dumpping");
        if (dumpping != null) this.dumpping.q = dumpping;
      } else {
        await _saveDumpping(false);
      }
    }

    final themeMode = sp.getString("halo_state.themeMode");
    if (themeMode != null) {
      this.themeMode.q = ThemeMode.values.firstWhereOrNull((e) => e.name == themeMode) ?? ThemeMode.system;
    }

    final preferredDarkCustomTheme = sp.getString("halo_state.preferredDarkCustomTheme");
    if (preferredDarkCustomTheme != null) {
      this.preferredDarkCustomTheme.q = .fromString(preferredDarkCustomTheme) ?? .lightsOut;
      if (this.preferredDarkCustomTheme.q == .light) {
        this.preferredDarkCustomTheme.q = .lightsOut;
      }
    }

    final ft = sp.getString('app.dev.feat');
    if (ft != null && ft.isNotEmpty) {
      try {
        featureRollout = FeatureRollout.fromMap(jsonDecode(ft));
      } catch (_) {}
    }

    fakeBatchInferenceBenchmarkEnabled = sp.getBool(_fakeBatchInferenceBenchmarkPreferenceKey) ?? false;
    renderMarkdownAndLatex = sp.getBool(_renderMarkdownAndLatexPreferenceKey) ?? true;
    renderMarkdownAndLatexEnabled.q = renderMarkdownAndLatex;

    final thinkingMode = sp.getString(_thinkingModePreferenceKey);
    final validThinkingMode = thinking_mode.ThinkingMode.values.map((e) => e.toString()).contains(thinkingMode);
    qqr(validThinkingMode ? "Loaded thinking mode: $thinkingMode" : "No valid thinking mode found in preferences, using default");
    if (validThinkingMode) {
      preferredThinkingMode.q = thinking_mode.ThinkingMode.fromString(thinkingMode);
    } else {
      preferredThinkingMode.q = .fast;
    }

    final tt = sp.getString('app.promptTemplate');
    if (tt != null && tt.isNotEmpty) {
      try {
        promptTemplate = PromptTemplate.deserialize(tt);
      } finally {}
    }

    final lastWorldModel = sp.getString("halo_state.lastWorldModel");
    if (lastWorldModel != null) {
      try {
        this.lastWorldModel.q = jsonDecode(lastWorldModel);
      } catch (_) {}
    }

    final lastChatModel = sp.getString("halo_state.lastChatModel");
    if (lastChatModel != null) {
      try {
        this.lastChatModel.q = jsonDecode(lastChatModel);
      } catch (_) {}
    }

    final customModelsDir = sp.getString("halo_state.customModelsDir");
    if (customModelsDir != null) this.customModelsDir.q = customModelsDir;

    final customModelsDirBookmark = sp.getString("halo_state.customModelsDirBookmark");
    if (customModelsDirBookmark != null) this.customModelsDirBookmark.q = customModelsDirBookmark;

    final weightsMigrationCompleted = sp.getBool("halo_state.weightsMigrationCompletedv640");
    if (weightsMigrationCompleted != null) this.weightsMigrationCompleted.q = weightsMigrationCompleted;

    final decodeParamTypeIndex = sp.getInt("halo_state.decodeParamType");
    if (decodeParamTypeIndex != null) {
      final type = DecodeParamType.values[decodeParamTypeIndex];
      if (type == DecodeParamType.custom) {
        final temperature = sp.getDouble("halo_state.custom.temperature");
        final topP = sp.getDouble("halo_state.custom.topP");
        final presencePenalty = sp.getDouble("halo_state.custom.presencePenalty");
        final frequencyPenalty = sp.getDouble("halo_state.custom.frequencyPenalty");
        final penaltyDecay = sp.getDouble("halo_state.custom.penaltyDecay");
        await P.rwkv.syncSamplerParams(
          temperature: temperature,
          topP: topP,
          presencePenalty: presencePenalty,
          frequencyPenalty: frequencyPenalty,
          penaltyDecay: penaltyDecay,
        );
      } else {
        await P.rwkv.syncSamplerParamsFromDefault(type);
      }

      final latestSkippedBuildNumber = sp.getInt("halo_state.latestSkippedBuildNumber");
      if (latestSkippedBuildNumber != null) {
        this.latestSkippedBuildNumber.q = latestSkippedBuildNumber;
      } else {
        this.latestSkippedBuildNumber.q = 0;
      }
    }

    final uiFont = sp.getString("halo_state.preferredUIFont");
    if (uiFont != null && uiFont.isNotEmpty && uiFont != 'System') {
      preferredUIFont.q = uiFont;
      P.font.loadFontByName(uiFont);
    } else {
      preferredUIFont.q = null;
    }

    final monospaceFont = sp.getString("halo_state.preferredMonospaceFont");
    if (monospaceFont != null && monospaceFont.isNotEmpty && monospaceFont != 'System') {
      preferredMonospaceFont.q = monospaceFont;
      P.font.loadFontByName(monospaceFont);
    } else {
      preferredMonospaceFont.q = null;
    }

    final entriesJson = sp.getString("halo_state.pthFolderEntries");
    if (entriesJson != null) {
      final list = jsonDecode(entriesJson) as List<dynamic>?;
      if (list != null) {
        pthFolderEntries.q = list.map((e) => PthFolderEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } else {
      final legacyPaths = sp.getStringList("halo_state.pthFolderPaths");
      if (legacyPaths != null && legacyPaths.isNotEmpty) {
        pthFolderEntries.q = legacyPaths.map((p) => PthFolderEntry(path: p, bookmark: null)).toList();
        await sp.setString("halo_state.pthFolderEntries", jsonEncode(pthFolderEntries.q.map((e) => e.toJson()).toList()));
      }
    }

    final debugRenderNewlineDirectly = sp.getBool(_debugRenderNewlineDirectlyPreferenceKey);
    if (debugRenderNewlineDirectly != null) {
      P.rwkv.renderNewlineDirectly.q = debugRenderNewlineDirectly;
      await sp.remove(_legacyDebugRenderNewlineDirectlyPreferenceKey);
    } else {
      final legacyDebugRenderNewlineDirectly = sp.getBool(_legacyDebugRenderNewlineDirectlyPreferenceKey);
      if (legacyDebugRenderNewlineDirectly != null) {
        P.rwkv.renderNewlineDirectly.q = legacyDebugRenderNewlineDirectly;
        await sp.setBool(_debugRenderNewlineDirectlyPreferenceKey, legacyDebugRenderNewlineDirectly);
        await sp.remove(_legacyDebugRenderNewlineDirectlyPreferenceKey);
      }
    }

    final debugRenderSpaceSymbol = sp.getBool(_debugRenderSpaceSymbolPreferenceKey);
    if (debugRenderSpaceSymbol != null) {
      P.rwkv.renderSpaceSymbol.q = debugRenderSpaceSymbol;
      await sp.remove(_legacyDebugRenderSpaceSymbolPreferenceKey);
    } else {
      final legacyDebugRenderSpaceSymbol = sp.getBool(_legacyDebugRenderSpaceSymbolPreferenceKey);
      if (legacyDebugRenderSpaceSymbol != null) {
        P.rwkv.renderSpaceSymbol.q = legacyDebugRenderSpaceSymbol;
        await sp.setBool(_debugRenderSpaceSymbolPreferenceKey, legacyDebugRenderSpaceSymbol);
        await sp.remove(_legacyDebugRenderSpaceSymbolPreferenceKey);
      }
    }

    final debugShowPrefillLogOnly = sp.getBool(_debugShowPrefillLogOnlyPreferenceKey);
    if (debugShowPrefillLogOnly != null) {
      P.rwkv.showPrefillLogOnly.q = debugShowPrefillLogOnly;
    }

    await sp.remove("halo_state.debug.visibleSpaceSymbol");
    await sp.remove("halo_state.debug.spaceSymbolBackgroundColor");
    await sp.remove("halo_state.debug.spaceSymbolTextColor");
    await sp.remove("halo_state.debug.newlineSymbolBackgroundColor");
    await sp.remove("halo_state.debug.newlineSymbolTextColor");

    // TODO: remove getter after refactor P.init logic is done @wangce
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;

    final hasUnlinkDefaultModelsDirOnce = sp.getBool("halo_state.hasUnlinkDefaultModelsDirOnce.$version.$buildNumber");
    this.hasUnlinkDefaultModelsDirOnce = hasUnlinkDefaultModelsDirOnce == true;
  }

  Future<void> _saveDumpping(bool dumpping) async {
    qqr("saveDumpping: $dumpping");
    this.dumpping.q = dumpping;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool("halo_state.dumpping", dumpping);
  }
}

/// Public methods
extension $Preference on _Preference {
  void showUserTypeDialog() async {
    final context = getContext();
    if (context == null || !context.mounted) return;
    final currentQ = userType.q;
    final res = await showConfirmationDialog<UserType?>(
      context: context,
      title: S.current.application_mode,
      message: S.current.str_please_select_app_mode_,
      initialSelectedActionKey: currentQ,
      actions: [
        AlertDialogAction<UserType>(label: S.current.beginner, key: .user),
        AlertDialogAction<UserType>(label: S.current.power_user, key: .powerUser),
        AlertDialogAction<UserType>(label: S.current.expert, key: .expert),
      ],
    );
    if (res == null) return;
    userType.q = res;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.user_type", res.index);
  }

  void goToFontSettings() {
    push(.fontSettings);
  }

  Future<void> showLocaleDialog() async {
    final context = getContext();
    if (context == null) return;
    if (!context.mounted) return;
    final currentQ = preferredLanguage.q;
    final res = await showConfirmationDialog<Language>(
      context: context,
      title: S.current.application_language,
      message: S.current.please_select_application_language,
      initialSelectedActionKey: currentQ,
      actions: Language.values.m(
        (lang) => AlertDialogAction<Language>(
          label: lang.display ?? S.current.follow_system,
          key: lang,
        ),
      ),
    );

    if (res == null) return;
    qqq("res: $res");
    preferredLanguage.q = res;
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.language", res.locale.toString());
    RoleplayManage.changeLocale(res.locale);
  }

  Future<void> showThemeSettings() async {
    final context = getContext();
    if (context == null) return;
    if (!context.mounted) return;
    await ThemeSelector.show();
  }

  Future<void> tryShowBatteryOptimizationDialog(BuildContext context) async {
    if (!_showBatteryOptimization || !Platform.isAndroid) {
      return;
    }
    final isBatteryOptimizationDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    if (isBatteryOptimizationDisabled == false && context.mounted) {
      final result = await showOkCancelAlertDialog(
        context: context,
        title: S.current.allow_background_downloads,
        message: S.current.str_please_disable_battery_opt_,
        okLabel: S.current.go_to_settings,
        cancelLabel: S.current.dont_ask_again,
        barrierDismissible: false,
      );
      if (result == OkCancelResult.ok) {
        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      }
      if (result == OkCancelResult.cancel) {
        _showBatteryOptimization = false;
        final sp = await SharedPreferences.getInstance();
        await sp.setBool("halo_state.showBatteryOptimizationDialog", false);
      }
    }
  }

  void setFeatureRollout(FeatureRollout featureRollout) async {
    this.featureRollout = featureRollout;
    final sp = await SharedPreferences.getInstance();
    sp.setString('app.dev.feat', jsonEncode(featureRollout.toMap()));
  }

  Future<void> setFakeBatchInferenceBenchmarkEnabled(bool value) async {
    fakeBatchInferenceBenchmarkEnabled = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_fakeBatchInferenceBenchmarkPreferenceKey, value);
  }

  Future<int?> loadBatchViewportWidth() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_batchViewportWidthPreferenceKey);
  }

  Future<void> saveBatchViewportWidth(int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_batchViewportWidthPreferenceKey, value);
  }

  Future<void> setRenderMarkdownAndLatexEnabled(bool value) async {
    renderMarkdownAndLatex = value;
    renderMarkdownAndLatexEnabled.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_renderMarkdownAndLatexPreferenceKey, value);
  }

  Future<void> saveThinkingMode(thinking_mode.ThinkingMode value) async {
    preferredThinkingMode.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_thinkingModePreferenceKey, value.toString());
  }

  void setThinkingModeUserTemplate(PromptTemplate template) async {
    promptTemplate = template;
    final sp = await SharedPreferences.getInstance();
    sp.setString('app.promptTemplate', template.serialize());
  }

  void saveLastWorldModel(Map<String, dynamic> data) async {
    lastWorldModel.q = data;
    final sp = await SharedPreferences.getInstance();
    sp.setString("halo_state.lastWorldModel", jsonEncode(data));
  }

  void saveLastChatModel(Map<String, dynamic> data) async {
    lastChatModel.q = data;
    final sp = await SharedPreferences.getInstance();
    sp.setString("halo_state.lastChatModel", jsonEncode(data));
  }

  void setCustomModelsDir(String? path, {String? bookmark}) async {
    customModelsDir.q = path;
    customModelsDirBookmark.q = bookmark;
    final sp = await SharedPreferences.getInstance();
    if (path == null) {
      await sp.remove("halo_state.customModelsDir");
      await sp.remove("halo_state.customModelsDirBookmark");
    } else {
      await sp.setString("halo_state.customModelsDir", path);
      if (bookmark != null) {
        await sp.setString("halo_state.customModelsDirBookmark", bookmark);
      } else {
        await sp.remove("halo_state.customModelsDirBookmark");
      }
    }
    P.remote.checkLocal();
  }

  void setWeightsMigrationCompleted(bool completed) async {
    weightsMigrationCompleted.q = completed;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool("halo_state.weightsMigrationCompletedv640", completed);
  }

  void saveDecodeParamType(DecodeParamType type) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.decodeParamType", type.index);
  }

  void saveCustomDecodeParams() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.decodeParamType", DecodeParamType.custom.index);
    await sp.setDouble("halo_state.custom.temperature", P.rwkv.arguments(Argument.temperature).q);
    await sp.setDouble("halo_state.custom.topP", P.rwkv.arguments(Argument.topP).q);
    await sp.setDouble("halo_state.custom.presencePenalty", P.rwkv.arguments(Argument.presencePenalty).q);
    await sp.setDouble("halo_state.custom.frequencyPenalty", P.rwkv.arguments(Argument.frequencyPenalty).q);
    await sp.setDouble("halo_state.custom.penaltyDecay", P.rwkv.arguments(Argument.penaltyDecay).q);
  }

  void saveLatestSkippedBuildNumber(int buildNumber) async {
    latestSkippedBuildNumber.q = buildNumber;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.latestSkippedBuildNumber", buildNumber);
  }

  Future<void> setPreferredUIFont(String? fontFamily) async {
    preferredUIFont.q = fontFamily;
    final sp = await SharedPreferences.getInstance();
    if (fontFamily == null || fontFamily.isEmpty || fontFamily == 'System') {
      await sp.remove("halo_state.preferredUIFont");
    } else {
      // Try to load the font
      await P.font.loadFontByName(fontFamily);
    }
  }

  Future<void> setPreferredMessageLineHeight(double lineHeight) async {
    final normalizedLineHeight = lineHeight <= 0 ? messageLineHeightDefault : lineHeight;
    preferredMessageLineHeight.q = normalizedLineHeight;
    final sp = await SharedPreferences.getInstance();
    if (normalizedLineHeight <= 0) {
      await sp.remove(_messageLineHeightPreferenceKey);
      return;
    }
    await sp.setDouble(_messageLineHeightPreferenceKey, normalizedLineHeight);
  }

  Future<void> setPreferredMonospaceFont(String? fontFamily) async {
    preferredMonospaceFont.q = fontFamily;
    final sp = await SharedPreferences.getInstance();
    if (fontFamily == null || fontFamily.isEmpty || fontFamily == 'System') {
      await sp.remove("halo_state.preferredMonospaceFont");
    } else {
      await sp.setString("halo_state.preferredMonospaceFont", fontFamily);
      // Try to load the font
      await P.font.loadFontByName(fontFamily);
    }
  }

  Future<void> addPthFolderEntry(PthFolderEntry entry) async {
    if (pthFolderEntries.q.any((e) => e.path == entry.path)) return;
    pthFolderEntries.q = [...pthFolderEntries.q, entry];
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.pthFolderEntries", jsonEncode(pthFolderEntries.q.map((e) => e.toJson()).toList()));
  }

  Future<void> removePthFolderEntry(String path) async {
    qq;
    pthFolderEntries.q = pthFolderEntries.q.where((e) => e.path != path).toList();
    qqr("pthFolderEntries: ${pthFolderEntries.q.length}");
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.pthFolderEntries", jsonEncode(pthFolderEntries.q.map((e) => e.toJson()).toList()));
  }

  /// 加载已保存的 pth 文件夹条目；若仅有旧版 path 列表则迁移为 entries 并持久化
  Future<List<PthFolderEntry>> getPthFolderEntries() async {
    final sp = await SharedPreferences.getInstance();
    final entriesJson = sp.getString("halo_state.pthFolderEntries");
    if (entriesJson != null) {
      final list = jsonDecode(entriesJson) as List<dynamic>?;
      if (list != null) {
        pthFolderEntries.q = list.map((e) => PthFolderEntry.fromJson(e as Map<String, dynamic>)).toList();
        return pthFolderEntries.q;
      }
    }
    final legacyPaths = sp.getStringList("halo_state.pthFolderPaths");
    if (legacyPaths != null && legacyPaths.isNotEmpty) {
      pthFolderEntries.q = legacyPaths.map((p) => PthFolderEntry(path: p, bookmark: null)).toList();
      await sp.setString("halo_state.pthFolderEntries", jsonEncode(pthFolderEntries.q.map((e) => e.toJson()).toList()));
      return pthFolderEntries.q;
    }
    pthFolderEntries.q = [];
    return pthFolderEntries.q;
  }

  Future<void> setHasUnlinkDefaultModelsDirOnce(bool value) async {
    // TODO: remove getter after refactor P.init logic is done @wangce
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    hasUnlinkDefaultModelsDirOnce = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool("halo_state.hasUnlinkDefaultModelsDirOnce.$version.$buildNumber", value);
  }

  Future<void> saveDebugRenderNewlineDirectly(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_debugRenderNewlineDirectlyPreferenceKey, value);
  }

  Future<void> saveDebugRenderSpaceSymbol(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_debugRenderSpaceSymbolPreferenceKey, value);
  }

  Future<void> saveDebugShowPrefillLogOnly(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_debugShowPrefillLogOnlyPreferenceKey, value);
  }

  Future<void> setEnableSystemProxy(bool value) async {
    _enableSystemProxy = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool("halo_state.enableSystemProxy", value);
  }
}
