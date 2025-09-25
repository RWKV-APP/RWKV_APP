// ignore_for_file: constant_identifier_names

import 'dart:ui';

enum Language {
  /// None
  none,

  /// English
  en,

  /// Russian
  ru,

  /// Japanese
  ja,

  /// Korean
  ko,

  /// generic simplified Chinese 'zh_Hans'
  zh_Hans,

  /// generic traditional Chinese 'zh_Hant'
  zh_Hant;

  String? get display => switch (this) {
    none => null,
    en => "English",
    ru => "Русский",
    ja => "日本語",
    ko => "한국어",
    zh_Hans => "简体中文",
    zh_Hant => "繁體中文",
  };

  String? get soundDisplay => switch (this) {
    none => null,
    en => "English",
    ru => "Русский",
    ja => "日本語",
    ko => "한국어",
    zh_Hans => "普通话",
    zh_Hant => "普通话",
  };

  String? get flag => switch (this) {
    none => null,
    en => "🇺🇸",
    ru => "🇷🇺",
    ja => "🇯🇵",
    ko => "🇰🇷",
    zh_Hans => "🇨🇳",
    zh_Hant => null,
  };

  String? get enName => switch (this) {
    none => null,
    en => "English",
    ru => "Russian",
    ja => "Japanese",
    ko => "Korean",
    zh_Hans => "Chinese",
    zh_Hant => null,
  };

  String? get jaName => switch (this) {
    none => null,
    en => "英語",
    ru => "ロシア語",
    ja => "日本語",
    ko => "韓国語",
    zh_Hans => "簡体中国語",
    zh_Hant => "繁体中国語",
  };

  // 영어 / 간체 중국어 / 번체 중국어 / 일본어 / 한국어
  String? get koName => switch (this) {
    none => null,
    en => "영어",
    ru => "러시아어",
    ja => "일본어",
    ko => "한국어",
    zh_Hans => "간체 중국어",
    zh_Hant => "번체 중국어",
  };

  String? get ruName => switch (this) {
    none => null,
    en => "Английский",
    ru => "Русский",
    ja => "Японский",
    ko => "Корейский",
    zh_Hans => "Китайский (упрощенный)",
    zh_Hant => "Китайский (традиционный)",
  };

  String? localizedName(Locale locale) => switch (locale.languageCode) {
    "en" => enName,
    "ru" => ruName,
    "ja" => jaName,
    "ko" => koName,
    "zh" => locale.scriptCode == 'Hans' ? zh_Hans.name : zh_Hant.name,
    _ => null,
  };

  bool get isCJK {
    return name.startsWith('zh') || this == ja || this == ko;
  }

  Language get resolved => switch (this) {
    none => fromSystemLocale(),
    _ => this,
  };

  Locale get locale {
    if (this == none) return PlatformDispatcher.instance.locale;

    final locale = name.split('_');
    final scriptCode = locale.length > 1 ? locale[1] : null;
    final countryCode = locale.length > 2 ? locale[2] : null;

    if (name.startsWith("zh")) {
      return Locale.fromSubtags(
        languageCode: locale[0],
        scriptCode: scriptCode,
        countryCode: countryCode,
      );
    }

    if (name.startsWith("pt")) {
      return Locale.fromSubtags(
        languageCode: locale[0],
        countryCode: locale.length > 1 ? locale[1] : null,
      );
    }
    return Locale(locale[0]);
  }

  static Language fromSystemLocale() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final languageCode = systemLocale.languageCode;
    final scriptCode = systemLocale.scriptCode;
    final countryCode = systemLocale.countryCode;

    // Handle Chinese variants
    if (languageCode == 'zh') {
      if (scriptCode == 'Hant') return Language.zh_Hant;
      if (scriptCode == 'Hans') return Language.zh_Hans;

      // If scriptCode is null, infer from countryCode
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        return Language.zh_Hant;
      }
      return Language.zh_Hans; // default to simplified
    }

    // Exact match to enum name
    for (final lang in Language.values) {
      if (lang.name == languageCode) {
        return lang;
      }
    }

    // Fallback
    return Language.en;
  }
}
