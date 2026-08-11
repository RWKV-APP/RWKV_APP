part of 'p.dart';

const int agentDefaultMaxLength = 10240;
const int agentReasoningCharacterBudget = 2400;
const int agentToolCallCharacterBudget = 12000;
const int agentFinalAnswerCharacterBudget = 4000;
const Duration agentModelIdleTimeout = Duration(seconds: 30);
const Duration agentModelGenerationTimeout = Duration(minutes: 15);
const Duration agentModelPollInterval = Duration(milliseconds: 40);
const Duration agentModelResponsePollInterval = Duration(milliseconds: 100);
const Duration agentModelStopSignalTimeout = Duration(seconds: 3);
const Duration agentModelFirstTokenTimeout = Duration(seconds: 20);
const String agentLocalFileSystemPrompt = """
You operate only inside a user-authorized real local workspace.
Use the provided file tools for the requested work and use only relative paths.
Every write or delete requires user approval. If an action is rejected or a tool reports an error, do not claim success.
After each mutation, trust only the tool's verification result. Read files when the user asks you to inspect or verify content.
When all requested work is complete, call submit with a concise truthful summary.
""";

class _Agent {
  late final running = qs(false);
  late final runningAll = qs(false);
  late final stopping = qs(false);
  late final currentCaseName = qs<String?>(null);
  late final currentCaseOrdinal = qs(0);
  late final runModelName = qs<String?>(null);
  late final evaluationMode = qs(AgentEvaluationMode.strict);
  late final repeatCount = qs(1);
  late final currentAttempt = qs(1);
  late final cases = qs<List<AgentCase>>(<AgentCase>[]);
  late final selectedCaseIndex = qs(0);
  late final records = qs<Map<String, AgentCaseRunRecord>>(<String, AgentCaseRunRecord>{});
  late final events = qs<List<AgentEvent>>(<AgentEvent>[]);
  late final result = qs<AgentRunResult?>(null);
  late final verdict = qs<AgentCaseVerdict?>(null);
  late final error = qs<String?>(null);
  late final liveModelOutput = qs("");
  late final report = qs<AgentEvaluationReport?>(null);
  late final reportRecords = qs<List<AgentCaseRunRecord>>(<AgentCaseRunRecord>[]);
  late final lastReportPath = qs<String?>(null);
  late final localWorkspacePath = qs<String?>(null);
  late final localRunning = qs(false);
  late final localSessionVisible = qs(false);
  late final localApproval = qs<AgentLocalFileApproval?>(null);
  late final localFinalAnswer = qs("");

  bool _cancelRequested = false;
  bool _reportOpen = false;
  String _benchmarkSha256 = "";
  Completer<bool>? _localApprovalCompleter;
}

extension $Agent on _Agent {
  bool get localFileActionsSupported {
    return kDebugMode && Platform.isWindows;
  }

