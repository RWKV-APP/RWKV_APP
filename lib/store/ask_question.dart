part of 'p.dart';

const _askQuestionSequentialQuestionCount = 4;
const _askQuestionSequentialAttemptLimit = 8;
const _askQuestionMinGenerateCount = 2;
const _askQuestionMaxGenerateCount = 8;

const _askQuestionPrefixes = <Language, List<String>>{
  .zh_Hans: [
    '如果',
    '请以',
    '请从',
    '请为',
    '为什么',
    '请解释',
    '请设计',
    '请推荐',
    '请扮演',
    '请构建',
  ],
  .zh_Hant: [
    '如果',
    '請以',
    '請從',
    '請為',
    '為什麼',
    '請解釋',
    '請設計',
    '請推薦',
    '請扮演',
    '請構建',
  ],
  .en: [
    'If ',
    'Why ',
    'How ',
    'What ',
    'Design ',
    'Assume ',
    'Can you ',
    'Explain ',
    'Could you ',
    'Recommend ',
  ],
  .ja: [
    'なぜ',
    'もし',
    '仮に',
    'どうして',
    'どうやって',
    '教えてください',
    '説明してください',
    '設計してください',
    '想像してください',
    'おすすめしてください',
  ],
  .ko: [
    '왜 ',
    '만약 ',
    '누구 ',
    '무엇이 ',
    '어떻게 ',
    '설명해 주세요 ',
    '추천해 주세요 ',
    '설계해 주세요 ',
    '만들어 주세요 ',
    '가정해 보면 ',
  ],
  .ru: [
    'Как ',
    'Что ',
    'Если ',
    'Почему ',
    'Опиши ',
    'Покажи ',
    'Объясни ',
    'Предложи ',
    'Представь ',
    'Разработай ',
  ],
};

class _AskQuestion {
  Timer? _getResponseTimer;
  DateTime? _lastRawQuestionsChangedAt;
  int? _runningModelID;
  Language? _lastResolvedLanguage;
  bool _stopRequested = false;
  List<String> _lastRawQuestions = const [];
  List<String> _completedQuestions = const [];
  List<String> _currentRunQuestions = const [];
  List<String> _runningPrefixes = const [];
  List<String> _activeMessages = const [];
  String _activePrefix = "";
  bool _activeAddGenerationPrompt = false;
  int _activeParallelCount = 1;
  bool _sequentialMode = false;
  int _attemptCount = 0;
  int _attemptLimit = 0;
  int _targetQuestionCount = 0;
  int _sessionId = 0;

  late final language = qs<Language>(.zh_Hans);
  late final interceptingEvents = qs(false);
  late final questions = qs<List<String>>([]);
  late final prefixInput = qs("");
  late final selectedPrefix = qs<String?>(null);
  late final selectedQuestionIndex = qs<int?>(null);
  late final editingQuestionIndex = qs<int?>(null);
  late final generateCount = qs(_askQuestionSequentialQuestionCount);
  late final parallelCount = qs(1);
  late final scheduledQuestionCount = qs(0);

  late final prefixes = qp((ref) {
    final selectedLanguage = ref.watch(language);
    return _askQuestionPrefixes[selectedLanguage] ?? const <String>[];
  });

  late final maxParallelCount = qp((ref) {
    final currentModel = ref.watch(P.rwkv.latestModel);
    if (currentModel == null) return 1;

    final batchAllowed = currentModel.tags.contains("batch");
    if (!batchAllowed) return 1;

    final supportedBatchSizes = ref.watch(P.rwkv.supportedBatchSizes);
    if (supportedBatchSizes.isEmpty) return 1;

    return supportedBatchSizes.max;
  });

  late final generateCountOptions = qp((ref) {
    return List<int>.generate(
      _askQuestionMaxGenerateCount - _askQuestionMinGenerateCount + 1,
      (index) => _askQuestionMinGenerateCount + index,
    );
  });

