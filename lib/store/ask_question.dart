part of 'p.dart';

const _askQuestionPrefixes = <Language, List<String>>{
  .zh_Hans: [
    '为什么',
    '如果',
    '请扮演',
    '请设计',
    '请解释',
    '请以',
    '请从',
    '请推荐',
    '请构建',
    '请为',
  ],
  .zh_Hant: [
    '為什麼',
    '如果',
    '請扮演',
    '請設計',
    '請解釋',
    '請以',
    '請從',
    '請推薦',
    '請構建',
    '請為',
  ],
  .en: [
    'Why ',
    'How ',
    'What ',
    'Can you ',
    'Could you ',
    'Explain ',
    'Design ',
    'Recommend ',
    'If ',
    'Assume ',
  ],
  .ja: [
    'なぜ',
    'どうして',
    'どうやって',
    '説明してください',
    '教えてください',
    '設計してください',
    'おすすめしてください',
    'もし',
    '仮に',
    '想像してください',
  ],
  .ko: [
    '왜 ',
    '어떻게 ',
    '무엇이 ',
    '설명해 주세요 ',
    '설계해 주세요 ',
    '추천해 주세요 ',
    '만들어 주세요 ',
    '만약 ',
    '가정해 보면 ',
    '누구 ',
  ],
  .ru: [
    'Почему ',
    'Как ',
    'Что ',
    'Объясни ',
    'Опиши ',
    'Покажи ',
    'Предложи ',
    'Разработай ',
    'Если ',
    'Представь ',
  ],
};

class _AskQuestion {
  Timer? _getResponseTimer;
  Timer? _panelAutoGenerateTimer;
  StreamSubscription<from_rwkv.FromRWKV>? _albatrossSubscription;
  DateTime? _lastRawQuestionsChangedAt;
  int? _runningModelID;
  bool _stopRequested = false;
  List<String> _lastRawQuestions = const [];
  List<String> _runningPrefixes = const [];

  late final language = qs<Language>(.zh_Hans);
  late final generating = qs(false);
  late final questions = qs<List<String>>([]);
  late final rawQuestions = qs<List<String>>([]);
  late final parallelCount = qs(1);
  late final lastTranscript = qs("");

  late final maxParallelCount = qp((ref) {
    final currentModel = ref.watch(P.rwkv.latestModel);
    if (currentModel == null) return 1;

    final batchAllowed = currentModel.tags.contains("batch");
    if (!batchAllowed) return 1;

    final supportedBatchSizes = ref.watch(P.rwkv.supportedBatchSizes);
    if (supportedBatchSizes.isEmpty) return 1;

    return supportedBatchSizes.max;
  });

  late final currentTranscript = qp((ref) {
    final _ = ref.watch(P.msg.list);
    final messages = _buildHistoryMessagesForQuestionGeneration();
    return _buildTranscriptFromMessages(messages);
  });

  late final hasChatHistory = qp((ref) {
    final transcript = ref.watch(currentTranscript);
    return transcript.trim().isNotEmpty;
  });

  late final defaultLanguage = qp((ref) {
    final preferredLanguage = ref.watch(P.preference.preferredLanguage);
    return _resolveLanguage(preferredLanguage.resolved);
  });

  late final languageSwitched = qp((ref) {
    final selectedLanguage = ref.watch(language);
    final defaultLanguage = ref.watch(this.defaultLanguage);
    return selectedLanguage != defaultLanguage;
  });

  late final shouldGenerateWithoutContext = qp((ref) {
    final hasChatHistory = ref.watch(this.hasChatHistory);
    final languageSwitched = ref.watch(this.languageSwitched);
    return hasChatHistory && languageSwitched;
  });
}

/// Private methods
extension _$AskQuestion on _AskQuestion {
  Language _resolveLanguage(Language preferredLanguage) {
    return switch (preferredLanguage) {
      .zh_Hant => .zh_Hant,
      .ja => .ja,
      .ko => .ko,
      .ru => .ru,
      .en => .en,
      _ => .zh_Hans,
    };
  }