  Future<void> _init() async {
    final raw = await rootBundle.loadString("assets/agent_cases/primitive_bench.json");
    _benchmarkSha256 = crypto.sha256.convert(utf8.encode(raw)).toString();
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException("Primitive Bench asset must contain a JSON array");
    }
    final loaded = <AgentCase>[];
    for (final value in decoded) {
      if (value is! Map) continue;
      final json = <String, dynamic>{};
      for (final entry in value.entries) {
        if (entry.key is! String) continue;
        json[entry.key as String] = entry.value;
      }
      loaded.add(AgentCase.fromJson(json));
    }
    cases.q = List<AgentCase>.unmodifiable(loaded);
    if (kDebugMode) {
      _registerDebugExtensions();
    }
  }

  void _registerDebugExtensions() {
    registerExtension("ext.rwkv.agent.status", _debugStatus);
    registerExtension("ext.rwkv.agent.report", _debugReport);
    registerExtension("ext.rwkv.agent.loadModel", _debugLoadModel);
    registerExtension("ext.rwkv.agent.runCase", _debugRunCase);
    registerExtension("ext.rwkv.agent.runAll", _debugRunAll);
    registerExtension("ext.rwkv.agent.stop", _debugStop);
  }

  Future<ServiceExtensionResponse> _debugStatus(
    String method,
    Map<String, String> parameters,
  ) async {
    return _debugResponse(_debugStatusJson());
  }

  Future<ServiceExtensionResponse> _debugReport(
    String method,
    Map<String, String> parameters,
  ) async {
    final activeReport = report.q;
    if (activeReport == null) {
      return _debugError("no Agent evaluation report is available");
    }
    return _debugResponse(activeReport.toJson());
  }

  Future<ServiceExtensionResponse> _debugLoadModel(
    String method,
    Map<String, String> parameters,
  ) async {
    final query = parameters["name"]?.trim() ?? "";
    if (query.isEmpty) {
      return _debugError("name is required");
    }
    if (running.q || runningAll.q || P.rwkvGeneration.generating.q || P.rwkvModel.loading.q) {
      return _debugError("model or agent is busy");
    }

    final normalizedQuery = query.toLowerCase();
    final matches = P.remote.chatWeights.q.where((fileInfo) {
      return fileInfo.name.toLowerCase() == normalizedQuery ||
          fileInfo.fileName.toLowerCase() == normalizedQuery ||
          fileInfo.name.toLowerCase().contains(normalizedQuery) ||
          fileInfo.fileName.toLowerCase().contains(normalizedQuery);
    }).toList();
    if (matches.isEmpty) {
      return _debugError("model not found: $query");
    }
    matches.sort((a, b) => a.name.compareTo(b.name));
    final fileInfo = matches.first;
    final localFile = P.remote.locals(fileInfo).q;
    if (!localFile.hasFile) {
      return _debugError("model file is not available: ${fileInfo.fileName}");
    }

    await P.rwkvModel.startLocalModelForChat(fileInfo);
    if (P.rwkvModel.latest.q != fileInfo) {
      return _debugError("model load did not complete: ${fileInfo.name}");
    }
    return _debugResponse(_debugStatusJson());
  }

  Future<ServiceExtensionResponse> _debugRunCase(
    String method,
    Map<String, String> parameters,
  ) async {
    final index = int.tryParse(parameters["index"] ?? "");
    if (index == null || index < 1 || index > cases.q.length) {
      return _debugError("index must be between 1 and ${cases.q.length}");
    }
    if (running.q || runningAll.q || P.rwkvGeneration.generating.q || P.rwkvModel.loading.q) {
      return _debugError("model or agent is busy");
    }
    selectedCaseIndex.q = index - 1;
    unawaited(runSelectedCase());
    return _debugResponse(_debugStatusJson());
  }

  Future<ServiceExtensionResponse> _debugRunAll(
    String method,
    Map<String, String> parameters,
  ) async {
    if (running.q || runningAll.q || P.rwkvGeneration.generating.q || P.rwkvModel.loading.q) {
      return _debugError("model or agent is busy");
    }
    unawaited(runAllCases());
    return _debugResponse(_debugStatusJson());
  }

  Future<ServiceExtensionResponse> _debugStop(
    String method,
    Map<String, String> parameters,
  ) async {
    await stop();
    return _debugResponse(_debugStatusJson());
  }

  ServiceExtensionResponse _debugResponse(Map<String, Object?> value) {
    return ServiceExtensionResponse.result(jsonEncode(value));
  }

  ServiceExtensionResponse _debugError(String message) {
    return _debugResponse(<String, Object?>{
      "ok": false,
      "error": message,
    });
  }

  Map<String, Object?> _debugStatusJson({bool includeEvents = false}) {
    final recordJson = <String, Object?>{};
    for (final entry in records.q.entries) {
      final record = entry.value;
      recordJson[entry.key] = <String, Object?>{
        "passed": record.verdict.passed,
        "failures": record.verdict.failures,
        "status": record.result.status.name,
        "turns": record.result.turns,
        "finalAnswer": record.result.finalAnswer,
        "toolCalls": record.result.events.where((event) => event.kind == .toolCall).length,
        if (includeEvents)
          "events": record.result.events.map((event) {
            return <String, Object?>{
              "kind": event.kind.name,
              "turn": event.turn,
              "title": event.title,
              "content": event.content,
              if (event.toolCall != null)
                "toolCall": <String, Object?>{
                  "id": event.toolCall!.id,
                  "name": event.toolCall!.name,
                  "arguments": event.toolCall!.arguments,
                },
              if (event.toolResult != null)
                "toolResult": <String, Object?>{
                  "toolName": event.toolResult!.toolName,
                  "content": event.toolResult!.content,
                  "isError": event.toolResult!.isError,
                },
            };
          }).toList(),
      };
    }

    return <String, Object?>{
      "ok": true,
      "model": P.rwkvModel.latest.q?.name,
      "modelLoading": P.rwkvModel.loading.q,
      "backendGenerating": P.rwkvGeneration.generating.q,
      "running": running.q,
      "runningAll": runningAll.q,
      "stopping": stopping.q,
      "currentCase": currentCaseName.q,
      "currentCaseOrdinal": currentCaseOrdinal.q,
      "selectedCaseIndex": selectedCaseIndex.q + 1,
      "caseCount": cases.q.length,
      "runModelName": runModelName.q,
      "evaluationMode": evaluationMode.q.name,
      "repeatCount": repeatCount.q,
      "currentAttempt": currentAttempt.q,
      "completed": records.q.length,
      "passed": records.q.values.where((record) => record.verdict.passed).length,
      "failed": records.q.values.where((record) => !record.verdict.passed).length,
      "error": error.q,
      "localFileActionsSupported": localFileActionsSupported,
      "localWorkspacePath": localWorkspacePath.q,
      "localRunning": localRunning.q,
      "localSessionVisible": localSessionVisible.q,
      "localApproval": localApproval.q == null
          ? null
          : <String, Object?>{
              "operation": localApproval.q!.operation.name,
              "relativePath": localApproval.q!.relativePath,
              "content": localApproval.q!.content,
            },
      "localFinalAnswer": localFinalAnswer.q,
      "reportPath": lastReportPath.q,
      "report": report.q?.toJson(),
      "liveModelOutput": liveModelOutput.q,
      "records": recordJson,
    };
  }

  AgentCase? get selectedCase {
    final loadedCases = cases.q;
    final index = selectedCaseIndex.q;
    if (index < 0 || index >= loadedCases.length) return null;
    return loadedCases[index];
  }

  void selectCase(int index) {
    if (running.q || runningAll.q) return;
    if (index < 0 || index >= cases.q.length) return;
    selectedCaseIndex.q = index;
  }

  void setEvaluationMode(AgentEvaluationMode value) {
    if (running.q || runningAll.q) return;
    evaluationMode.q = value;
  }

  void setRepeatCount(int value) {
    if (running.q || runningAll.q) return;
    repeatCount.q = value.clamp(1, 3);
  }

  Future<bool> chooseLocalWorkspace() async {
    if (!localFileActionsSupported) {
      Alert.warning(S.current.agent_local_windows_debug_only);
      return false;
    }
    if (running.q || runningAll.q || P.rwkvGeneration.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return false;
    }
    final selectedPath = await file_picker.FilePicker.getDirectoryPath(
      dialogTitle: S.current.agent_local_select_workspace,
      lockParentWindow: true,
    );
    if (selectedPath == null) return false;
    try {
      final host = await AgentLocalFileHost.create(
        workspacePath: selectedPath,
        requestApproval: (approval) async {
          return false;
        },
      );
      localWorkspacePath.q = host.workspacePath;
      Alert.success(
        "${S.current.agent_local_workspace_authorized}\n\n${host.workspacePath}",
      );
      return true;
    } catch (caught) {
      Alert.error(
        "${S.current.agent_local_workspace_failed}\n\n$caught",
      );
      return false;
    }
  }

  Future<bool> ensureLocalWorkspace() async {
    if (localWorkspacePath.q != null) return true;
    return chooseLocalWorkspace();
  }

  Future<AgentRunResult?> runLocalFileTask(
    String prompt, {
    bool diagnosticSessionVisible = true,
    FutureOr<void> Function(AgentEvent event)? onEvent,
  }) async {
    if (!localFileActionsSupported) {
      Alert.warning(S.current.agent_local_windows_debug_only);
      return null;
    }
    if (running.q || runningAll.q || P.rwkvGeneration.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return null;
    }
    final workspacePath = localWorkspacePath.q;
    if (workspacePath == null) {
      Alert.info(S.current.agent_local_select_workspace_first);
      return null;
    }
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      Alert.info(S.current.agent_local_prompt_required);
      return null;
    }
    final model = P.rwkvModel.latest.q;
    if (model == null) {
      Alert.info(S.current.please_load_model_first);
      return null;
    }
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      Alert.error(S.current.agent_eval_active_model_unknown);
      return null;
    }

    running.q = true;
    localRunning.q = true;
    localSessionVisible.q = diagnosticSessionVisible;
    stopping.q = false;
    currentCaseName.q = "local-file-workspace";
    runModelName.q = model.name;
    events.q = <AgentEvent>[];
    result.q = null;
    verdict.q = null;
    error.q = null;
    liveModelOutput.q = "";
    localFinalAnswer.q = "";
    localApproval.q = null;
    _cancelRequested = false;
    _localApprovalCompleter = null;

    _AgentSamplerSnapshot? samplerSnapshot;
    try {
      final host = await AgentLocalFileHost.create(
        workspacePath: workspacePath,
        requestApproval: _requestLocalFileApproval,
      );
      final runtime = AgentRuntime(
        model: _RWKVAgentModel(
          this,
          modelID: modelID,
        ),
        toolHost: host,
        mode: .strict,
        maxTurns: 20,
        maxRepeatedCalls: 2,
      );

      agentEvaluationSamplerConfig.validate();
      samplerSnapshot = await _AgentSamplerSnapshot.capture(modelID: modelID);
      await P.rwkvParams.syncSamplerParams(
        temperature: agentEvaluationSamplerConfig.temperature,
        topK: agentEvaluationSamplerConfig.topK.toDouble(),
        topP: agentEvaluationSamplerConfig.topP,
        presencePenalty: agentEvaluationSamplerConfig.presencePenalty,
        frequencyPenalty: agentEvaluationSamplerConfig.frequencyPenalty,
        penaltyDecay: agentEvaluationSamplerConfig.penaltyDecay,
      );
      await samplerSnapshot.setSeed(agentEvaluationSeed);
      await P.rwkvGeneration.clearStates();
      final runResult = await runtime.run(
        system: agentLocalFileSystemPrompt,
        user: normalizedPrompt,
        isCancelled: () => _cancelRequested,
        onEvent: (event) async {
          events.q = List<AgentEvent>.unmodifiable(<AgentEvent>[
            ...events.q,
            event,
          ]);
          await onEvent?.call(event);
          if (event.kind != .modelOutput) return;
          liveModelOutput.q = event.content;
        },
      );
      result.q = runResult;
      localFinalAnswer.q = runResult.finalAnswer;
      return runResult;
    } catch (caught, stackTrace) {
      qqe("Local Agent file task failed: $caught");
      error.q = caught.toString();
      if (!kDebugMode) {
        unawaited(Sentry.captureException(caught, stackTrace: stackTrace));
      }
      return null;
    } finally {
      final approvalCompleter = _localApprovalCompleter;
      if (approvalCompleter != null && !approvalCompleter.isCompleted) {
        approvalCompleter.complete(false);
      }
      _localApprovalCompleter = null;
      localApproval.q = null;
      try {
        await samplerSnapshot?.restore();
      } catch (caught, stackTrace) {
        qqe("Local Agent sampler restore failed: $caught");
        error.q = caught.toString();
        if (!kDebugMode) {
          unawaited(Sentry.captureException(caught, stackTrace: stackTrace));
        }
      }
      running.q = false;
      localRunning.q = false;
      stopping.q = false;
      currentCaseName.q = null;
      liveModelOutput.q = "";
    }
  }

  Future<bool> _requestLocalFileApproval(
    AgentLocalFileApproval approval,
  ) async {
    if (_cancelRequested) return false;
    final previousCompleter = _localApprovalCompleter;
    if (previousCompleter != null && !previousCompleter.isCompleted) {
      previousCompleter.complete(false);
    }
    final completer = Completer<bool>();
    _localApprovalCompleter = completer;
    localApproval.q = approval;
    return completer.future;
  }

  void resolveLocalFileApproval(bool approved) {
    final completer = _localApprovalCompleter;
    if (completer == null || completer.isCompleted) return;
    _localApprovalCompleter = null;
    localApproval.q = null;
    completer.complete(approved);
  }

  Future<AgentCaseVerdict?> runSelectedCase() async {
    final agentCase = selectedCase;
    if (agentCase == null) return null;
    if (!_validateActiveModel()) return null;
    try {
      await _beginEvaluationReport(
        repeats: 1,
        selectedCases: <String>[agentCase.name],
      );
      currentCaseOrdinal.q = selectedCaseIndex.q + 1;
      return await runCase(agentCase);
    } catch (caught, stackTrace) {
      _recordSessionError(caught, stackTrace);
      return null;
    } finally {
      try {
        await _completeEvaluationReport();
      } catch (caught, stackTrace) {
        _recordSessionError(caught, stackTrace);
      }
    }
  }

  Future<void> runAllCases() async {
    if (running.q || runningAll.q || cases.q.isEmpty) return;
    if (!_validateActiveModel()) return;
    _cancelRequested = false;
    runningAll.q = true;
    records.q = <String, AgentCaseRunRecord>{};
    reportRecords.q = <AgentCaseRunRecord>[];
    try {
      await _beginEvaluationReport(
        repeats: repeatCount.q,
        selectedCases: cases.q.map((value) => value.name).toList(),
      );
      for (int attempt = 1; attempt <= repeatCount.q; attempt++) {
        currentAttempt.q = attempt;
        for (final entry in cases.q.indexed) {
          if (_cancelRequested) break;
          selectedCaseIndex.q = entry.$1;
          currentCaseOrdinal.q = (attempt - 1) * cases.q.length + entry.$1 + 1;
          final caseVerdict = await runCase(entry.$2);
          if (caseVerdict == null && error.q != null) break;
          if (result.q?.status == .infrastructureFailed) break;
        }
        if (_cancelRequested || error.q != null || result.q?.status == .infrastructureFailed) {
          break;
        }
      }
    } catch (caught, stackTrace) {
      _recordSessionError(caught, stackTrace);
    } finally {
      try {
        await _completeEvaluationReport();
      } catch (caught, stackTrace) {
        _recordSessionError(caught, stackTrace);
      } finally {
        runningAll.q = false;
        currentCaseName.q = null;
        currentCaseOrdinal.q = 0;
        currentAttempt.q = 1;
      }
    }
  }

  Future<AgentCaseVerdict?> runCase(AgentCase agentCase) async {
    if (running.q || P.rwkvGeneration.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return null;
    }

    final model = P.rwkvModel.latest.q;
    if (model == null) {
      Alert.info(S.current.please_load_model_first);
      return null;
    }
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      Alert.error(S.current.agent_eval_active_model_unknown);
      return null;
    }
    if (runModelName.q != model.name) {
      records.q = <String, AgentCaseRunRecord>{};
    }
    runModelName.q = model.name;

    running.q = true;
    localSessionVisible.q = false;
    stopping.q = false;
    currentCaseName.q = agentCase.name;
    events.q = <AgentEvent>[];
    result.q = null;
    verdict.q = null;
    error.q = null;
    liveModelOutput.q = "";
    _cancelRequested = false;
    final caseStartedAt = DateTime.now();

    final sandboxedLua = AgentSandboxedLua();
    final sandbox = agentCase.createSandbox(luaRunner: sandboxedLua.run);
    final runtime = AgentRuntime(
      model: _RWKVAgentModel(
        this,
        modelID: modelID,
      ),
      toolHost: sandbox,
      mode: evaluationMode.q,
      maxTurns: agentCase.maxTurns,
    );
    _AgentSamplerSnapshot? samplerSnapshot;

    try {
      agentEvaluationSamplerConfig.validate();
      samplerSnapshot = await _AgentSamplerSnapshot.capture(modelID: modelID);
      await P.rwkvParams.syncSamplerParams(
        temperature: agentEvaluationSamplerConfig.temperature,
        topK: agentEvaluationSamplerConfig.topK.toDouble(),
        topP: agentEvaluationSamplerConfig.topP,
        presencePenalty: agentEvaluationSamplerConfig.presencePenalty,
        frequencyPenalty: agentEvaluationSamplerConfig.frequencyPenalty,
        penaltyDecay: agentEvaluationSamplerConfig.penaltyDecay,
      );
      await samplerSnapshot.setSeed(agentEvaluationSeed);
      await P.rwkvGeneration.clearStates();
      final runResult = await runtime.run(
        system: agentCase.system,
        user: agentCase.prompt,
        isCancelled: () => _cancelRequested,
        onEvent: (event) async {
          events.q = List<AgentEvent>.unmodifiable(<AgentEvent>[
            ...events.q,
            event,
          ]);
          if (event.kind == .modelOutput) {
            liveModelOutput.q = event.content;
          }
        },
      );
      result.q = runResult;
      final caseVerdict = await _recordCaseResult(
        agentCase: agentCase,
        result: runResult,
        sandbox: sandbox,
        startedAt: caseStartedAt,
      );
      return caseVerdict;
    } catch (caught, stackTrace) {
      qqe("Agent case failed: $caught");
      error.q = caught.toString();
      if (result.q == null) {
        final event = AgentEvent(
          kind: .error,
          turn: 0,
          title: "Infrastructure error",
          content: caught.toString(),
        );
        events.q = <AgentEvent>[event];
        final infrastructureResult = AgentRunResult(
          status: .infrastructureFailed,
          finalAnswer: "",
          prompt: "",
          events: <AgentEvent>[event],
          turns: 0,
          validForModelScore: false,
        );
        result.q = infrastructureResult;
        try {
          return await _recordCaseResult(
            agentCase: agentCase,
            result: infrastructureResult,
            sandbox: sandbox,
            startedAt: caseStartedAt,
          );
        } catch (persistError) {
          error.q = "$caught\n$persistError";
        }
      }
      final activeReport = report.q;
      if (activeReport != null) {
        report.q = activeReport.copyWith(error: caught.toString());
      }
      if (!kDebugMode) {
        unawaited(Sentry.captureException(caught, stackTrace: stackTrace));
      }
      return null;
    } finally {
      try {
        await samplerSnapshot?.restore();
      } catch (caught, stackTrace) {
        qqe("Agent sampler restore failed: $caught");
        error.q = caught.toString();
        final activeReport = report.q;
        if (activeReport != null) {
          final failedReport = activeReport.copyWith(error: caught.toString());
          report.q = failedReport;
          try {
            await _persistReport(failedReport);
          } catch (persistError) {
            qqe("Agent report persistence failed after sampler restore error: $persistError");
          }
        }
        if (!kDebugMode) {
          unawaited(Sentry.captureException(caught, stackTrace: stackTrace));
        }
      }
      running.q = false;
      stopping.q = false;
      liveModelOutput.q = "";
    }
  }

  bool _validateActiveModel() {
    final model = P.rwkvModel.latest.q;
    if (model == null) {
      Alert.info(S.current.please_load_model_first);
      return false;
    }
    return true;
  }

  Future<AgentCaseVerdict> _recordCaseResult({
    required AgentCase agentCase,
    required AgentRunResult result,
    required AgentSandbox sandbox,
    required DateTime startedAt,
  }) async {
    final caseVerdict = agentCase.score(
      result: result,
      sandbox: sandbox,
    );
    verdict.q = caseVerdict;
    final activeReport = report.q;
    final record = AgentCaseRunRecord(
      agentCase: agentCase,
      result: result,
      verdict: caseVerdict,
      runId: activeReport?.manifest.runId ?? "",
      attempt: currentAttempt.q,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
    records.q = <String, AgentCaseRunRecord>{
      ...records.q,
      agentCase.name: record,
    };
    reportRecords.q = List<AgentCaseRunRecord>.unmodifiable(<AgentCaseRunRecord>[
      ...reportRecords.q,
      record,
    ]);
    if (result.status == .infrastructureFailed && activeReport != null) {
      report.q = activeReport.copyWith(
        error: result.events.lastOrNull?.content ?? "Infrastructure failure",
      );
    }
    await _updateAndPersistReport();
    return caseVerdict;
  }

  Future<AgentCaseVerdict?> runCaseJson(Map<String, dynamic> json) async {
    final agentCase = AgentCase.fromJson(json);
    try {
      await _beginEvaluationReport(
        repeats: 1,
        selectedCases: <String>[agentCase.name],
      );
      return await runCase(agentCase);
    } catch (caught, stackTrace) {
      _recordSessionError(caught, stackTrace);
      return null;
    } finally {
      try {
        await _completeEvaluationReport();
      } catch (caught, stackTrace) {
        _recordSessionError(caught, stackTrace);
      }
    }
  }

  Future<void> stop() async {
    if ((!running.q && !runningAll.q) || stopping.q) return;
    stopping.q = true;
    _cancelRequested = true;
    resolveLocalFileApproval(false);
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) return;
    P.rwkvBridge.send(to_rwkv.Stop(modelID: modelID));
  }

  Future<void> exportLatestReport() async {
    final activeReport = report.q;
    if (activeReport == null) {
      Alert.info(S.current.agent_eval_no_report);
      return;
    }
    await _persistReport(activeReport);
    final content = const JsonEncoder.withIndent("  ").convert(activeReport.toJson());
    final fileName = "agent-eval-${activeReport.manifest.runId}.json";
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final targetPath = await file_picker.FilePicker.saveFile(
        dialogTitle: S.current.agent_eval_export_title,
        fileName: fileName,
        type: file_picker.FileType.custom,
        allowedExtensions: const <String>["json"],
        lockParentWindow: true,
      );
      if (targetPath == null) return;
      final outputPath = extension(targetPath).isEmpty ? "$targetPath.json" : targetPath;
      await File(outputPath).writeAsString(content, encoding: utf8);
      Alert.success("${S.current.export_success}\n\n$outputPath");
      return;
    }
    final tempDir = await getTemporaryDirectory();
    final file = File(join(tempDir.path, fileName));
    await file.writeAsString(content, encoding: utf8);
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: "application/json")],
        subject: fileName,
        title: S.current.agent_eval_export_title,
      ),
    );
  }

  Future<void> _beginEvaluationReport({
    required int repeats,
    required List<String> selectedCases,
  }) async {
    final model = P.rwkvModel.latest.q;
    if (model == null) return;
    final now = DateTime.now();
    final runId =
        "${now.toUtc().toIso8601String().replaceAll(RegExp(r"[^0-9]"), "")}-${math.Random.secure().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, "0")}";
    final manifest = AgentEvaluationManifest(
      schemaVersion: agentEvaluationSchemaVersion,
      benchmarkId: agentEvaluationBenchmarkId,
      benchmarkVersion: agentEvaluationBenchmarkVersion,
      benchmarkSha256: _benchmarkSha256,
      caseCount: cases.q.length,
      runId: runId,
      mode: evaluationMode.q,
      repeatCount: repeats,
      selectedCases: List<String>.unmodifiable(selectedCases),
      plannedRuns: selectedCases.length * repeats,
      app: <String, Object?>{
        "version": P.app.version.q,
        "buildNumber": P.app.buildNumber.q,
        "buildMode": kReleaseMode
            ? "release"
            : kProfileMode
            ? "profile"
            : "debug",
        "sourceRevision": const String.fromEnvironment("GIT_COMMIT", defaultValue: "unknown"),
        "inferenceEngineRevision": P.rwkvBackend.commitId.q,
      },
      device: Map<String, Object?>.from(P.telemetry.benchmarkDeviceInfo.q),
      model: <String, Object?>{
        "name": model.name,
        "fileName": model.fileName,
        "fileSize": model.fileSize,
        "modelSize": model.modelSize,
        "quantization": model.quantization ?? "unknown",
        "backend": model.backend?.name ?? "unknown",
        "sha256": _declaredModelSha256(model.sha256),
        "sha256Verified": false,
      },
      sampler: agentEvaluationSamplerConfig.toManifest(seed: agentEvaluationSeed),
    );
    records.q = <String, AgentCaseRunRecord>{};
    reportRecords.q = <AgentCaseRunRecord>[];
    report.q = AgentEvaluationReport(
      manifest: manifest,
      startedAt: now,
      completedAt: null,
      records: const <AgentCaseRunRecord>[],
    );
    _reportOpen = true;
    await _persistReport(report.q!);
  }

  Future<void> _updateAndPersistReport() async {
    final activeReport = report.q;
    if (activeReport == null) return;
    final next = activeReport.copyWith(
      records: List<AgentCaseRunRecord>.unmodifiable(reportRecords.q),
    );
    report.q = next;
    await _persistReport(next);
  }

  Future<void> _completeEvaluationReport() async {
    if (!_reportOpen) return;
    final activeReport = report.q;
    _reportOpen = false;
    if (activeReport == null) return;
    final completed = activeReport.copyWith(
      completedAt: DateTime.now(),
      records: List<AgentCaseRunRecord>.unmodifiable(reportRecords.q),
    );
    report.q = completed;
    await _persistReport(completed);
  }

  Future<void> _persistReport(AgentEvaluationReport value) async {
    final supportDir = await getApplicationSupportDirectory();
    final reportDir = Directory(join(supportDir.path, "agent_evaluations"));
    await reportDir.create(recursive: true);
    final fileName = "agent-eval-${value.manifest.runId}.json";
    final target = File(join(reportDir.path, fileName));
    final temporary = File("${target.path}.tmp");
    final content = const JsonEncoder.withIndent("  ").convert(value.toJson());
    await temporary.writeAsString(content, encoding: utf8, flush: true);
    if (Platform.isWindows && await target.exists()) {
      await target.delete();
    }
    await temporary.rename(target.path);
    lastReportPath.q = target.path;
  }

  String _declaredModelSha256(String? value) {
    final normalized = value?.trim() ?? "";
    if (normalized.isEmpty) return "not_provided";
    return normalized;
  }

  void _recordSessionError(Object caught, StackTrace stackTrace) {
    qqe("Agent evaluation session failed: $caught");
    error.q = caught.toString();
    final activeReport = report.q;
    if (activeReport != null) {
      report.q = activeReport.copyWith(error: caught.toString());
    }
    if (kDebugMode) return;
    unawaited(Sentry.captureException(caught, stackTrace: stackTrace));
  }
}

