part of 'p.dart';

const String _suggestionCacheFileName = "suggestion.json";
const String _highScoreSuggestionCacheFileName = "suggestion_high_score.json";
const int _chatSuggestionCount = 5;
const double _chatSuggestionHighScoreThreshold = 9.0;

class Suggestion {
  final String display;
  final String prompt;
  final double? score;
  final String? category;

  Suggestion({
    required this.display,
    required this.prompt,
    this.score,
    this.category,
  });

  factory Suggestion.fromJson(
    dynamic json, {
    String? category,
  }) {
    final display = json['display'] as String?;
    final prompt = json['prompt'];
    return Suggestion(
      display: display ?? prompt,
      prompt: prompt ?? display,
      category: category ?? json['category']?.toString(),
    );
  }

  factory Suggestion.fromHighScoreJson(
    dynamic json, {
    String? category,
  }) {
    final title = json['title']?.toString().trim() ?? "";
    final prompt = json['prompt']?.toString().trim() ?? "";
    final score = (json['score'] as num?)?.toDouble();
    final display = title.isNotEmpty ? title : prompt;
    final resolvedPrompt = prompt.isNotEmpty ? prompt : display;
    return Suggestion(
      display: display,
      prompt: resolvedPrompt,
      score: score,
      category: category ?? json['category']?.toString(),
    );
  }
}

class SuggestionCategory {
  final String key;
  final String name;
  final List<Suggestion> items;

  const SuggestionCategory({
    required this.key,
    required this.name,
    required this.items,
  });

  factory SuggestionCategory.fromJson(dynamic json) {
    final key = (json['category']?.toString() ?? json['name']?.toString() ?? '').trim();
    final name = (json['name']?.toString() ?? key).trim();
    return SuggestionCategory(
      key: key,
      name: name,
      items: (json['items'] as Iterable).map((e) => Suggestion.fromJson(e, category: key)).toList(),
    );
  }
}

class SuggestionConfig {
  final List<SuggestionCategory> chat;
  final List<String> completion;
  final List<String> tts;
  final List<String> seeReasoningQa;
  final List<String> seeOcr;

  const SuggestionConfig({
    required this.chat,
    required this.tts,
    required this.completion,
    required this.seeReasoningQa,
    required this.seeOcr,
  });

  SuggestionConfig copyWith({
    List<SuggestionCategory>? chat,
    List<String>? tts,
    List<String>? seeReasoningQa,
    List<String>? completion,
    List<String>? seeOcr,
  }) {
    return SuggestionConfig(
      chat: chat ?? this.chat,
      tts: tts ?? this.tts,
      completion: completion ?? this.completion,
      seeReasoningQa: seeReasoningQa ?? this.seeReasoningQa,
      seeOcr: seeOcr ?? this.seeOcr,
    );
  }

  factory SuggestionConfig.fromJson(dynamic json) {
    return SuggestionConfig(
      chat: (json['chat'] as Iterable).map((e) => SuggestionCategory.fromJson(e)).toList(),
      tts: (json['tts'] as Iterable).map((e) => e as String).toList(),
      completion: (json['completion'] as Iterable?)?.map((e) => e as String).toList() ?? [],
      seeReasoningQa: (json['see_reasoning_qa'] as Iterable).map((e) => e as String).toList(),
      seeOcr: (json['see_ocr'] as Iterable).map((e) => e as String).toList(),
    );
  }
}

class _Suggestion {
  // ===========================================================================
  // StateProvider
  // ===========================================================================

  /// All suggestion config
  final config = qs(_DefaultSuggestion.zh);

  final ttsTicker = qs(0);

  /// Whether the high-score API is active for current language
  final useHighScoreApi = qs(false);

  /// All categories from the high-score API (for "more" dialog)
  final highScoreCategories = qs<List<SuggestionCategory>>(const []);

  /// Suggestions with score >= 9.0 (for empty page random display)
  final highScoreTopSuggestions = qs<List<Suggestion>>(const []);

  /// Cached shuffled chat suggestions (only refreshed explicitly)
  final chatSuggestions = qs<List<Suggestion>>(const []);

  // ===========================================================================
  // Provider
  // ===========================================================================

  /// Suggestion list for the empty-state UI.
  /// Item type: [String] or [Suggestion].
  late final suggestion = qp<List<dynamic>>((ref) {
    final demoType = ref.watch(P.app.demoType);
    final messages = ref.watch(P.msg.list);

    switch (demoType) {
      case .chat:
        if (messages.isNotEmpty) return [];
        return ref.watch(chatSuggestions);
      case .see:
        final imagePath = ref.watch(P.see.imagePath);
        if (imagePath == null || imagePath.isEmpty || messages.length != 1) return [];
        return _seeSuggestions(ref);
      case .tts:
        final _ = ref.watch(ttsTicker);
        final config = ref.watch(this.config);
        return _buildMixedTalkSuggestions(config.tts);
      default:
        return [];
    }
  });