  Future<void> _init() async {
    final preferredLanguage = P.preference.preferredLanguage.q.resolved;
    language.q = _resolveLanguage(preferredLanguage);

    P.rwkv.broadcastStream.listen(
      _onStreamEvent,
      onDone: _onStreamDone,
      onError: _onStreamError,
    );
  }

  void _cancelRunningTasks() {
    _getResponseTimer?.cancel();
    _getResponseTimer = null;
    _panelAutoGenerateTimer?.cancel();
    _panelAutoGenerateTimer = null;
    _albatrossSubscription?.cancel();
    _albatrossSubscription = null;
  }

  void _onStreamDone() async {
    if (!generating.q) return;
    _finalizeQuestions();
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    if (!generating.q) return;
    qqe("ask question stream error: $error");
    if (!kDebugMode) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
    _finalizeQuestions();
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    if (!generating.q) return;

    switch (event) {
      case from_rwkv.ResponseBatchBufferContent res:
        if (parallelCount.q <= 1) return;
        _updateQuestionsFromRaw(res.responseBufferContent);
        if (res.eosFound.isNotEmpty && res.eosFound.every((item) => item)) {
          _finalizeQuestions();
        }
      case from_rwkv.ResponseBufferContent res:
        if (parallelCount.q != 1) return;
        _updateQuestionsFromRaw([res.responseBufferContent]);
        if (res.eosFound) {
          _finalizeQuestions();
        }
      case from_rwkv.IsGenerating res:
        final runningModelID = _runningModelID;
        if (runningModelID != null && res.modelID != runningModelID) return;
        if (res.isGenerating) return;
        _finalizeQuestions();
      case from_rwkv.GenerateStop _:
        _finalizeQuestions();
      default:
        break;
    }
  }

  void _updateQuestionsFromRaw(List<String> nextRawQuestions) {
    final effectiveRawQuestions = _mergePrefixesIntoRawQuestions(nextRawQuestions);
    rawQuestions.q = effectiveRawQuestions;

    final cleanedQuestions = _dedupeQuestions(
      effectiveRawQuestions.map((raw) => raw.trim()),
    );
    questions.q = cleanedQuestions;
    _maybeStopSettledGeneration(cleanedQuestions);
  }

  void _finalizeQuestions() {
    _cancelRunningTasks();
    generating.q = false;
    P.rwkv.generating.q = false;
    _refreshChatModelGeneratingState();

    final finalizedQuestions = _dedupeQuestions(
      rawQuestions.q.map((raw) => raw.trim()),
    );
    questions.q = finalizedQuestions;
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _runningModelID = null;
    _runningPrefixes = const [];
    _stopRequested = false;
  }

  void _maybeStopSettledGeneration(List<String> currentQuestions) {
    if (P.rwkv.isAlbatrossLoaded.q) return;
    if (_stopRequested) return;
    if (currentQuestions.isEmpty) return;

    if (!_sameQuestionList(_lastRawQuestions, currentQuestions)) {
      _lastRawQuestions = [...currentQuestions];
      _lastRawQuestionsChangedAt = DateTime.now();
      return;
    }

    final changedAt = _lastRawQuestionsChangedAt;
    if (changedAt == null) {
      _lastRawQuestionsChangedAt = DateTime.now();
      return;
    }

    final settledFor = DateTime.now().difference(changedAt);
    if (settledFor < const Duration(seconds: 2)) return;

    final modelID = _runningModelID;
    if (modelID == null) return;

    _stopRequested = true;
    P.rwkv.send(to_rwkv.Stop(modelID: modelID));
  }

