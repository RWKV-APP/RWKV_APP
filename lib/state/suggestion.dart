part of 'p.dart';

class Suggestion {
  final String display;
  final String prompt;

  Suggestion({required this.display, required this.prompt});

  factory Suggestion.fromJson(dynamic json) {
    final display = json['display'] as String?;
    final prompt = json['prompt'];
    return Suggestion(
      display: display ?? prompt,
      prompt: prompt ?? display,
    );
  }
}

class SuggestionCategory {
  final String name;
  final List<Suggestion> items;

  const SuggestionCategory({required this.name, required this.items});

  factory SuggestionCategory.fromJson(dynamic json) {
    return SuggestionCategory(
      name: json['name'] as String,
      items: (json['items'] as Iterable).map((e) => Suggestion.fromJson(e)).toList(),
    );
  }
}

class SuggestionConfig {
  final List<SuggestionCategory> chat;
  final List<String> tts;
  final List<String> seeReasoningQa;
  final List<String> seeOcr;

  const SuggestionConfig({
    required this.chat,
    required this.tts,
    required this.seeReasoningQa,
    required this.seeOcr,
  });

  SuggestionConfig copyWith({
    List<SuggestionCategory>? chat,
    List<String>? tts,
    List<String>? seeReasoningQa,
    List<String>? seeOcr,
  }) {
    return SuggestionConfig(
      chat: chat ?? this.chat,
      tts: tts ?? this.tts,
      seeReasoningQa: seeReasoningQa ?? this.seeReasoningQa,
      seeOcr: seeOcr ?? this.seeOcr,
    );
  }

  factory SuggestionConfig.fromJson(dynamic json) {
    return SuggestionConfig(
      chat: (json['chat'] as Iterable).map((e) => SuggestionCategory.fromJson(e)).toList(),
      tts: (json['tts'] as Iterable).map((e) => e as String).toList(),
      seeReasoningQa: (json['see_reasoning_qa'] as Iterable).map((e) => e as String).toList(),
      seeOcr: (json['see_ocr'] as Iterable).map((e) => e as String).toList(),
    );
  }
}

class _Suggestion {
  /// All suggestion config
  final config = qs<SuggestionConfig>(_DefaultSuggestion.zh);

  /// suggestion prompt list at top of the text input
  /// item type: [String] or [Suggestion]
  final suggestion = qp<List<dynamic>>((ref) {
    final imagePath = ref.watch(P.world.imagePath);
    final demoType = ref.watch(P.app.demoType);
    final messages = ref.watch(P.msg.list);
    final currentModel = ref.watch(P.rwkv.currentModel);
    final lang = ref.watch(P.preference.preferredLanguage);
    final en = lang.resolved.locale.languageCode != "zh";
    final maxLen = en ? 30 : 14;

    final hideCases = [
      demoType == DemoType.chat && (messages.isNotEmpty || currentModel == null),
      demoType == DemoType.world && (imagePath == null || imagePath.isEmpty || messages.length != 1),
    ];
    if (hideCases.any((e) => e)) {
      return [];
    }
    final config = ref.watch(P.suggestion.config);
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);

    switch (demoType) {
      case DemoType.chat:
        final s = config.chat
            .map((e) => e.items)
            .flattened
            .shuffled()
            .where((e) => e.display.length < maxLen)
            /// NOTE: filter out long suggestions
            .toList();
        if (s.length < 5) {
          return s;
        }
        return s.take(5).toList();
      case DemoType.world:
        switch (currentWorldType) {
          case WorldType.reasoningQA:
            return config.seeReasoningQa;
          case WorldType.ocr:
            final s2 = config.seeOcr.shuffled;
            if (s2.length < 5) {
              return s2;
            }
            return s2.take(5).toList();
          default:
            break;
        }
        break;
      case DemoType.tts:
        return config.tts.toList().shuffled.take(5).toList();
      default:
        return [];
    }
    return [];
  });

  FV loadSuggestions() async {
    final shouldUseEn = P.preference.preferredLanguage.q.resolved.locale.languageCode != "zh";
    final lang = shouldUseEn ? "en" : "zh";
    dynamic config;
    try {
      config = await _get("http://120.77.3.4:3010/suggestions.json") as dynamic;
      if (config == null) {
        throw "empty response";
      }
      final sConfig = SuggestionConfig.fromJson(config[lang]);
      this.config.q = sConfig;
      _persistConfig(config);
    } catch (e) {
      qqe("load suggestions failed: $e");
      this.config.q = shouldUseEn ? _DefaultSuggestion.en : _DefaultSuggestion.zh;
      config = await _restoreConfig();
      if (config != null) {
        final sConfig = SuggestionConfig.fromJson(config[lang]);
        this.config.q = sConfig;
        qqq('config restored');
      }
      return;
    }
  }

  void _persistConfig(dynamic json) async {
    final dir = await getApplicationDocumentsDirectory();
    final cache = File("${dir.path}${Platform.pathSeparator}suggestion.json");
    if (cache.existsSync()) {
      await cache.delete();
    }
    await cache.create();
    final string = jsonEncode(json);
    cache.writeAsString(string);
  }

  Future<dynamic> _restoreConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cache = File("${dir.path}${Platform.pathSeparator}suggestion.json");
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

  @Deprecated('Deprecated')
  FV _loadSuggestions() async {
    final demoType = P.app.demoType.q;
    final shouldUseEn = P.preference.preferredLanguage.q.resolved.locale.languageCode != "zh";
    config.q = shouldUseEn ? _DefaultSuggestion.en : _DefaultSuggestion.zh;

    // TODO load suggestions from server

    if (demoType == DemoType.chat) {
      const head = "assets/config/chat/suggestions";
      final lang = shouldUseEn ? ".en-US" : ".zh-hans";
      final suffix = kDebugMode ? ".debug" : "";
      final assetPath = "$head$lang$suffix.json";
      final jsonString = await rootBundle.loadString(assetPath);
      final list = HF.list(jsonDecode(jsonString));

      final suggestions = list.map((e) => Suggestion(display: e['display'], prompt: e['prompt'])).toList();
      config.q = config.q.copyWith(
        chat: [
          SuggestionCategory(
            name: 'Default',
            items: suggestions,
          ),
        ],
      );
    }
  }
}

/// Private methods
extension _$Suggestion on _Suggestion {
  FV _init() async {
    qq;
  }
}

/// Public methods
extension $Suggestion on _Suggestion {}

class _DefaultSuggestion {
  static const SuggestionConfig zh = SuggestionConfig(
    chat: [],
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
