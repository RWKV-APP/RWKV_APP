part of 'p.dart';

class _RWKVParams {
  late final _thinkingMode = qs<thinking_mode.ThinkingMode>(P.preference.preferredThinkingMode.q);

  late final argumentUpdatingDebouncer = Debouncer(milliseconds: 300);

  late final supportedBatchSizes = qs<List<int>>([]);
  late final batchParams = qs<List<DecodeParamType>>([]);

  late final arguments = qsff<Argument, double>((ref, argument) {
    return argument.defaults;
  });

  late final frontendBatchParams = qs<List<SamplerAndPenaltyParam>>([]);
  late final backendBatchParams = qs<List<SamplerAndPenaltyParam>>([]);
  late final editingBatchParamsIndex = qs<int?>(null);

  late final frontendBatchParamsAreAllSame = qp<bool>((ref) {
    final frontendBatchParams = ref.watch(P.rwkvParams.frontendBatchParams);
    if (frontendBatchParams.isEmpty) return false;
    return frontendBatchParams.every((param) => param == frontendBatchParams.first);
  });

  late final syncingBatchParams = qp<bool>(_syncingBatchParams);

  bool _syncingBatchParams(Ref<dynamic> ref) {
    final frontendBatchParams = ref.watch(P.rwkvParams.frontendBatchParams);
    final backendBatchParams = ref.watch(P.rwkvParams.backendBatchParams);
    if (frontendBatchParams.isEmpty || backendBatchParams.isEmpty) return false;
    bool areAllSame = true;
    for (int i = 0; i < backendBatchParams.length; i++) {
      final frontendParam = frontendBatchParams[i];
      final backendParam = backendBatchParams[i];
      final isEqual = frontendParam.tolerantEquals(backendParam);
      if (!isEqual) {
        areAllSame = false;
        break;
      }
    }
    return !areAllSame;
  }

  late final decodeParamType = qp<DecodeParamType>((ref) {
    final temp = ref.watch(arguments(Argument.temperature));
    final topP = ref.watch(arguments(Argument.topP));
    final presencePenalty = ref.watch(arguments(Argument.presencePenalty));
    final frequencyPenalty = ref.watch(arguments(Argument.frequencyPenalty));
    final penaltyDecay = ref.watch(arguments(Argument.penaltyDecay));
    return DecodeParamType.fromValue(
      temperature: temp,
      topP: topP,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      penaltyDecay: penaltyDecay,
    );
  });

  late final reasoning = qp<bool>((ref) => ref.watch(_thinkingMode).hasThinkTag);
  late final thinkingMode = qp<thinking_mode.ThinkingMode>((ref) => ref.watch(_thinkingMode));

  /// 当前模型是否是2025年9月22日之前发布的
  ///
  /// 新的权重要使用新的 thinking mode 组
  late final currentModelIsBefore20250922 = qp<bool>((ref) {
    final currentModel = ref.watch(P.rwkvModel.latest);
    if (currentModel == null) return false;
    final date = currentModel.date;
    return date != null && date.isBefore(DateTime(2025, 9, 22));
  });
}

extension $RWKVParams on _RWKVParams {
  void setGenerateMode(bool isGenerateMode) {
    if (isGenerateMode) {
      for (final entry in P.rwkvModel.allLoaded.q.entries) {
        final modelID = entry.value;
        P.rwkvBridge.send(to_rwkv.SetPrompt("", modelID: modelID));
      }
    } else {
      setModelConfig(thinkingMode: _thinkingMode.q);
    }
  }