final class _RWKVAgentModel implements AgentModel {
  final _Agent owner;
  final int modelID;

  const _RWKVAgentModel(
    this.owner, {
    required this.modelID,
  });

  @override
  Future<AgentGeneration> generate(
    String prompt, {
    required AgentEvaluationMode mode,
  }) async {
    await _waitForBackendIdle();
    if (owner._cancelRequested) throw const _AgentCancelledException();

    P.rwkvGeneration._cancelTokensTimer();
    P.rwkvGeneration.prefillSpeed.q = 0;
    P.rwkvGeneration.decodeSpeed.q = 0;
    P.rwkvGeneration.prefillProgress.q = 0;
    P.telemetry.resetPeakDecodeSpeed();

    final staleContent = await _readLatestResponseBuffer();
    if (owner._cancelRequested) throw const _AgentCancelledException();

    final protocol = const G1hAgentProtocol();
    final isToolCallContinuation = prompt.trimRight().endsWith(G1hAgentProtocol.toolCallOpen);
    final generationRequest = to_rwkv.GenerateAsync(
      prompt,
      batch: 1,
      modelID: modelID,
      maxLength: agentDefaultMaxLength,
      disableCache: false,
    );
    final bufferGate = AgentResponseBufferGate(
      staleContent: staleContent,
      replacementPrefix: prompt,
    );
    final responsePollTracker = AgentResponsePollTracker(modelID: modelID);
    final completer = Completer<AgentGeneration>();
    final stopwatch = Stopwatch()..start();
    bool finishStarted = false;
    bool firstTokenTimeoutTriggered = false;
    int pollCount = 0;
    String latest = "";
    Timer? firstTokenTimer;
    Timer? responseTimer;
    StreamSubscription<from_rwkv.FromRWKV>? subscription;

    Future<void> finish({
      required String output,
      required bool stopBackend,
      required String stopReason,
      List<AgentInterventionKind> interventions = const <AgentInterventionKind>[],
    }) async {
      if (completer.isCompleted || finishStarted) return;
      finishStarted = true;
      firstTokenTimer?.cancel();
      try {
        if (stopBackend) {
          await _stopBackendAndSync();
        }
        if (completer.isCompleted) return;
        completer.complete(
          AgentGeneration(
            rawOutput: latest,
            output: output,
            interventions: List<AgentInterventionKind>.unmodifiable(interventions),
            stopReason: stopReason,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
      } catch (caught, stackTrace) {
        if (completer.isCompleted) return;
        completer.completeError(caught, stackTrace);
      }
    }

    Future<void> fail({
      required AgentInfrastructureException error,
      required bool stopBackend,
    }) async {
      if (completer.isCompleted || finishStarted) return;
      finishStarted = true;
      firstTokenTimer?.cancel();
      if (stopBackend) {
        try {
          await _stopBackendAndSync();
        } catch (caught) {
          qqe("Agent backend stop after ${error.code} failed: $caught");
        }
      }
      if (completer.isCompleted) return;
      completer.completeError(error, StackTrace.current);
    }

    void requestLatestBuffer() {
      if (completer.isCompleted || finishStarted) return;
      final request = to_rwkv.GetResponseBufferContent(
        messages: const <String>[],
        modelID: modelID,
      );
      responsePollTracker.register(request.requestId);
      P.rwkvBridge.send(request);
      pollCount += 1;
      if (pollCount % 5 != 0) return;
      P.rwkvBridge.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    }

    subscription = P.rwkvBridge.broadcastStream.listen(
      (event) {
        if (event is from_rwkv.GenerateStart) {
          if (event.req?.requestId != generationRequest.requestId) return;
          P.rwkvGeneration.generating.q = true;
          return;
        }
        if (event is from_rwkv.GenerateStop) {
          if (event.req?.requestId != generationRequest.requestId) return;
          final message = event.error;
          if (message == null || message.isEmpty) return;
          unawaited(
            fail(
              error: AgentInfrastructureException(
                code: "backend_generation_error",
                message: message,
              ),
              stopBackend: false,
            ),
          );
          return;
        }
        if (event is from_rwkv.Error) {
          final requestId = event.req?.requestId;
          final belongsToGeneration = requestId == generationRequest.requestId;
          final errorRequest = event.req;
          final belongsToResponsePoll =
              requestId != null &&
              errorRequest is to_rwkv.GetResponseBufferContent &&
              responsePollTracker.consume(
                modelID: errorRequest.modelID,
                requestId: requestId,
              );
          if (!belongsToGeneration && !belongsToResponsePoll) return;
          unawaited(
            fail(
              error: AgentInfrastructureException(
                code: "backend_generation_error",
                message: event.message,
              ),
              stopBackend: belongsToGeneration,
            ),
          );
          return;
        }
        if (event is! from_rwkv.ResponseBufferContent) return;
        final request = event.req;
        if (request is! to_rwkv.GetResponseBufferContent || request.modelID != modelID) {
          return;
        }
        if (!responsePollTracker.consume(
          modelID: request.modelID,
          requestId: request.requestId,
        )) {
          return;
        }

        final fresh = bufferGate.freshContent(event.responseBufferContent);
        if (fresh.isEmpty) return;
        latest = fresh.startsWith(prompt) ? fresh.substring(prompt.length) : fresh;
        if (latest.isEmpty) return;
        firstTokenTimer?.cancel();
        owner.liveModelOutput.q = latest;

        if (event.eosFound) {
          unawaited(
            finish(
              output: latest,
              stopBackend: false,
              stopReason: "eos",
            ),
          );
          return;
        }
        if (isToolCallContinuation) {
          final parsedContinuation = protocol.parse(
            "${G1hAgentProtocol.toolCallOpen}$latest",
            callOrdinal: 1,
            mode: mode,
          );
          if (parsedContinuation.kind == .toolCall) {
            unawaited(
              finish(
                output: latest,
                stopBackend: true,
                stopReason: "tool_call_complete",
              ),
            );
            return;
          }
          if (latest.length >= agentToolCallCharacterBudget) {
            unawaited(
              finish(
                output: latest,
                stopBackend: true,
                stopReason: "tool_call_budget",
                interventions: const <AgentInterventionKind>[
                  .generationBudgetStop,
                ],
              ),
            );
            return;
          }
        }
        final truncatedRepeatedOutput = protocol.truncateAtRepeatedThinkClose(latest);
        if (truncatedRepeatedOutput != null) {
          unawaited(
            finish(
              output: truncatedRepeatedOutput,
              stopBackend: true,
              stopReason: "repeated_think",
              interventions: const <AgentInterventionKind>[
                .repeatedThinkTruncation,
              ],
            ),
          );
          return;
        }
        final truncatedRepeatedText = protocol.truncateAtRepeatedText(latest);
        if (truncatedRepeatedText != null) {
          final assistedOutput = _forceToolCallAfterRepeatedText(
            prompt: prompt,
            output: truncatedRepeatedText,
          );
          unawaited(
            finish(
              output: mode == .assisted ? assistedOutput : truncatedRepeatedText,
              stopBackend: true,
              stopReason: "repeated_text",
              interventions: <AgentInterventionKind>[
                .repeatedTextTruncation,
                if (mode == .assisted && assistedOutput != truncatedRepeatedText) .forcedToolCall,
              ],
            ),
          );
          return;
        }
        final hasToolCall = latest.contains(G1hAgentProtocol.toolCallOpen);
        final hasThinkClose = latest.contains(G1hAgentProtocol.thinkClose);
        if (!isToolCallContinuation && !hasToolCall && !hasThinkClose && latest.length >= agentReasoningCharacterBudget) {
          final assistedOutput = _forceToolCallAfterRepeatedText(
            prompt: prompt,
            output: latest,
          );
          unawaited(
            finish(
              output: mode == .assisted ? assistedOutput : latest,
              stopBackend: true,
              stopReason: "reasoning_budget",
              interventions: <AgentInterventionKind>[
                .generationBudgetStop,
                if (mode == .assisted && assistedOutput != latest) .forcedToolCall,
              ],
            ),
          );
          return;
        }
        if (!hasToolCall && hasThinkClose && latest.length >= agentFinalAnswerCharacterBudget) {
          unawaited(
            finish(
              output: latest,
              stopBackend: true,
              stopReason: "final_answer_budget",
              interventions: const <AgentInterventionKind>[
                .generationBudgetStop,
              ],
            ),
          );
          return;
        }
        if (latest.contains(G1hAgentProtocol.toolCallOpen) ||
            latest.contains(G1hAgentProtocol.toolCallClose) ||
            latest.contains("<EOD>") ||
            latest.contains("\n\nUser:") ||
            latest.contains("\nUser:")) {
          unawaited(
            finish(
              output: latest,
              stopBackend: true,
              stopReason: "protocol_boundary",
            ),
          );
          return;
        }
        if (latest.contains("</s>")) {
          unawaited(
            finish(
              output: latest,
              stopBackend: true,
              stopReason: "stop_token",
            ),
          );
        }
      },
      onError: (Object caught, StackTrace stackTrace) {
        unawaited(
          fail(
            error: AgentInfrastructureException(
              code: "backend_stream_error",
              message: caught.toString(),
            ),
            stopBackend: true,
          ),
        );
      },
    );

    P.rwkvGeneration.generating.q = true;
    P.rwkvBridge.send(generationRequest);
    requestLatestBuffer();
    responseTimer = Timer.periodic(
      agentModelResponsePollInterval,
      (_) => requestLatestBuffer(),
    );
    firstTokenTimer = Timer(agentModelFirstTokenTimeout, () {
      if (completer.isCompleted || finishStarted) return;
      firstTokenTimeoutTriggered = true;
      unawaited(
        fail(
          error: const AgentInfrastructureException(
            code: "first_token_timeout",
            message: "Inference engine produced no model output within 20 seconds",
          ),
          stopBackend: true,
        ),
      );
    });
    final cancellationTimer = Timer.periodic(agentModelPollInterval, (_) {
      if (!owner._cancelRequested || completer.isCompleted || finishStarted) {
        return;
      }
      finishStarted = true;
      unawaited(_cancelGeneration(completer));
    });

    try {
      return await completer.future.timeout(agentModelGenerationTimeout);
    } on TimeoutException {
      try {
        await _stopBackendAndSync();
      } catch (caught) {
        qqe("Agent backend stop after generation timeout failed: $caught");
      }
      throw AgentInfrastructureException(
        code: "generation_timeout",
        message: "Agent model generation exceeded ${agentModelGenerationTimeout.inMinutes} minutes",
      );
    } finally {
      cancellationTimer.cancel();
      firstTokenTimer.cancel();
      responseTimer.cancel();
      await subscription.cancel();
      if (!firstTokenTimeoutTriggered) {
        await _waitForBackendIdle();
      }
    }
  }

  Future<void> _cancelGeneration(Completer<AgentGeneration> completer) async {
    try {
      await _stopBackendAndSync();
      if (completer.isCompleted) return;
      completer.completeError(const _AgentCancelledException());
    } catch (caught, stackTrace) {
      if (completer.isCompleted) return;
      completer.completeError(caught, stackTrace);
    }
  }

  Future<void> _waitForBackendIdle() async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      final isGenerating = await _queryIsGenerating();
      if (!isGenerating) {
        P.rwkvGeneration.generating.q = false;
        return;
      }
      if (stopwatch.elapsed >= agentModelIdleTimeout) {
        throw const AgentInfrastructureException(
          code: "backend_idle_timeout",
          message: "Inference engine did not confirm idle state",
        );
      }
      await Future<void>.delayed(agentModelPollInterval);
    }
  }