  List<dynamic> _seeSuggestions(Ref ref) {
    final config = ref.watch(this.config);
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);

    switch (currentWorldType) {
      case WorldType.reasoningQA:
        return config.seeReasoningQa;
      case WorldType.ocr:
        final shuffled = config.seeOcr.shuffled;
        if (shuffled.length < 5) return shuffled;
        return shuffled.take(5).toList();
      case WorldType.modrwkvV2:
      case WorldType.modrwkvV3:
        return [...config.seeReasoningQa, ...config.seeOcr].shuffled.take(5).toList();
      case null:
        return [];
    }
  }

  final worldSuggestion = qp<List<String>>((ref) {
    final _ = ref.watch(P.suggestion.ttsTicker);
    final _ = ref.watch(P.rwkv.latestModel);
    final _ = ref.watch(P.msg.length);

    final config = ref.watch(P.suggestion.config);

    final currentWorldType = ref.watch(P.rwkv.currentWorldType);

    switch (currentWorldType) {
      case WorldType.reasoningQA:
        return config.seeReasoningQa;
      case WorldType.ocr:
        return config.seeOcr;
      case WorldType.modrwkvV2:
      case WorldType.modrwkvV3:
        return config.seeReasoningQa;
      case null:
        return [];
    }
  });

  final talkSuggestion = qp<List<String>>((ref) {
    final _ = ref.watch(P.suggestion.ttsTicker);
    final _ = ref.watch(P.rwkv.latestModel);
    final _ = ref.watch(P.msg.length);

    final config = ref.watch(P.suggestion.config);

    return _buildMixedTalkSuggestions(config.tts);
  });

  Future<void> loadSuggestions({bool forceChatMode = false}) async {
    final language = P.preference.preferredLanguage.q.resolved;
    final lang = _suggestionLang(language);
    final fallbackConfig = lang == "en" ? _DefaultSuggestion.en : _DefaultSuggestion.zh;
    SuggestionConfig effectiveConfig = fallbackConfig;
    dynamic remoteConfig;

    try {
      remoteConfig = await _get(Config.suggestionsUrl) as dynamic;
      if (remoteConfig == null) {
        throw "empty response";
      }
      effectiveConfig = SuggestionConfig.fromJson(remoteConfig[lang]);
      _persistConfig(remoteConfig, fileName: _suggestionCacheFileName);
    } catch (e) {
      qqe("load suggestions failed: $e");
      remoteConfig = await _restoreConfig(fileName: _suggestionCacheFileName);
      if (remoteConfig != null) {
        effectiveConfig = SuggestionConfig.fromJson(remoteConfig[lang]);
        qqq('config restored');
      }
    }

    config.q = effectiveConfig;

    final isChatMode = forceChatMode || P.app.demoType.q == .chat;
    if (isChatMode) {
      await _tryLoadHighScoreSuggestions(language);
    }

    refreshChatSuggestions();
  }

  Future<void> _tryLoadHighScoreSuggestions(Language language) async {
    final categories = await _loadHighScoreChatSuggestions(language);
    if (categories == null) {
      useHighScoreApi.q = false;
      highScoreCategories.q = const [];
      highScoreTopSuggestions.q = const [];
      return;
    }
    useHighScoreApi.q = true;
    highScoreCategories.q = categories;
    final allItems = categories.map((e) => e.items).flattened.toList();
    highScoreTopSuggestions.q = allItems.where((e) => e.score != null && e.score! >= _chatSuggestionHighScoreThreshold).toList();
  }

  String _suggestionLang(Language language) {
    if (language.locale.languageCode == "zh") {
      return "zh";
    }
    return "en";
  }

  String _languageToApiCode(Language language) {
    final locale = language.locale;
    final scriptCode = locale.scriptCode;
    if (scriptCode != null && scriptCode.isNotEmpty) {
      return "${locale.languageCode}-$scriptCode";
    }
    return locale.languageCode;
  }

  Future<List<SuggestionCategory>?> _loadHighScoreChatSuggestions(Language language) async {
    try {
      final supportedLanguagesResponse = await _get(
        Config.highScoreLanguagesUrl,
        ea: const [_EA.console],
      );
      if (supportedLanguagesResponse == null) {
        throw "empty language response";
      }

      final supportedLanguages = _parseHighScoreLanguages(supportedLanguagesResponse);
      final currentLanguageCode = _languageToApiCode(language);
      if (!supportedLanguages.contains(currentLanguageCode)) {
        return null;
      }

      final response = await _get(
        Config.highScoreSamplesUrl,
        ea: const [_EA.console],
      );
      if (response == null) {
        throw "empty sample response";
      }

      final categories = _parseHighScoreCategories(response);
      _persistConfig(
        response,
        fileName: _highScoreSuggestionCacheFileName,
      );
      return categories;
    } catch (e) {
      qqe("load high score suggestions failed: $e");
      final cachedResponse = await _restoreConfig(fileName: _highScoreSuggestionCacheFileName);
      if (cachedResponse == null) {
        return null;
      }
      final categories = _parseHighScoreCategories(cachedResponse);
      qqq("high score suggestions restored");
      return categories;
    }
  }

  List<String> _parseHighScoreLanguages(dynamic json) {
    if (json is! Iterable) {
      throw "invalid high score language response";
    }
    return json.map((e) => e.toString()).toList();
  }

  List<SuggestionCategory> _parseHighScoreCategories(dynamic json) {
    if (json is! Map) {
      throw "invalid high score sample response";
    }
    final categories = json["categories"];
    if (categories is! Iterable) {
      throw "invalid high score categories";
    }
    return categories.map((e) {
      final key = e['category']?.toString().trim() ?? '';
      final name = e['categoryDisplayName']?.toString().trim() ?? key;
      final items = (e['items'] as Iterable?)?.map((item) => Suggestion.fromHighScoreJson(item, category: key)).toList() ?? [];
      return SuggestionCategory(
        key: key,
        name: name,
        items: items,
      );
    }).toList();
  }

  void _persistConfig(
    dynamic json, {
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final cache = File(join(dir.path, fileName));
    if (cache.existsSync()) {
      await cache.delete();
    }
    await cache.create();
    final string = jsonEncode(json);
    cache.writeAsString(string);
  }

  Future<dynamic> _restoreConfig({
    required String fileName,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cache = File(join(dir.path, fileName));
      if (!cache.existsSync()) {
        return null;
      }
      final json = await cache.readAsString();
      if (json.isEmpty) {
        return null;
      }
      return jsonDecode(json);
    } catch (e) {
      return null;
    }
  }
}