  void updateSystemPrompt({String? prompt}) {
    final systemPrompt = P.preference.promptTemplate.formatedSystemPrompt().trim();
    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      if (prompt != null) {
        P.rwkvBridge.send(to_rwkv.SetPrompt(prompt, modelID: modelID));
      } else {
        String p = prompt ?? "<EOD>";
        if (systemPrompt.isNotEmpty) {
          p = "$systemPrompt\n\n";
        }
        P.rwkvBridge.send(to_rwkv.SetPrompt(p, modelID: modelID));
      }
      qqw("setPrompt: $prompt");
    }
  }

  Future<void> setModelConfig({
    thinking_mode.ThinkingMode? thinkingMode,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? enableReasoning,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? preferChinese,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? preferPseudo,
    bool setPrompt = true,
    String? prompt,
    bool rememberThinkingMode = false,
  }) async {
    qqr(thinkingMode);
    final nextThinkingMode = thinkingMode ?? _thinkingMode.q;
    if (nextThinkingMode != .fast && P.chat.responseStyle.q.activeCount > 1) {
      P.chat.resetResponseStyle();
    }
    _thinkingMode.q = nextThinkingMode;
    if (rememberThinkingMode) {
      unawaited(P.preference.saveThinkingMode(nextThinkingMode));
    }

    if (setPrompt) {
      updateSystemPrompt(prompt: prompt);
    }

    final custom = P.preference.promptTemplate;
    final thinkingToken = custom.apply(_thinkingMode.q);
    qqq("setThinkingToken: $thinkingToken");
    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      P.rwkvBridge.send(to_rwkv.SetThinkingToken(thinkingToken, modelID: modelID));
    }
  }

  thinking_mode.ThinkingMode preferredThinkingModeForCurrentChatModel() {
    final preferredThinkingMode = P.preference.preferredThinkingMode.q;
    if (!currentModelIsBefore20250922.q) {
      return switch (preferredThinkingMode) {
        .lighting => .fast,
        _ => preferredThinkingMode,
      };
    }

    return switch (preferredThinkingMode) {
      .none => .none,
      .free => .free,
      .preferChinese => .preferChinese,
      .lighting => .lighting,
      _ => .lighting,
    };
  }

  thinking_mode.ThinkingMode thinkingModeForCurrentChatConfig() {
    if (P.chat.responseStyle.q.activeCount > 1) {
      return .fast;
    }
    return preferredThinkingModeForCurrentChatModel();
  }

  Future<void> resetSamplerParams({required bool enableReasoning}) async {
    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      P.rwkvBridge.send(
        to_rwkv.SetSamplerParams(
          temperature: enableReasoning ? Argument.temperature.reasonDefaults : Argument.temperature.defaults,
          topK: enableReasoning ? Argument.topK.reasonDefaults : Argument.topK.defaults,
          topP: enableReasoning ? Argument.topP.reasonDefaults : Argument.topP.defaults,
          presencePenalty: enableReasoning ? Argument.presencePenalty.reasonDefaults : Argument.presencePenalty.defaults,
          frequencyPenalty: enableReasoning ? Argument.frequencyPenalty.reasonDefaults : Argument.frequencyPenalty.defaults,
          penaltyDecay: enableReasoning ? Argument.penaltyDecay.reasonDefaults : Argument.penaltyDecay.defaults,
          modelID: modelID,
        ),
      );
    }
  }

  Future syncSamplerParamsFromDefault(DecodeParamType param) async {
    await syncSamplerParams(
      temperature: param.temperature,
      topP: param.topP,
      penaltyDecay: param.penaltyDecay,
      presencePenalty: param.presencePenalty,
      frequencyPenalty: param.frequencyPenalty,
    );
  }

  Future<void> syncSamplerParams({
    double? temperature,
    double? topK,
    double? topP,
    double? presencePenalty,
    double? frequencyPenalty,
    double? penaltyDecay,
  }) async {
    if (temperature != null) arguments(Argument.temperature).q = temperature;
    if (topK != null) arguments(Argument.topK).q = topK;
    if (topP != null) arguments(Argument.topP).q = topP;
    if (presencePenalty != null) arguments(Argument.presencePenalty).q = presencePenalty;
    if (frequencyPenalty != null) arguments(Argument.frequencyPenalty).q = frequencyPenalty;
    if (penaltyDecay != null) arguments(Argument.penaltyDecay).q = penaltyDecay;

    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      P.rwkvBridge.send(
        to_rwkv.SetSamplerParams(
          temperature: _intIfFixedDecimalsIsZero(Argument.temperature),
          topK: _intIfFixedDecimalsIsZero(Argument.topK),
          topP: _intIfFixedDecimalsIsZero(Argument.topP),
          presencePenalty: _intIfFixedDecimalsIsZero(Argument.presencePenalty),
          frequencyPenalty: _intIfFixedDecimalsIsZero(Argument.frequencyPenalty),
          penaltyDecay: _intIfFixedDecimalsIsZero(Argument.penaltyDecay),
          modelID: modelID,
        ),
      );
    }

    if (kDebugMode) {
      for (final entry in P.rwkvModel.allLoaded.q.entries) {
        final modelID = entry.value;
        P.rwkvBridge.send(to_rwkv.GetSamplerParams(modelID: modelID));
      }
    }
  }

  Future<void> resetMaxLength({required bool enableReasoning}) async {
    await syncMaxLength(maxLength: enableReasoning ? Argument.maxLength.reasonDefaults : Argument.maxLength.defaults);
  }

  Future<void> syncMaxLength({num? maxLength}) async {
    if (maxLength != null) arguments(Argument.maxLength).q = maxLength.toDouble();
    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      P.rwkvBridge.send(to_rwkv.SetMaxLength(_intIfFixedDecimalsIsZero(Argument.maxLength).toInt(), modelID: modelID));
    }
  }

  Future<void> onThinkModeTapped() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    P.app.hapticLight();

    final s = S.current;

    if (P.rwkvContext.isAlbatrossLoaded.q) {
      final current = thinkingMode.q;
      if (current != .none) {
        setModelConfig(thinkingMode: .none, rememberThinkingMode: true);
      } else {
        setModelConfig(thinkingMode: .free, rememberThinkingMode: true);
      }
      return;
    }

    final currentModelIsBefore20250922 = P.rwkvParams.currentModelIsBefore20250922.q;
    qqr("currentModelIsBefore20250922: $currentModelIsBefore20250922");
    if (currentModelIsBefore20250922) {
      final current = thinkingMode.q;
      switch (current) {
        case .lighting:
          setModelConfig(thinkingMode: .free, rememberThinkingMode: true);
          Alert.success(s.thinking_mode_high(s.thinking_mode_alert_footer));
        case .free:
          setModelConfig(thinkingMode: .none, rememberThinkingMode: true);
          Alert.success(s.thinking_mode_off(s.thinking_mode_alert_footer));
        case .preferChinese:
          setModelConfig(thinkingMode: .none, rememberThinkingMode: true);
          Alert.success(s.thinking_mode_off(s.thinking_mode_alert_footer));
        case .none:
          setModelConfig(thinkingMode: .lighting, rememberThinkingMode: true);
          Alert.success(s.thinking_mode_auto(s.thinking_mode_alert_footer));
        default:
          break;
      }
      return;
    }

    final current = thinkingMode.q;

    final actionPairs = <({thinking_mode.ThinkingMode key, String label})>[
      (label: s.thinking_mode_off(""), key: .none),
      (label: s.think_button_mode_fast(""), key: .fast),
      (label: s.thinking_mode_high(""), key: .free),
      (label: s.think_button_mode_en(""), key: .en),
      (label: s.think_button_mode_en_short(""), key: .enShort),
      (label: s.think_button_mode_en_long(""), key: .enLong),
    ];

    qqr("actionPairs: $actionPairs");

    final actions = actionPairs.map((e) {
      final isCurrent = e.key == current;
      final label = isCurrent ? "☑ ${e.label}" : e.label;
      final key = e.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final res = await showModalActionSheet<thinking_mode.ThinkingMode>(
      context: getContext()!,
      title: s.think_mode_selector_title,
      message: s.think_mode_selector_message + "\n" + s.think_mode_selector_recommendation,
      actions: actions,
    );

    if (res == null) return;

    setModelConfig(thinkingMode: res, rememberThinkingMode: true);
    switch (res) {
      case .none:
        Alert.success(s.thinking_mode_off(s.thinking_mode_alert_footer));
      case .fast:
        Alert.success(s.think_button_mode_fast(s.thinking_mode_alert_footer));
      case .free:
        Alert.success(s.thinking_mode_high(s.thinking_mode_alert_footer));
      case .en:
        Alert.success(s.think_button_mode_en(s.thinking_mode_alert_footer));
      case .enShort:
        Alert.success(s.think_button_mode_en_short(s.thinking_mode_alert_footer));
      case .enLong:
        Alert.success(s.think_button_mode_en_long(s.thinking_mode_alert_footer));
      default:
        break;
    }
  }

  void onBatchInferenceTapped() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final currentModel = P.rwkvModel.latest.q;

    final batchAllowed = currentModel!.supportsBatchInference;

    if (!batchAllowed) {
      Alert.info(S.current.this_model_does_not_support_batch_inference);
      await 500.msLater;
      ModelSelector.show();
      return;
    }

    await BatchSettingsPanel.show();
  }

  void onSecondaryOptionsTapped() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final current = thinkingMode.q;
    P.app.hapticLight();
    switch (current) {
      case .lighting:
      case .none:
        break;
      case .free:
        setModelConfig(thinkingMode: .preferChinese, rememberThinkingMode: true);
        Alert.success(S.current.prefer_chinese);
      case .preferChinese:
        setModelConfig(thinkingMode: .free, rememberThinkingMode: true);
        Alert.success(S.current.thinking_mode_high(S.current.thinking_mode_alert_footer));
      default:
        break;
    }
  }

  void _syncMaxBatchCount() {
    for (final delay in [500.ms, 1000.ms, 2000.ms]) {
      unawaited(_requestSupportedBatchSizesLater(delay));
    }
  }

  num _intIfFixedDecimalsIsZero(Argument argument) {
    if (argument.fixedDecimals == 0) {
      return arguments(argument).q.toInt();
    } else {
      return double.parse(arguments(argument).q.toStringAsFixed(argument.fixedDecimals));
    }
  }

  Future<void> _requestSupportedBatchSizesLater(Duration delay) async {
    await Future<void>.delayed(delay);
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID != null) P.rwkvBridge.send(to_rwkv.GetSupportedBatchSizes(modelID: modelID));
  }
}