  Future<void> _stopBackendAndSync() async {
    final stopRequest = to_rwkv.Stop(modelID: modelID);
    final stopSignal = P.rwkvBridge.broadcastStream
        .where((event) {
          if (event is from_rwkv.GenerateStop) {
            final request = event.req;
            return request is to_rwkv.Stop && request.modelID == modelID;
          }
          if (event is from_rwkv.IsGenerating) {
            return event.modelID == modelID && !event.isGenerating;
          }
          return false;
        })
        .first
        .timeout(agentModelStopSignalTimeout);
    try {
      P.rwkvBridge.send(stopRequest);
      await stopSignal;
    } on TimeoutException {
      final isGenerating = await _queryIsGenerating();
      if (isGenerating) {
        throw const AgentInfrastructureException(
          code: "backend_stop_timeout",
          message: "Inference engine did not confirm stop for the active model",
        );
      }
    }
    await _waitForBackendIdle();
    P.rwkvGeneration._cancelTokensTimer();
    P.rwkvGeneration.generating.q = false;
  }

  Future<String> _readLatestResponseBuffer() async {
    final request = to_rwkv.GetResponseBufferContent(
      messages: const <String>[],
      modelID: modelID,
    );
    final response = P.rwkvBridge.broadcastStream
        .whereType<from_rwkv.ResponseBufferContent>()
        .where((event) {
          final responseRequest = event.req;
          if (responseRequest is! to_rwkv.GetResponseBufferContent) return false;
          return responseRequest.modelID == modelID && responseRequest.requestId == request.requestId;
        })
        .first
        .timeout(agentModelStopSignalTimeout);
    P.rwkvBridge.send(request);
    try {
      return (await response).responseBufferContent;
    } on TimeoutException {
      throw const AgentInfrastructureException(
        code: "backend_buffer_timeout",
        message: "Inference engine did not report its current response buffer",
      );
    }
  }