  bool _sameQuestionList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  List<String> _mergePrefixesIntoRawQuestions(List<String> rawQuestions) {
    if (_runningPrefixes.isEmpty) return rawQuestions;

    final result = <String>[];
    final count = math.min(rawQuestions.length, _runningPrefixes.length);
    for (int i = 0; i < count; i++) {
      final raw = rawQuestions[i];
      if (raw.trim().isEmpty) {
        result.add("");
        continue;
      }
      result.add(_mergePrefixIntoRawQuestion(prefix: _runningPrefixes[i], raw: raw));
    }

    if (rawQuestions.length <= count) return result;

    for (int i = count; i < rawQuestions.length; i++) {
      result.add(rawQuestions[i]);
    }

    return result;
  }

  String _mergePrefixIntoRawQuestion({
    required String prefix,
    required String raw,
  }) {
    final trimmedPrefix = prefix.trim();
    if (trimmedPrefix.isEmpty) return raw;

    final trimmedRaw = raw.trimLeft();
    if (trimmedRaw.isEmpty) return raw;

    if (trimmedRaw.toLowerCase().startsWith(trimmedPrefix.toLowerCase())) return raw;

    return "$prefix$raw";
  }

  List<String> _buildHistoryMessagesForQuestionGeneration() {
    final allMessages = P.msg.list.q.where((message) => message.type == MessageType.text).toList();
    if (allMessages.isEmpty) return const [];

    int startIndex = math.max(0, allMessages.length - 12);
    if (startIndex.isOdd) {
      startIndex = math.max(0, startIndex - 1);
    }
    final scopedMessages = allMessages.sublist(startIndex).toList();
    if (scopedMessages.length.isOdd) {
      scopedMessages.removeLast();
    }

    final messages = <String>[];
    for (int i = 0; i < scopedMessages.length; i = i + 2) {
      final userMsg = scopedMessages[i];
      final botMsg = i + 1 < scopedMessages.length ? scopedMessages[i + 1] : null;
      if (botMsg == null) continue;

      final userContent = userMsg.getContentForHistoryWithRef(botMsg.reference).trim();
      if (userContent.isEmpty) continue;

      final botContent = botMsg.getHistoryContent().trim();
      if (botContent.isEmpty) continue;

      messages.add(userContent);
      messages.add(botContent);
    }

    return messages;
  }

  String _buildTranscriptFromMessages(List<String> messages) {
    if (messages.isEmpty) return "";

    final lines = <String>[];
    for (int i = 0; i < messages.length; i++) {
      final role = i.isEven ? "User" : "Assistant";
      lines.add("$role: ${messages[i]}");
    }

    return _trimTranscript(lines.join("\n\n"));
  }

  int _resolveParallelCount({
    int? cap,
  }) {
    if (P.rwkv.isAlbatrossLoaded.q) return 1;

    final currentModel = P.rwkv.latestModel.q;
    if (currentModel == null) return 1;

    final batchAllowed = currentModel.tags.contains("batch");
    if (!batchAllowed) return 1;

    final supportedBatchSizes = P.rwkv.supportedBatchSizes.q;
    if (supportedBatchSizes.isEmpty) return 1;

    final maxBatchSize = supportedBatchSizes.max;
    if (maxBatchSize <= 0) return 1;

    if (cap == null) return maxBatchSize;

    return math.min(maxBatchSize, cap);
  }

