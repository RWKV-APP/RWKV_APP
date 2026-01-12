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

  late final userType = qs<UserType>(UserType.powerUser);

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

  /// Whether the weights migration to weights folder has been completed
  late final weightsMigrationCompleted = qs<bool>(false);

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
      this.userType.q = UserType.values.firstWhereOrNull((e) => e.index == userType) ?? UserType.user;
    }

    final latestRuntimeAddress = sp.getInt("halo_state.latestRuntimeAddress");
    if (latestRuntimeAddress != null) this.latestRuntimeAddress.q = latestRuntimeAddress;

    if (Platform.isAndroid && P.app.demoType.q == DemoType.see) {
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

    final weightsMigrationCompleted = sp.getBool("halo_state.weightsMigrationCompletedv640");
    if (weightsMigrationCompleted != null) this.weightsMigrationCompleted.q = weightsMigrationCompleted;
  }

  Future<void> _saveDumpping(bool dumpping) async {
    qqr("saveDumpping: $dumpping");
    this.dumpping.q = dumpping;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool("halo_state.dumpping", dumpping);
  }

  Future<void> _saveLatestRuntimeAddress(int latestRuntimeAddress) async {
    qqr("saveLatestRuntimeAddress: $latestRuntimeAddress");
    this.latestRuntimeAddress.q = latestRuntimeAddress;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.latestRuntimeAddress", latestRuntimeAddress);
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
        AlertDialogAction<UserType>(label: S.current.beginner, key: UserType.user),
        AlertDialogAction<UserType>(label: S.current.power_user, key: UserType.powerUser),
        AlertDialogAction<UserType>(label: S.current.expert, key: UserType.expert),
      ],
    );
    if (res == null) return;
    userType.q = res;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.user_type", res.index);
  }

  void goToFontSettings() {
    push(PageKey.fontSettings);
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

  void setCustomModelsDir(String? path) async {
    customModelsDir.q = path;
    final sp = await SharedPreferences.getInstance();
    if (path == null) {
      await sp.remove("halo_state.customModelsDir");
    } else {
      await sp.setString("halo_state.customModelsDir", path);
    }
    P.fileManager.checkLocal();
  }

  void setWeightsMigrationCompleted(bool completed) async {
    weightsMigrationCompleted.q = completed;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool("halo_state.weightsMigrationCompletedv640", completed);
  }
}
