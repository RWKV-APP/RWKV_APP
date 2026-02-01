part of 'p.dart';

class _Preference {
  // ===========================================================================
  // Static
  // ===========================================================================

  final textScaleFactorSystem = -1.0;

  // ===========================================================================
  // Instance
  // ===========================================================================

  bool _showBatteryOptimization = true;

  var featureRollout = const FeatureRollout();

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

  /// 偏好的主题模式设置，跟随系统、深色模式、浅色模式
  late final themeMode = qs<ThemeMode>(ThemeMode.system);

  /// 偏好的深色模式主题
  late final preferredDarkCustomTheme = qs<custom_theme.CustomTheme>(custom_theme.LightsOut());

  late final lastWorldModel = qs<Map<String, dynamic>?>(null);

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

  // ===========================================================================
  // Provider
  // ===========================================================================

  late final currentLangIsZh = qp((ref) {
    final preferredLanguage = ref.watch(P.preference.preferredLanguage);
    return preferredLanguage.resolved.locale.languageCode == "zh";
  });
}

/// Private methods
extension _$Preference on _Preference {
  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();

    _showBatteryOptimization = sp.getBool("halo_state.showBatteryOptimizationDialog") ?? true;

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
      this.preferredDarkCustomTheme.q = custom_theme.CustomTheme.fromString(preferredDarkCustomTheme) ?? custom_theme.LightsOut();
      if (this.preferredDarkCustomTheme.q is custom_theme.Light) {
        this.preferredDarkCustomTheme.q = custom_theme.LightsOut();
      }
    }

    final ft = sp.getString('app.dev.feat');
    if (ft != null && ft.isNotEmpty) {
      try {
        featureRollout = FeatureRollout.fromMap(jsonDecode(ft));
      } catch (_) {}
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
        final sp2 = await SharedPreferences.getInstance();
        await sp2.setString("halo_state.pthFolderEntries", jsonEncode(pthFolderEntries.q.map((e) => e.toJson()).toList()));
      }
    }
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
}