/// Private methods
extension _$Suggestion on _Suggestion {
  Future<void> _init() async {
    await loadSuggestions();
    P.app.pageKey.l(_onPageKeyChanged);
    P.preference.preferredLanguage.lv(loadSuggestions);
  }

  void _onPageKeyChanged(PageKey pageKey) {
    if (pageKey != .chat && pageKey != .neko) return;
    unawaited(loadSuggestions(forceChatMode: true));
  }
}

/// Public methods
extension $Suggestion on _Suggestion {
  List<String> pickRandomChatPrompts(
    int count, {
    List<String> exclude = const <String>[],
  }) {
    final excludeSet = exclude.map(_normalizePromptDedupeKey).where((item) => item.isNotEmpty).toSet();
    final seen = <String>{};
    final prompts = <String>[];
    final pool = <Suggestion>[
      if (useHighScoreApi.q && highScoreTopSuggestions.q.isNotEmpty) ...highScoreTopSuggestions.q,
      ...config.q.chat.expand((category) => category.items),
    ].shuffled;

    for (final suggestion in pool) {
      final prompt = suggestion.prompt.trim();
      if (prompt.isEmpty) continue;
      final dedupeKey = _normalizePromptDedupeKey(prompt);
      if (excludeSet.contains(dedupeKey)) continue;
      if (seen.contains(dedupeKey)) continue;
      seen.add(dedupeKey);
      prompts.add(prompt);
      if (prompts.length >= count) return prompts;
    }

    return prompts;
  }

  void refreshChatSuggestions() {
    final useHighScore = useHighScoreApi.q;
    if (useHighScore) {
      final categories = _buildHighScoreChatSuggestionCategories(highScoreCategories.q);
      chatSuggestions.q = _pickChatSuggestionsByCategory(categories);
      return;
    }
    chatSuggestions.q = _pickChatSuggestionsByCategory(config.q.chat);
  }
}