  Future<void> _startPolling({required int modelID, required bool isBatchInference}) async {
    _getResponseTimer?.cancel();
    _getResponseTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (isBatchInference) {
        P.rwkv.send(to_rwkv.GetBatchResponseBufferContent(messages: [], modelID: modelID));
      } else {
        P.rwkv.send(to_rwkv.GetResponseBufferContent(messages: [], modelID: modelID));
      }
      P.rwkv.send(to_rwkv.GetIsGenerating(modelID: modelID));
      P.rwkv.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    });
  }

  Future<bool> _ensureChatModelIdle({required int modelID}) async {
    if (!P.rwkv.generating.q) return true;
    if (generating.q) return false;

    final request = to_rwkv.GetIsGenerating(modelID: modelID);
    P.rwkv.send(request);

    try {
      final response = await P.rwkv.broadcastStream
          .whereType<from_rwkv.IsGenerating>()
          .firstWhere((event) => event.req == request)
          .timeout(const Duration(milliseconds: 400));
      P.rwkv.generating.q = response.isGenerating;
      return !response.isGenerating;
    } catch (_) {
      return false;
    }
  }

  void _refreshChatModelGeneratingState() {
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) return;
    P.rwkv.send(to_rwkv.GetIsGenerating(modelID: modelID));
  }

  Future<void> _startAlbatrossCompletion({required String prompt}) async {
    final stream = Albatross.instance.completion(prompt, batchSize: 1);
    _albatrossSubscription = stream.listen(
      _onStreamEvent,
      onDone: _onStreamDone,
      onError: _onStreamError,
    );
  }

  String _trimTranscript(String transcript) {
    final normalized = transcript.replaceAll("\r\n", "\n").replaceAll("\r", "\n").trim();
    if (normalized.isEmpty) return "";

    const maxChars = 3200;
    if (normalized.length <= maxChars) return normalized;

    return "...\n${normalized.substring(normalized.length - maxChars)}";
  }

  List<String> _dedupeQuestions(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized)) continue;
      result.add(normalized);
    }

    return result;
  }
}

/// Public methods
extension $AskQuestion on _AskQuestion {
  void onPanelShown() {
    _panelAutoGenerateTimer?.cancel();
    _panelAutoGenerateTimer = Timer(const Duration(milliseconds: 100), () async {
      if (generating.q) return;
      await generateFromCurrentChat();
    });
  }

  void onPanelHidden() {
    _panelAutoGenerateTimer?.cancel();
    _panelAutoGenerateTimer = null;
    if (!generating.q) return;
    _pauseGeneration();
    questions.q = [];
    rawQuestions.q = [];
  }

  void pauseGeneration() {
    if (!generating.q) return;
    _pauseGeneration();
  }

  void _pauseGeneration() {
    final modelID = _runningModelID;
    if (modelID != null) {
      P.rwkv.send(to_rwkv.Stop(modelID: modelID));
    }

    _cancelRunningTasks();

    generating.q = false;
    P.rwkv.generating.q = false;
    _refreshChatModelGeneratingState();
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _runningModelID = null;
    _runningPrefixes = const [];
    _stopRequested = false;
  }

  void selectLanguage(Language nextLanguage) {
    if (generating.q) return;
    if (language.q == nextLanguage) return;
    language.q = nextLanguage;
    questions.q = [];
    rawQuestions.q = [];
  }

  Future<void> generateFromCurrentChat() async {
    final historyMessages = _buildHistoryMessagesForQuestionGeneration();
    if (historyMessages.isNotEmpty && !shouldGenerateWithoutContext.q) {
      await generateFromMessages(historyMessages);
      return;
    }

    final targetLanguage = language.q;
    final prefixes = _askQuestionPrefixes[targetLanguage] ?? const [];
    if (prefixes.isEmpty) {
      Alert.info(S.current.chat_empty_message);
      return;
    }

    await _generateFromDefaultPrefixes(
      language: targetLanguage,
      prefixes: prefixes,
    );
  }