  Future<bool> _queryIsGenerating() async {
    final request = to_rwkv.GetIsGenerating(modelID: modelID);
    final response = P.rwkvBridge.broadcastStream
        .whereType<from_rwkv.IsGenerating>()
        .where((event) {
          final responseRequest = event.req;
          return event.modelID == modelID && responseRequest is to_rwkv.GetIsGenerating && responseRequest.modelID == modelID;
        })
        .first
        .timeout(agentModelStopSignalTimeout);
    P.rwkvBridge.send(request);
    try {
      final value = await response;
      return value.isGenerating;
    } on TimeoutException {
      throw const AgentInfrastructureException(
        code: "backend_status_timeout",
        message: "Inference engine did not report generation state",
      );
    }
  }

  String _forceToolCallAfterRepeatedText({
    required String prompt,
    required String output,
  }) {
    if (prompt.trimRight().endsWith(G1hAgentProtocol.toolCallOpen)) {
      return output;
    }
    final buffer = StringBuffer(output.trimRight());
    if (!output.contains(G1hAgentProtocol.thinkClose)) {
      buffer.write("\n${G1hAgentProtocol.thinkClose}");
    }
    buffer.write("\n${G1hAgentProtocol.toolCallOpen}");
    return buffer.toString();
  }
}

final class _AgentCancelledException implements Exception {
  const _AgentCancelledException();