String _normalizePromptDedupeKey(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<SuggestionCategory> _buildHighScoreChatSuggestionCategories(
  List<SuggestionCategory> categories,
) {
  final filtered = <SuggestionCategory>[];
  for (final category in categories) {
    final items = category.items.where((item) => item.score != null && item.score! >= _chatSuggestionHighScoreThreshold).toList();
    if (items.isEmpty) continue;
    filtered.add(
      SuggestionCategory(
        key: category.key,
        name: category.name,
        items: items,
      ),
    );
  }
  return filtered;
}

List<Suggestion> _pickChatSuggestionsByCategory(
  List<SuggestionCategory> categories,
) {
  final availableCategories = categories.where((category) => category.items.isNotEmpty).toList();
  if (availableCategories.isEmpty) return const [];

  final selectedCategories = availableCategories.shuffled.take(min(_chatSuggestionCount, availableCategories.length)).toList();
  final suggestions = <Suggestion>[];

  for (final category in selectedCategories) {
    final items = category.items.shuffled;
    if (items.isEmpty) continue;
    suggestions.add(items.first);
  }

  return suggestions;
}

List<String> _buildMixedTalkSuggestions(List<String> rawSuggestions) {
  const totalCount = _chatSuggestionCount;
  const intonationCount = 1;
  const normalCount = totalCount - intonationCount;

  final normalSuggestions = rawSuggestions.toList().shuffled.toList();
  final selectedNormal = normalSuggestions.length <= normalCount ? normalSuggestions : normalSuggestions.take(normalCount).toList();

  final intonationSuggestions = _buildIntonationSuggestionDisplays().shuffled.toList();
  if (intonationSuggestions.isEmpty) {
    if (normalSuggestions.length <= totalCount) return normalSuggestions;
    return normalSuggestions.take(totalCount).toList();
  }

  final mixed = <String>[
    ...selectedNormal,
    intonationSuggestions.first,
  ];
  return mixed.shuffled.toList();
}

List<String> _buildIntonationSuggestionDisplays() {
  return TTSInstruction.intonation.options.indexMap((index, option) {
    final emoji = TTSInstruction.intonation.emojiOptions[index];
    return "$emoji$option";
  });
}

class _DefaultSuggestion {
  static const SuggestionConfig zh = SuggestionConfig(
    chat: [],
    completion: [],
    tts: [
      "一二三四五，上山打老虎！",
      "一日不见，如三秋兮",
      "世界那么大，我想去看看",
      "人生若只如初见，何事秋风悲画扇",
      "你笑起来真像好天气",
      "做自己喜欢的事，遇见志同道合的人",
      "别让昨天的沮丧，毁掉今天的美好",
      "在最好的年纪，做最疯狂的事",
      "失败是成功之母，不要轻易放弃",
      "奥利给！",
      "心有猛虎，细嗅蔷薇",
      "愿你出走半生，归来仍是少年",
      "所有伟大，源于一个勇敢的开始",
      "时间会告诉我们，简单的喜欢最长远",
      "星辰大海，是我永恒的向往",
      "春风十里，不如你",
      "月亮不睡我不睡",
      "有趣的灵魂终会相遇",
      "来了老弟！",
      "梦想是注定孤独的旅行",
      "每一个不曾起舞的日子，都是对生命的辜负",
      "生活不止眼前的苟且，还有诗和远方",
      "贫穷限制了我的想象力",
      "长风破浪会有时，直挂云帆济沧海",
      "颜值即正义",
      "风雨之后，必见彩虹",
    ],
    seeReasoningQa: [
      "请向我描述这张图片",
      "Please describe this image for me~",
    ],
    seeOcr: [
      "请向我描述这张图片",
      "Please describe this image for me~",
      "图片上的文字是什么意思？",
      "可以帮我识别一下这张图片上的文字吗？",
      "图片里的文字内容是什么？",
      "这张图片里写了什么？",
      "What does the text in the image mean?",
      "Can you help me recognize the text on this image?",
      "What is the text content in this image?",
      "What is written in this image?",
      "What do you see in this picture?",
    ],
  );

  static const SuggestionConfig en = SuggestionConfig(
    chat: [],
    completion: [],
    tts: [
      "Believe in yourself and all that you are",
      "Dream big and dare to fail",
      "Stay hungry, stay foolish",
      "The best is yet to come",
      "You are stronger than you think",
      "Every day is a second chance",
      "Do what you love, love what you do",
      "Life is short, make it sweet",
      "Be a voice, not an echo",
      "Happiness looks good on you",
      "Let your dreams be bigger than your fears",
      "The sky is not the limit, it's just the view",
      "Difficult roads often lead to beautiful destinations",
      "Stay close to people who feel like sunshine",
      "Create your own sunshine",
      "Good vibes only",
      "You are enough",
      "Chase the sun",
      "Kindness changes everything",
      "Stars can't shine without darkness",
      "Smile, it's free therapy",
      "Progress, not perfection",
      "Adventure is out there",
      "Keep going, keep growing",
      "Magic is something you make",
      "Breathe. Everything is going to be okay",
      "Radiate positivity",
      "Nothing worth having comes easy",
      "Today is a perfect day to start",
      "Find joy in the ordinary",
    ],
    seeReasoningQa: [
      "请向我描述这张图片",
      "Please describe this image for me~",
    ],
    seeOcr: [
      "请向我描述这张图片",
      "Please describe this image for me~",
      "图片上的文字是什么意思？",
      "可以帮我识别一下这张图片上的文字吗？",
      "图片里的文字内容是什么？",
      "这张图片里写了什么？",
      "What does the text in the image mean?",
      "Can you help me recognize the text on this image?",
      "What is the text content in this image?",
      "What is written in this image?",
      "What do you see in this picture?",
    ],
  );
}