  Future<void> generateFromMessages(
    List<String> historyMessages, {
    Language? preferredLanguage,
  }) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      Alert.info(S.current.please_load_model_first);
      return;
    }

    final chatModelIdle = await _ensureChatModelIdle(modelID: modelID);
    if (!chatModelIdle) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (historyMessages.isEmpty) {
      Alert.info(S.current.chat_empty_message);
      return;
    }

    final transcript = _buildTranscriptFromMessages(historyMessages);
    if (transcript.isEmpty) {
      Alert.info(S.current.chat_empty_message);
      return;
    }

    final resolvedParallelCount = _resolveParallelCount();
    final addGenerationPrompt = true;

    await P.rwkv.clearStates();
    _cancelRunningTasks();
    generating.q = true;
    P.rwkv.generating.q = true;
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _runningModelID = modelID;
    _runningPrefixes = const [];
    _stopRequested = false;
    questions.q = [];
    rawQuestions.q = [];
    parallelCount.q = resolvedParallelCount;
    lastTranscript.q = transcript;

    if (P.rwkv.isAlbatrossLoaded.q) {
      await _startAlbatrossCompletion(prompt: "$transcript\n\nUser:");
      return;
    }

    P.rwkv.send(to_rwkv.SetUserRole("User", modelID: modelID));
    P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "Assistant", modelID: modelID));

    final isBatchInference = resolvedParallelCount > 1;
    if (isBatchInference) {
      final batchMessages = <List<String>>[];
      for (int i = 0; i < resolvedParallelCount; i++) {
        batchMessages.add([...historyMessages]);
      }
      P.rwkv.send(
        to_rwkv.ChatBatchAsync(
          batchMessages,
          enableReasoning: false,
          forceReasoning: false,
          addGenerationPrompt: addGenerationPrompt,
          batchSize: resolvedParallelCount,
          modelID: modelID,
        ),
      );
    } else {
      P.rwkv.send(
        to_rwkv.ChatAsync(
          historyMessages,
          enableReasoning: false,
          forceReasoning: false,
          addGenerationPrompt: addGenerationPrompt,
          modelID: modelID,
        ),
      );
    }

    await _startPolling(
      modelID: modelID,
      isBatchInference: isBatchInference,
    );
  }

  Future<void> _generateFromDefaultPrefixes({
    required Language language,
    required List<String> prefixes,
  }) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      Alert.info(S.current.please_load_model_first);
      return;
    }

    final chatModelIdle = await _ensureChatModelIdle(modelID: modelID);
    if (!chatModelIdle) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final resolvedParallelCount = _resolveParallelCount(cap: prefixes.length);
    final selectedPrefixes = prefixes.take(resolvedParallelCount).toList();
    if (selectedPrefixes.isEmpty) return;

    await P.rwkv.clearStates();
    _cancelRunningTasks();
    generating.q = true;
    P.rwkv.generating.q = true;
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _runningModelID = modelID;
    _runningPrefixes = selectedPrefixes;
    _stopRequested = false;
    questions.q = [];
    rawQuestions.q = [];
    parallelCount.q = selectedPrefixes.length;
    lastTranscript.q = "";

    if (P.rwkv.isAlbatrossLoaded.q) {
      await _startAlbatrossCompletion(prompt: "User: ${selectedPrefixes.first}");
      return;
    }

    P.rwkv.send(to_rwkv.SetUserRole("User", modelID: modelID));
    P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "Assistant", modelID: modelID));

    final isBatchInference = selectedPrefixes.length > 1;
    if (isBatchInference) {
      final batchMessages = <List<String>>[];
      for (final prefix in selectedPrefixes) {
        batchMessages.add([prefix]);
      }
      P.rwkv.send(
        to_rwkv.ChatBatchAsync(
          batchMessages,
          enableReasoning: false,
          forceReasoning: false,
          addGenerationPrompt: false,
          batchSize: selectedPrefixes.length,
          modelID: modelID,
        ),
      );
    } else {
      P.rwkv.send(
        to_rwkv.ChatAsync(
          [selectedPrefixes.first],
          enableReasoning: false,
          forceReasoning: false,
          addGenerationPrompt: false,
          modelID: modelID,
        ),
      );
    }

    await _startPolling(
      modelID: modelID,
      isBatchInference: isBatchInference,
    );
  }

  Future<void> useQuestion(String question) async {
    final normalized = question.trim();
    if (normalized.isEmpty) return;

    final controller = P.chat.textEditingController;
    controller.text = normalized;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    P.chat.textInInput.q = normalized;
    await pop();
    await 1.msLater;
    await P.chat.onSendButtonPressed(preferredDemoType: .chat);
  }
}