  @override
  String toString() {
    return "Agent run cancelled";
  }
}

final class _AgentSamplerSnapshot {
  final double temperature;
  final double topK;
  final double topP;
  final double presencePenalty;
  final double frequencyPenalty;
  final double penaltyDecay;
  final int seed;
  final int modelID;

  const _AgentSamplerSnapshot({
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.presencePenalty,
    required this.frequencyPenalty,
    required this.penaltyDecay,
    required this.seed,
    required this.modelID,
  });

  static Future<_AgentSamplerSnapshot> capture({
    required int modelID,
  }) async {
    final seed = await _readSeed(modelID);
    return _AgentSamplerSnapshot(
      temperature: P.rwkvParams.arguments(Argument.temperature).q,
      topK: P.rwkvParams.arguments(Argument.topK).q,
      topP: P.rwkvParams.arguments(Argument.topP).q,
      presencePenalty: P.rwkvParams.arguments(Argument.presencePenalty).q,
      frequencyPenalty: P.rwkvParams.arguments(Argument.frequencyPenalty).q,
      penaltyDecay: P.rwkvParams.arguments(Argument.penaltyDecay).q,
      seed: seed,
      modelID: modelID,
    );
  }

  static Future<int> _readSeed(int modelID) async {
    final request = to_rwkv.GetSeed(modelID: modelID);
    final response = P.rwkvBridge.broadcastStream
        .whereType<from_rwkv.CurrentSeed>()
        .where((event) {
          final responseRequest = event.req;
          return event.modelID == modelID && responseRequest is to_rwkv.GetSeed && responseRequest.modelID == modelID;
        })
        .first
        .timeout(agentModelStopSignalTimeout);
    P.rwkvBridge.send(request);
    try {
      return (await response).seed;
    } on TimeoutException {
      throw const AgentInfrastructureException(
        code: "backend_seed_timeout",
        message: "Inference engine did not report its current random seed",
      );
    }
  }

  Future<void> setSeed(int value) async {
    P.rwkvBridge.send(to_rwkv.SetSeed(value, modelID: modelID));
    final confirmed = await _readSeed(modelID);
    if (confirmed == value) return;
    throw AgentInfrastructureException(
      code: "backend_seed_mismatch",
      message: "Inference engine reported seed $confirmed after setting $value",
    );
  }

  Future<void> restore() async {
    await P.rwkvParams.syncSamplerParams(
      temperature: temperature,
      topK: topK,
      topP: topP,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      penaltyDecay: penaltyDecay,
    );
    await setSeed(seed);
  }
}