  late final hasChatHistory = qp((ref) {
    final _ = ref.watch(P.msg.list);
    final messages = _buildHistoryMessagesForQuestionGeneration();
    final transcript = _buildTranscriptFromMessages(messages);
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

  late final targetQuestionCount = qp((ref) {
    final selectedCount = ref.watch(generateCount);
    if (selectedCount < _askQuestionMinGenerateCount) return _askQuestionMinGenerateCount;
    if (selectedCount > _askQuestionMaxGenerateCount) return _askQuestionMaxGenerateCount;
    return selectedCount;
  });

  late final hasPrefixInput = qp((ref) {
    final prefixInput = ref.watch(this.prefixInput);
    return prefixInput.trim().isNotEmpty;
  });
}

/// Private methods
extension _$AskQuestion on _AskQuestion {
  bool get _isGenerating => P.rwkv.generating.q && interceptingEvents.q;

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
    P.preference.preferredLanguage.lv(_onPreferredLanguageChanged, fireImmediately: true);

    P.rwkv.broadcastStream.listen(
      _onStreamEvent,
      onDone: _onStreamDone,
      onError: _onStreamError,
    );
  }

  void _cancelRunningTasks() {
    _getResponseTimer?.cancel();
    _getResponseTimer = null;
  }

  void _onStreamDone() async {
    if (!interceptingEvents.q) return;
    _attemptCount = _attemptLimit;
    _finalizeQuestions();
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    if (!interceptingEvents.q) return;
    qqe("ask question stream error: $error");
    if (!kDebugMode) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
    _attemptCount = _attemptLimit;
    _finalizeQuestions();
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    if (!interceptingEvents.q) return;

    switch (event) {
      case from_rwkv.ResponseBatchBufferContent res:
        if (!_isGenerating) return;
        if (parallelCount.q <= 1) return;
        _updateQuestionsFromRaw(res.responseBufferContent);
      case from_rwkv.ResponseBufferContent res:
        if (!_isGenerating) return;
        if (parallelCount.q != 1) return;
        _updateQuestionsFromRaw([res.responseBufferContent]);
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
    final cleanedCurrentQuestions = _dedupeQuestions(
      effectiveRawQuestions.map((raw) => raw.trim()),
    );
    _currentRunQuestions = cleanedCurrentQuestions;
    final nextQuestions = _limitQuestions(
      _dedupeQuestions([
        ..._completedQuestions,
        ...cleanedCurrentQuestions,
      ]),
    );
    questions.q = nextQuestions;
    _syncQuestionSelectionWithQuestions(nextQuestions);
    _maybeStopSettledGeneration(cleanedCurrentQuestions);
  }

  void _finalizeQuestions() {
    _cancelRunningTasks();
    final finalizedCurrentQuestions = _dedupeQuestions(
      _currentRunQuestions.map((question) => question.trim()),
    );
    _completedQuestions = _limitQuestions(
      _dedupeQuestions([
        ..._completedQuestions,
        ...finalizedCurrentQuestions,
      ]),
    );
    questions.q = _completedQuestions;
    _syncQuestionSelectionWithQuestions(_completedQuestions);

    if (_shouldContinueSequentialGeneration()) {
      final sessionId = _sessionId;
      _currentRunQuestions = const [];
      _lastRawQuestions = const [];
      _lastRawQuestionsChangedAt = null;
      _runningPrefixes = const [];
      _stopRequested = false;
      unawaited(_continueSequentialGeneration(sessionId: sessionId));
      return;
    }

    interceptingEvents.q = false;
    P.rwkv.generating.q = false;
    parallelCount.q = 1;
    scheduledQuestionCount.q = 0;
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _runningModelID = null;
    _completedQuestions = const [];
    _currentRunQuestions = const [];
    _runningPrefixes = const [];
    _activeMessages = const [];
    _activePrefix = "";
    _activeAddGenerationPrompt = false;
    _activeParallelCount = 1;
    _sequentialMode = false;
    _attemptCount = 0;
    _attemptLimit = 0;
    _targetQuestionCount = 0;
    _stopRequested = false;
  }

  bool _shouldContinueSequentialGeneration() {
    if (!_sequentialMode) return false;
    if (_completedQuestions.length >= _targetQuestionCount) return false;
    if (_attemptCount >= _attemptLimit) return false;
    return true;
  }

  void _maybeStopSettledGeneration(List<String> currentQuestions) {
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

  Future<List<int>> _refreshSupportedBatchSizes({
    required int modelID,
  }) async {
    final request = to_rwkv.GetSupportedBatchSizes(modelID: modelID);
    P.rwkv.send(request);

    try {
      final response = await P.rwkv.broadcastStream
          .whereType<from_rwkv.SupportedBatchSizes>()
          .firstWhere((event) => event.req == request)
          .timeout(const Duration(milliseconds: 400));
      P.rwkv.supportedBatchSizes.q = response.supportedBatchSizes;
      return response.supportedBatchSizes;
    } catch (_) {
      return P.rwkv.supportedBatchSizes.q;
    }
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
    if (interceptingEvents.q) return false;

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

  List<String> _limitQuestions(List<String> questions) {
    if (_targetQuestionCount <= 0) return questions;
    if (questions.length <= _targetQuestionCount) return questions;
    return questions.take(_targetQuestionCount).toList();
  }

  ({List<String> messages, String prefix, bool addGenerationPrompt}) _buildGenerationPayload({
    required List<String> historyMessages,
    required String prefix,
  }) {
    final normalizedPrefix = prefix.trim();
    final hasContext = historyMessages.isNotEmpty;

    if (!hasContext) {
      if (normalizedPrefix.isEmpty) {
        return (
          messages: const <String>[""],
          prefix: "",
          addGenerationPrompt: true,
        );
      }
      return (
        messages: [normalizedPrefix],
        prefix: normalizedPrefix,
        addGenerationPrompt: false,
      );
    }

    if (normalizedPrefix.isEmpty) {
      return (
        messages: [...historyMessages],
        prefix: "",
        addGenerationPrompt: true,
      );
    }

    return (
      messages: [...historyMessages, normalizedPrefix],
      prefix: normalizedPrefix,
      addGenerationPrompt: false,
    );
  }

  bool _isDefaultPrefixStateForLanguage(Language targetLanguage) {
    final prefixes = _askQuestionPrefixes[targetLanguage] ?? const <String>[];
    if (prefixes.isEmpty) return prefixInput.q.trim().isEmpty && selectedPrefix.q == null;

    final defaultPrefix = prefixes.first;
    return prefixInput.q.trim() == defaultPrefix && selectedPrefix.q == defaultPrefix;
  }

  void _applyPrefixForLanguage(Language targetLanguage) {
    final prefixes = _askQuestionPrefixes[targetLanguage] ?? const <String>[];
    if (prefixes.isEmpty) {
      selectedPrefix.q = null;
      prefixInput.q = "";
      return;
    }

    final nextPrefix = prefixes.first;
    selectedPrefix.q = nextPrefix;
    prefixInput.q = nextPrefix;
  }

  void _applyPrefixStateForCurrentContext(Language targetLanguage) {
    if (hasChatHistory.q) {
      if (prefixInput.q.trim().isEmpty || _isDefaultPrefixStateForLanguage(targetLanguage)) {
        selectedPrefix.q = null;
        prefixInput.q = "";
        return;
      }

      _syncSelectedPrefixFromInput();
      return;
    }

    if (prefixInput.q.trim().isNotEmpty) {
      _syncSelectedPrefixFromInput();
      return;
    }

    _applyPrefixForLanguage(targetLanguage);
  }

  void _resetPanelStateForLanguage(Language nextLanguage) {
    if (_isGenerating) {
      _pauseGeneration();
    }

    language.q = nextLanguage;
    questions.q = [];
    prefixInput.q = "";
    selectedPrefix.q = null;
    parallelCount.q = 1;
    scheduledQuestionCount.q = 0;
    _completedQuestions = const [];
    _currentRunQuestions = const [];
    _activeMessages = const [];
    _activeAddGenerationPrompt = false;
    _clearQuestionSelectionState();

    if (hasChatHistory.q) return;
    _applyPrefixForLanguage(nextLanguage);
  }

  void _onPreferredLanguageChanged() {
    final nextLanguage = _resolveLanguage(P.preference.preferredLanguage.q.resolved);
    if (_lastResolvedLanguage == nextLanguage && language.q == nextLanguage) return;

    _lastResolvedLanguage = nextLanguage;
    _resetPanelStateForLanguage(nextLanguage);
  }

  void _syncSelectedPrefixFromInput() {
    final normalized = prefixInput.q.trim();
    if (normalized.isEmpty) {
      selectedPrefix.q = null;
      return;
    }

    final prefixes = _askQuestionPrefixes[language.q] ?? const <String>[];
    if (!prefixes.contains(normalized)) {
      selectedPrefix.q = null;
      return;
    }

    selectedPrefix.q = normalized;
  }

  void _clearQuestionSelectionState() {
    selectedQuestionIndex.q = null;
    editingQuestionIndex.q = null;
  }

  void _syncQuestionSelectionWithQuestions(List<String> questions) {
    if (questions.isEmpty) {
      _clearQuestionSelectionState();
      return;
    }

    final selectedIndex = selectedQuestionIndex.q;
    if (selectedIndex == null || selectedIndex < 0 || selectedIndex >= questions.length) {
      selectedQuestionIndex.q = 0;
    }
  }

  Future<void> _startQuestionGenerationSession({
    required int modelID,
    required List<String> messages,
    required String prefix,
    required bool addGenerationPrompt,
    required int parallelCount,
    required bool sequentialMode,
    required int targetQuestionCount,
    required int attemptLimit,
  }) async {
    _sessionId = _sessionId + 1;
    _cancelRunningTasks();
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _runningModelID = modelID;
    _completedQuestions = const [];
    _currentRunQuestions = const [];
    _runningPrefixes = const [];
    _activeMessages = [...messages];
    _activePrefix = prefix;
    _activeAddGenerationPrompt = addGenerationPrompt;
    _activeParallelCount = parallelCount;
    _sequentialMode = sequentialMode;
    _attemptCount = 0;
    _attemptLimit = attemptLimit;
    _targetQuestionCount = targetQuestionCount;
    _stopRequested = false;
    questions.q = [];
    this.parallelCount.q = parallelCount;
    scheduledQuestionCount.q = 0;
    interceptingEvents.q = true;
    P.rwkv.generating.q = true;
    _clearQuestionSelectionState();

    await _startQuestionGenerationRun(
      modelID: modelID,
      messages: messages,
      prefix: prefix,
      addGenerationPrompt: addGenerationPrompt,
      parallelCount: parallelCount,
      sessionId: _sessionId,
    );
  }

  Future<void> _startQuestionGenerationRun({
    required int modelID,
    required List<String> messages,
    required String prefix,
    required bool addGenerationPrompt,
    required int parallelCount,
    required int sessionId,
  }) async {
    _attemptCount = _attemptCount + 1;
    final remainingQuestionCount = math.max(1, _targetQuestionCount - _completedQuestions.length);
    final effectiveParallelCount = math.min(parallelCount, remainingQuestionCount);
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _currentRunQuestions = const [];
    _runningPrefixes = prefix.isEmpty ? const [] : List<String>.filled(effectiveParallelCount, prefix);
    _stopRequested = false;
    this.parallelCount.q = effectiveParallelCount;
    scheduledQuestionCount.q = math.min(_completedQuestions.length + effectiveParallelCount, _targetQuestionCount);

    await P.rwkv.clearStates();
    if (sessionId != _sessionId) return;
    if (!interceptingEvents.q) return;

    P.rwkv.send(to_rwkv.SetUserRole("User", modelID: modelID));
    P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "Assistant", modelID: modelID));

    final isBatchInference = effectiveParallelCount > 1;
    if (isBatchInference) {
      final batchMessages = <List<String>>[];
      for (int i = 0; i < effectiveParallelCount; i++) {
        batchMessages.add([...messages]);
      }
      P.rwkv.send(
        to_rwkv.ChatBatchAsync(
          batchMessages,
          enableReasoning: false,
          forceReasoning: false,
          addGenerationPrompt: addGenerationPrompt,
          batchSize: effectiveParallelCount,
          modelID: modelID,
        ),
      );
    } else {
      P.rwkv.send(
        to_rwkv.ChatAsync(
          messages,
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

  Future<void> _continueSequentialGeneration({
    required int sessionId,
  }) async {
    if (sessionId != _sessionId) return;
    if (!interceptingEvents.q) return;

    final modelID = _runningModelID;
    final activeMessages = _activeMessages;
    if (modelID == null || activeMessages.isEmpty) {
      _sequentialMode = false;
      _attemptCount = _attemptLimit;
      _finalizeQuestions();
      return;
    }

    await _startQuestionGenerationRun(
      modelID: modelID,
      messages: activeMessages,
      prefix: _activePrefix,
      addGenerationPrompt: _activeAddGenerationPrompt,
      parallelCount: _activeParallelCount,
      sessionId: sessionId,
    );
  }
}

/// Public methods
extension $AskQuestion on _AskQuestion {
  void onPanelShown() {
    final nextLanguage = _resolveLanguage(P.preference.preferredLanguage.q.resolved);
    if (language.q != nextLanguage) {
      _lastResolvedLanguage = nextLanguage;
      _resetPanelStateForLanguage(nextLanguage);
    }

    _applyPrefixStateForCurrentContext(language.q);
    _syncQuestionSelectionWithQuestions(questions.q);
  }

  void onPanelHidden() {
    if (_isGenerating) {
      _pauseGeneration();
    }
    _clearQuestionSelectionState();
  }

  void pauseGeneration() {
    if (!_isGenerating) return;
    _pauseGeneration();
  }

  void _pauseGeneration() {
    _sessionId = _sessionId + 1;
    final modelID = _runningModelID;
    if (modelID != null) {
      P.rwkv.send(to_rwkv.Stop(modelID: modelID));
    }

    _cancelRunningTasks();

    P.rwkv.generating.q = false;
    interceptingEvents.q = false;
    parallelCount.q = 1;
    scheduledQuestionCount.q = 0;
    _refreshChatModelGeneratingState();
    _lastRawQuestions = const [];
    _lastRawQuestionsChangedAt = null;
    _runningModelID = null;
    _completedQuestions = const [];
    _currentRunQuestions = const [];
    _runningPrefixes = const [];
    _activeMessages = const [];
    _activePrefix = "";
    _activeAddGenerationPrompt = false;
    _activeParallelCount = 1;
    _sequentialMode = false;
    _attemptCount = 0;
    _attemptLimit = 0;
    _targetQuestionCount = 0;
    _stopRequested = false;
  }

  void selectLanguage(Language nextLanguage) {
    if (_isGenerating) return;
    if (language.q == nextLanguage) return;

    _lastResolvedLanguage = nextLanguage;
    _resetPanelStateForLanguage(nextLanguage);
  }

  void selectPrefix(String prefix) {
    if (_isGenerating) return;

    final normalized = prefix.trim();
    if (normalized.isEmpty) return;

    if (hasChatHistory.q && selectedPrefix.q == normalized && prefixInput.q.trim() == normalized) {
      prefixInput.q = "";
      selectedPrefix.q = null;
      _clearQuestionSelectionState();
      return;
    }

    prefixInput.q = normalized;
    selectedPrefix.q = normalized;
    _clearQuestionSelectionState();
  }

  void updatePrefixInput(String next) {
    if (_isGenerating) return;
    prefixInput.q = next;
    _syncSelectedPrefixFromInput();
    _clearQuestionSelectionState();
  }

  void selectQuestion(int index) {
    final questions = this.questions.q;
    if (index < 0 || index >= questions.length) return;
    if (selectedQuestionIndex.q == index) return;

    selectedQuestionIndex.q = index;
    editingQuestionIndex.q = null;
  }

  void clearQuestionSelection() {
    _clearQuestionSelectionState();
  }

  void beginEditingQuestion(int index) {
    final questions = this.questions.q;
    if (index < 0 || index >= questions.length) return;

    selectedQuestionIndex.q = index;
    editingQuestionIndex.q = index;
  }

  void cancelEditingQuestion() {
    editingQuestionIndex.q = null;
  }

  void setGenerateCount(int nextCount) {
    if (_isGenerating) return;
    if (nextCount < _askQuestionMinGenerateCount) return;
    if (nextCount > _askQuestionMaxGenerateCount) return;
    if (generateCount.q == nextCount) return;

    generateCount.q = nextCount;
  }

  Future<void> generateFromCurrentChat() async {
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

    final payload = _buildGenerationPayload(
      historyMessages: _buildHistoryMessagesForQuestionGeneration(),
      prefix: prefixInput.q,
    );

    await _refreshSupportedBatchSizes(modelID: modelID);
    final targetQuestionCount = this.targetQuestionCount.q;
    final resolvedParallelCount = _resolveParallelCount(cap: targetQuestionCount);
    final sequentialMode = true;
    final attemptLimit = math.max(_askQuestionSequentialAttemptLimit, targetQuestionCount * 2);

    await _startQuestionGenerationSession(
      modelID: modelID,
      messages: payload.messages,
      prefix: payload.prefix,
      addGenerationPrompt: payload.addGenerationPrompt,
      parallelCount: resolvedParallelCount,
      sequentialMode: sequentialMode,
      targetQuestionCount: targetQuestionCount,
      attemptLimit: attemptLimit,
    );
  }

  Future<void> generateFromMessages(List<String> historyMessages) async {
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

    final payload = _buildGenerationPayload(
      historyMessages: historyMessages,
      prefix: "",
    );

    await _refreshSupportedBatchSizes(modelID: modelID);
    final targetQuestionCount = this.targetQuestionCount.q;
    final resolvedParallelCount = _resolveParallelCount(cap: targetQuestionCount);
    final sequentialMode = true;
    final attemptLimit = math.max(_askQuestionSequentialAttemptLimit, targetQuestionCount * 2);

    await _startQuestionGenerationSession(
      modelID: modelID,
      messages: payload.messages,
      prefix: payload.prefix,
      addGenerationPrompt: payload.addGenerationPrompt,
      parallelCount: resolvedParallelCount,
      sequentialMode: sequentialMode,
      targetQuestionCount: targetQuestionCount,
      attemptLimit: attemptLimit,
    );
  }

  Future<void> useQuestion(String question) async {
    final normalized = question.trim();
    if (normalized.isEmpty) return;

    prefixInput.q = "";
    selectedPrefix.q = null;
    _clearQuestionSelectionState();

    final controller = P.chat.textEditingController;
    controller.text = normalized;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    P.chat.textInInput.q = normalized;
    await pop();
    await 1.msLater;
    P.chat.focusNode.requestFocus();
  }
}
