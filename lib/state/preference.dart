part of 'p.dart';

class _Preference {
  /// 空表示根据系统当前的 locale，在可选的 locale 中选择一个
  ///
  /// 非空表示使用指定的 locale
  late final preferredLanguage = qs<Language>(Language.none);

  /// 空表示根据系统当前的 textScaleFactor 来设置应用的 textScaleFactor
  ///
  /// 非空表示使用指定的 textScaleFactor
  late final preferredTextScaleFactor = qs<double>(-1.0);

  /// 偏好的主题模式设置，跟随系统、深色模式、浅色模式
  late final themeMode = qs<ThemeMode>(ThemeMode.system);

  /// 偏好的深色模式主题
  late final preferredDarkCustomTheme = qs<custom_theme.CustomTheme>(custom_theme.LightsOut());

  final textScaleFactorSystem = -1.0;

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

  @Deprecated("This is not used anymore")
  late final latestRuntimeAddress = qs<int>(0);

  late final dumpping = qs(false);

  bool isZhLang() => preferredLanguage.q.resolved.locale.languageCode == "zh";
}

/// Private methods
extension _$Preference on _Preference {
  FV _init() async {
    final sp = await SharedPreferences.getInstance();

    final language = sp.getString("halo_state.language");
    if (language != null) {
      final r = Language.values.firstWhereOrNull((e) => e.name == language) ?? Language.none;
      qqq("language: $language, r: $r");
      preferredLanguage.q = r;
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

    final latestRuntimeAddress = sp.getInt("halo_state.latestRuntimeAddress");
    if (latestRuntimeAddress != null) this.latestRuntimeAddress.q = latestRuntimeAddress;

    if (Platform.isAndroid && P.app.demoType.q == DemoType.world) {
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
  }

  FV _saveDumpping(bool dumpping) async {
    qqr("saveDumpping: $dumpping");
    this.dumpping.q = dumpping;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool("halo_state.dumpping", dumpping);
  }

  FV _saveLatestRuntimeAddress(int latestRuntimeAddress) async {
    qqr("saveLatestRuntimeAddress: $latestRuntimeAddress");
    this.latestRuntimeAddress.q = latestRuntimeAddress;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.latestRuntimeAddress", latestRuntimeAddress);
  }
}

/// Public methods
extension $Preference on _Preference {
  FV showTextScaleFactorDialog() async {
    final context = getContext();
    if (context == null) return;
    if (!context.mounted) return;
    final currentQ = preferredTextScaleFactor.q;
    final res = await showConfirmationDialog<double?>(
      context: context,
      title: S.current.font_setting,
      message: S.current.please_select_font_size,
      initialSelectedActionKey: currentQ,
      actions: textScalePairs.indexMap(
        (key, value) => AlertDialogAction<double>(
          label: value,
          key: key,
        ),
      ),
    );
    qqq("$res");

    if (res == null) return;

    preferredTextScaleFactor.q = res;
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble("halo_state.textScaleFactor", res);
  }

  FV showLocaleDialog() async {
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
  }

  FV showThemeSettings() async {
    final context = getContext();
    if (context == null) return;
    if (!context.mounted) return;
    await ThemeSelector.show();
  }
}
