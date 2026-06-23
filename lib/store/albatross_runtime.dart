part of 'p.dart';

const String _albatrossHostPreferenceKey = "halo_state.albatross.host";
const String _albatrossPortPreferenceKey = "halo_state.albatross.port";
const String _albatrossExecutablePathPreferenceKey = "halo_state.albatross.executablePath";
const String _albatrossModelPathPreferenceKey = "halo_state.albatross.modelPath";
const String _albatrossTokenizerPathPreferenceKey = "halo_state.albatross.tokenizerPath";
const int _albatrossLogLimit = 400;
const int _albatrossStartupProbeAttempts = 180;
const Duration _albatrossStartupProbeInterval = Duration(seconds: 1);

enum AlbatrossSetupPanel {
  computer,
  endpoint,
  runtimeAssets,
  model,
}

enum _AlbatrossEndpointPreflight {
  availableService,
  launchablePort,
  invalid,
}

class _AlbatrossRuntime {
  static const String _defaultHost = "127.0.0.1";
  static const int _defaultPort = 9527;
  static const List<int> _defaultStopTokens = <int>[0, 261, 24281];
  static const int _chunkSize = 3;

  Process? _process;
  http.Client? _client;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  Timer? _metricsTimer;
  bool _metricsPollInFlight = false;
  int? _lastMetricGeneratedTokens;
  DateTime? _lastMetricAt;
  String? _lastMetricsDebugLine;
  bool _detachedRuntimeLaunched = false;
  // ignore: unused_field
  AppLifecycleListener? _lifecycleListener;

  late final enabled = qs(false);
  late final connecting = qs(false);
  late final checkingService = qs(false);
  late final running = qs(false);
  late final downloading = qs(false);
  late final launchedByApp = qs(false);
  late final host = qs(_defaultHost);
  late final port = qs(_defaultPort);
  late final executablePath = qs("");
  late final modelPath = qs("");
  late final tokenizerPath = qs("");
  late final lastError = qs("");
  late final processId = qs<int?>(null);
  late final processExitCode = qs<int?>(null);
  late final logs = qs<List<String>>([]);
  late final cudaInfo = qs<Map<String, String>>({});
  late final highlightedSetupPanels = qs<Set<AlbatrossSetupPanel>>(const <AlbatrossSetupPanel>{});

  late final displaySystemInfo = qp<Map<String, String>>((ref) {
    final telemetryInfo = ref.watch(P.telemetry.benchmarkDeviceInfo);
    final cudaInfo = ref.watch(this.cudaInfo);
    return buildAlbatrossDisplaySystemInfo(
      telemetryInfo: telemetryInfo,
      cudaInfo: cudaInfo,
      isDesktop: Platform.isWindows || Platform.isLinux || Platform.isMacOS,
    );
  });

  late final cudaBackendAvailable = qp<bool>((ref) {
    final telemetryInfo = ref.watch(P.telemetry.benchmarkDeviceInfo);
    final cudaInfo = ref.watch(this.cudaInfo);
    return isAlbatrossCudaBackendAvailable(
      isWindows: Platform.isWindows,
      isLinux: Platform.isLinux,
      isMacOS: Platform.isMacOS,
      telemetryInfo: telemetryInfo,
      cudaInfo: cudaInfo,
    );
  });

  late final baseUrl = qp<String>((ref) {
    final host = ref.watch(this.host).trim();
    final port = ref.watch(this.port);
    return "http://$host:$port";
  });

  late final canShowHomeEntry = qp<bool>((ref) {
    final gpuName = ref.watch(P.telemetry.gpuName);
    return shouldShowAlbatrossEntry(
      isWindows: Platform.isWindows,
      isWindowsX64: ffi.Abi.current() == ffi.Abi.windowsX64,
      isLinux: Platform.isLinux,
      isMacOS: Platform.isMacOS,
      gpuName: gpuName,
    );
  });

  late final canUse = qp<bool>((ref) {
    final enabled = ref.watch(this.enabled);
    final running = ref.watch(this.running);
    return enabled && running;
  });

  late final launchCommand = qp<String>((ref) {
    final executablePath = ref.watch(this.executablePath);
    final modelPath = ref.watch(this.modelPath);
    final tokenizerPath = ref.watch(this.tokenizerPath);
    final host = ref.watch(this.host);
    final port = ref.watch(this.port);
    if (executablePath.isEmpty) return "";
    final args = _launchArgsFor(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      host: host,
      port: port,
    );
    return buildAlbatrossLaunchCommand(executablePath: executablePath, args: args);
  });

  late final pthCandidates = qp<List<FileInfo>>((ref) {
    final remoteWeights = ref.watch(P.remote.chatWeights);
    final folders = ref.watch(P.pth.folders);
    final result = <FileInfo>[];
    final seen = <String>{};

    void add(FileInfo fileInfo) {
      final key = normalize(fileInfo.raw);
      if (seen.contains(key)) return;
      seen.add(key);
      result.add(fileInfo);
    }

    for (final fileInfo in remoteWeights) {
      final fileName = fileInfo.fileName.toLowerCase();
      if (!fileName.endsWith(".pth") && !fileInfo.isAlbatross) continue;
      add(fileInfo);
    }

    for (final folder in folders) {
      for (final fileInfo in folder.files) {
        if (!fileInfo.fromPthFile) continue;
        add(fileInfo);
      }
    }

    result.sort((a, b) => b.fileSize.compareTo(a.fileSize));
    return result;
  });
}

extension $AlbatrossRuntime on _AlbatrossRuntime {
  Future<void> _init() async {
    _applyConfigDefaults();
    await _loadPreferences();
    unawaited(refreshCudaInfo());
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state != AppLifecycleState.detached) return;
        unawaited(shutdown());
      },
    );
  }

  void enableExternalMode() {
    enabled.q = true;
    P.rwkvParams.supportedBatchSizes.q = [2, 4, 6, 8, 10];
  }

  void disableExternalMode() {
    enabled.q = false;
  }

  Future<void> _loadPreferences() async {
    final sp = await SharedPreferences.getInstance();
    host.q = sp.getString(_albatrossHostPreferenceKey) ?? host.q;
    port.q = sp.getInt(_albatrossPortPreferenceKey) ?? port.q;
    executablePath.q = sp.getString(_albatrossExecutablePathPreferenceKey) ?? executablePath.q;
    modelPath.q = sp.getString(_albatrossModelPathPreferenceKey) ?? modelPath.q;
    tokenizerPath.q = sp.getString(_albatrossTokenizerPathPreferenceKey) ?? tokenizerPath.q;
  }

  Future<void> setHost(String value) async {
    final next = value.trim().isEmpty ? _AlbatrossRuntime._defaultHost : value.trim();
    host.q = next;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_albatrossHostPreferenceKey, next);
  }

  Future<void> setPortFromText(String value) async {
    final next = int.tryParse(value.trim());
    if (next == null) return;
    await setPort(next);
  }

  Future<void> setPort(int value) async {
    if (value <= 0 || value > 65535) return;
    port.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_albatrossPortPreferenceKey, value);
  }

  Future<void> setExecutablePath(String value) async {
    executablePath.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_albatrossExecutablePathPreferenceKey, value);
  }

  Future<void> setModelPath(String value) async {
    modelPath.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_albatrossModelPathPreferenceKey, value);
  }

  Future<void> setTokenizerPath(String value) async {
    tokenizerPath.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_albatrossTokenizerPathPreferenceKey, value);
  }

  void _applyConfigDefaults() {
    final binaryConfig = _binaryConfig;
    final configPort = _configInt(binaryConfig, "default_port") ?? _configInt(binaryConfig, "port");
    if (configPort != null && configPort > 0) {
      port.q = configPort;
    }
    final configHost = _configString(binaryConfig, "host");
    if (configHost != null && configHost.isNotEmpty) {
      host.q = configHost;
    }
  }

  Future<bool> prepareForChat() async {
    if (connecting.q) {
      _addLog("start ignored: already connecting");
      return false;
    }

    enableExternalMode();
    connecting.q = true;
    lastError.q = "";
    processExitCode.q = null;
    try {
      _addLog("prepare for chat");
      final connected = await probe();
      if (connected) {
        _addLog("service already running at ${baseUrl.q}");
        return true;
      }

      if (!_canLaunchRuntime(showAlert: true)) return false;
      await _ensureConfiguredAssets();
      await _startProcess();
      return await _waitUntilRunning();
    } catch (e) {
      lastError.q = e.toString();
      _addLog("error: $e");
      Alert.error(e.toString());
      return false;
    } finally {
      connecting.q = false;
    }
  }

  Future<bool> probe({bool verbose = true}) async {
    final client = http.Client();
    try {
      for (final path in albatrossProbePaths) {
        try {
          final uri = Uri.parse("${baseUrl.q}$path");
          final response = await client.get(uri).timeout(const Duration(seconds: 2));
          final ok = response.statusCode >= 200 && response.statusCode < 300;
          if (verbose) _addLog("probe $path: ${response.statusCode}");
          if (!ok) continue;
          running.q = true;
          return true;
        } catch (e) {
          if (verbose) _addLog("probe $path failed: $e");
        }
      }
      running.q = false;
      if (verbose) _addLog("probe failed");
      return false;
    } finally {
      client.close();
    }
  }

  Future<void> probeAndNotify() async {
    if (checkingService.q) return;

    checkingService.q = true;
    try {
      final ok = await probe();
      if (ok) {
        Alert.success(S.current.albatross_connected);
        return;
      }
      Alert.warning(S.current.albatross_service_not_running);
    } finally {
      checkingService.q = false;
    }
  }

  Future<void> downloadConfiguredBinary() async {
    final fileInfo = _fileInfoFromConfig(_binaryConfig);
    if (fileInfo == null) {
      Alert.error(S.current.albatross_binary_config_missing);
      _addLog("binary config missing");
      return;
    }
    downloading.q = true;
    try {
      _addLog("download binary: ${fileInfo.fileName}");
      await P.remote.getFile(fileInfo: fileInfo);
      await setExecutablePath(P.remote.locals(fileInfo).q.targetPath);
    } finally {
      downloading.q = false;
    }
  }

  Future<void> downloadConfiguredTokenizer() async {
    final fileInfo = _fileInfoFromConfig(_tokenizerConfig);
    if (fileInfo == null) {
      Alert.error(S.current.albatross_tokenizer_config_missing);
      _addLog("tokenizer config missing");
      return;
    }
    downloading.q = true;
    try {
      _addLog("download tokenizer: ${fileInfo.fileName}");
      await P.remote.getFile(fileInfo: fileInfo);
      await setTokenizerPath(P.remote.locals(fileInfo).q.targetPath);
    } finally {
      downloading.q = false;
    }
  }

  Future<void> pickExecutable() async {
    final result = Platform.isWindows
        ? await file_picker.FilePicker.pickFiles(
            type: file_picker.FileType.custom,
            allowedExtensions: const <String>["exe"],
          )
        : await file_picker.FilePicker.pickFiles();
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;
    await setExecutablePath(path);
  }

  Future<void> pickModelPth() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: const <String>["pth"],
    );
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;
    await setModelPath(path);
  }

  Future<void> pickTokenizer() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: const <String>["txt", "json", "model"],
    );
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;
    await setTokenizerPath(path);
  }

  Future<void> useDownloadedModel(FileInfo fileInfo) async {
    final local = P.remote.locals(fileInfo).q;
    if (!local.hasFile) {
      Alert.info(S.current.chat_you_need_download_model_if_you_want_to_use_it);
      return;
    }
    await setModelPath(local.targetPath);
  }

  Future<void> selectPthModel(FileInfo fileInfo) async {
    if (fileInfo.fromPthFile) {
      await setModelPath(fileInfo.raw);
      return;
    }
    final local = P.remote.locals(fileInfo).q;
    if (local.hasFile) {
      await setModelPath(local.targetPath);
      return;
    }
    await downloadPthModel(fileInfo);
  }

  Future<void> downloadPthModel(FileInfo fileInfo) async {
    await P.remote.getFile(fileInfo: fileInfo);
  }

  Future<void> handleDroppedPath(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      return;
    }
    final lower = path.toLowerCase();
    if (lower.endsWith(".pth")) {
      await setModelPath(path);
      return;
    }
    if (lower.endsWith(".txt") || lower.endsWith(".json") || lower.endsWith(".model")) {
      await setTokenizerPath(path);
      return;
    }
    if (lower.endsWith(".exe")) {
      await setExecutablePath(path);
    }
  }

  Future<void> handleDroppedItems(List<desktop_drop.DropItem> items) async {
    for (final item in items) {
      await handleDroppedPath(item.path);
    }
  }

  Stream<from_rwkv.FromRWKV> chat(List<String> messages, {int batchSize = 1}) async* {
    if (batchSize <= 1 && messages.length.isOdd) {
      yield* _streamChatMessages(messages);
      return;
    }

    final prompt = _buildChatCompletionPrompt(messages);
    final initialOutput = _initialChatOutput(messages);
    await for (final event in _streamContents(
      contents: List<String>.filled(batchSize, prompt),
      includePromptInOutput: false,
      initialOutputs: List<String>.filled(batchSize, initialOutput),
    )) {
      if (batchSize == 1) {
        yield from_rwkv.ResponseBufferContent(
          responseBufferContent: event.responseBufferContent.firstOrNull ?? "",
          eosFound: event.eosFound.firstOrNull ?? false,
        );
      } else {
        yield event;
      }
    }
  }

  Stream<from_rwkv.FromRWKV> _streamChatMessages(List<String> messages) async* {
    final requestMessages = _buildChatRequestMessages(messages);
    final thinkingMode = P.rwkvParams.thinkingMode.q;
    final enableThink = thinkingMode.hasThinkTag;
    final thinkType = thinkingMode.albatrossThinkType;
    final initialOutput = enableThink ? _assistantPrefix().trim() : "";
    String result = initialOutput;
    final parser = AlbatrossSseParser();

    P.rwkvGeneration.generating.q = true;
    _client?.close();
    _client = http.Client();
    _startMetricsPolling();
    bool shouldPollFinalMetrics = false;
    try {
      final request = http.Request("POST", Uri.parse("${baseUrl.q}/v1/chat/completions"));
      request.headers["Content-Type"] = "application/json";
      final requestBody = <String, Object?>{
        "model": "albatross",
        "messages": requestMessages,
        "stop_tokens": _AlbatrossRuntime._defaultStopTokens,
        "chunk_size": _AlbatrossRuntime._chunkSize,
        "stream": true,
        "enable_think": enableThink,
        ..._decodeParams(),
      };
      if (thinkType != null) {
        requestBody["think_type"] = thinkType;
      }
      request.body = jsonEncode(requestBody);
      final response = await _client!.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw "${response.statusCode}: $body";
      }
      shouldPollFinalMetrics = true;

      await for (final rawChunk in response.stream.transform(utf8.decoder)) {
        final events = parser.add(rawChunk);
        for (final event in events) {
          if (event.done) {
            await _pollFinalMetricsOnce();
            shouldPollFinalMetrics = false;
            yield from_rwkv.ResponseBufferContent(
              responseBufferContent: result,
              eosFound: true,
            );
            return;
          }
          for (final choice in event.choices) {
            if (choice.index != 0) continue;
            result = result + choice.content;
            _markPrefillComplete();
            yield from_rwkv.ResponseBufferContent(
              responseBufferContent: result,
              eosFound: choice.finishReason != null,
            );
          }
        }
      }
    } finally {
      if (shouldPollFinalMetrics) await _pollFinalMetricsOnce();
      _stopMetricsPolling();
      _client?.close();
      _client = null;
    }
  }

  Stream<from_rwkv.ResponseBatchBufferContent> chatSlots(List<List<String>> batchMessages) {
    final contents = batchMessages.map(_buildChatCompletionPrompt).toList();
    final initialOutputs = batchMessages.map(_initialChatOutput).toList();
    return _streamContents(
      contents: contents,
      includePromptInOutput: false,
      initialOutputs: initialOutputs,
    );
  }

  Stream<from_rwkv.ResponseBatchBufferContent> completion(
    String prompt, {
    int batchSize = 1,
    bool includePromptInOutput = true,
  }) {
    return _streamContents(
      contents: List<String>.filled(batchSize, prompt),
      includePromptInOutput: includePromptInOutput,
    );
  }

  Future<int?> countTextTokens(String text) {
    if (text.isEmpty) return Future.value(0);
    return _countTokens(<String, Object?>{"text": text});
  }

  Future<int?> countMessageTokens(List<String> messages) {
    if (messages.isEmpty) return Future.value(0);
    return _countTokens(<String, Object?>{"text": _buildChatCompletionPrompt(messages)});
  }

  Future<int?> _countTokens(Map<String, Object?> body) async {
    try {
      final uri = Uri.parse("${baseUrl.q}/v1/tokens/count");
      final response = await http
          .post(
            uri,
            headers: <String, String>{"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final tokens = decoded["tokens"];
      if (tokens is int) return tokens;
      return null;
    } catch (e) {
      _addLog("count tokens failed: $e");
      return null;
    }
  }

  Stream<from_rwkv.ResponseBatchBufferContent> _streamContents({
    required List<String> contents,
    required bool includePromptInOutput,
    List<String>? initialOutputs,
  }) async* {
    final batchSize = contents.length;
    final result = includePromptInOutput
        ? List<String>.from(contents)
        : List<String>.generate(batchSize, (index) {
            if (initialOutputs == null) return "";
            if (index >= initialOutputs.length) return "";
            return initialOutputs[index];
          });
    final eosFound = List<bool>.filled(batchSize, false);
    final parser = AlbatrossSseParser();

    P.rwkvGeneration.generating.q = true;
    _client?.close();
    _client = http.Client();
    _startMetricsPolling();
    bool shouldPollFinalMetrics = false;
    try {
      final request = http.Request("POST", Uri.parse("${baseUrl.q}/v1/batch/completions"));
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode({
        "contents": contents,
        "stop_tokens": _AlbatrossRuntime._defaultStopTokens,
        "chunk_size": _AlbatrossRuntime._chunkSize,
        "stream": true,
        ..._decodeParams(),
      });
      final response = await _client!.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw "${response.statusCode}: $body";
      }
      shouldPollFinalMetrics = true;

      await for (final rawChunk in response.stream.transform(utf8.decoder)) {
        final events = parser.add(rawChunk);
        for (final event in events) {
          if (event.done) {
            await _pollFinalMetricsOnce();
            shouldPollFinalMetrics = false;
            yield from_rwkv.ResponseBatchBufferContent(
              responseBufferContent: List<String>.from(result),
              eosFound: List<bool>.filled(batchSize, true),
              batchSize: batchSize,
            );
            return;
          }
          for (final choice in event.choices) {
            if (choice.index < 0 || choice.index >= batchSize) continue;
            result[choice.index] = result[choice.index] + choice.content;
            eosFound[choice.index] = choice.finishReason != null;
            _markPrefillComplete();
          }
          yield from_rwkv.ResponseBatchBufferContent(
            responseBufferContent: List<String>.from(result),
            eosFound: List<bool>.from(eosFound),
            batchSize: batchSize,
          );
        }
      }
    } finally {
      if (shouldPollFinalMetrics) await _pollFinalMetricsOnce();
      _stopMetricsPolling();
      P.rwkvGeneration.generating.q = false;
      _client?.close();
      _client = null;
    }
  }

  Future<void> stop() async {
    _client?.close();
    _client = null;
    _stopMetricsPolling();
    try {
      final uri = Uri.parse("${baseUrl.q}/v1/server/stop");
      await http.post(uri).timeout(const Duration(seconds: 2));
      _addLog("stop active request");
    } catch (e) {
      qqw("Albatross stop failed: $e");
      _addLog("stop active request failed: $e");
    } finally {
      P.rwkvGeneration.generating.q = false;
    }
  }

  Future<void> shutdown({bool terminateRuntime = false}) async {
    _client?.close();
    _client = null;
    _stopMetricsPolling();
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;

    final pid = processId.q;
    if (terminateRuntime && launchedByApp.q && pid != null) {
      _addLog("terminate process: $pid");
      final killed = Process.killPid(pid);
      _addLog("terminate process signal sent: $killed");
    } else if (terminateRuntime && launchedByApp.q && !_detachedRuntimeLaunched) {
      _addLog("kill process");
      _process?.kill();
    } else if (launchedByApp.q && _detachedRuntimeLaunched) {
      _addLog("keep detached process running");
    }

    _process = null;
    _detachedRuntimeLaunched = false;
    launchedByApp.q = false;
    running.q = false;
    processId.q = null;
  }

  Future<void> stopRuntime() async {
    await stop();
    await shutdown(terminateRuntime: true);
    disableExternalMode();
  }

  Future<void> restartRuntime() async {
    if (!_canLaunchRuntime(showAlert: true)) return;

    await stopRuntime();
    await prepareForChat();
  }

  Future<void> startChat({
    String? hostText,
    String? portText,
  }) async {
    clearLogs();
    clearSetupHighlights();
    final passedPreflight = await _runStartChatPreflight(
      hostText: hostText,
      portText: portText,
    );
    if (!passedPreflight) return;

    final ok = await prepareForChat();
    if (!ok) return;
    P.chat.startNewChat();
    await push(.chat);
  }

  void clearLogs() {
    logs.q = [];
  }

  void clearSetupHighlights() {
    highlightedSetupPanels.q = const <AlbatrossSetupPanel>{};
  }

  Future<bool> _runStartChatPreflight({
    required String? hostText,
    required String? portText,
  }) async {
    final failedPanels = <AlbatrossSetupPanel>{};
    final endpointStatus = await _checkEndpointForStart(
      hostText: hostText,
      portText: portText,
    );

    if (endpointStatus == _AlbatrossEndpointPreflight.invalid) {
      failedPanels.add(AlbatrossSetupPanel.endpoint);
    }

    if (endpointStatus != _AlbatrossEndpointPreflight.availableService) {
      if (!_canLaunchRuntime(showAlert: false) || !cudaBackendAvailable.q) {
        failedPanels.add(AlbatrossSetupPanel.computer);
      }
      if (!await _runtimeAssetsReadyForStart()) {
        failedPanels.add(AlbatrossSetupPanel.runtimeAssets);
      }
      if (!await _modelReadyForStart()) {
        failedPanels.add(AlbatrossSetupPanel.model);
      }
    }

    if (failedPanels.isEmpty) return true;

    highlightedSetupPanels.q = Set<AlbatrossSetupPanel>.unmodifiable(failedPanels);
    final message = S.current.albatross_preflight_failed;
    lastError.q = message;
    _addLog("preflight failed: ${failedPanels.map((panel) => panel.name).join(", ")}");
    Alert.warning(message);
    return false;
  }

  Future<_AlbatrossEndpointPreflight> _checkEndpointForStart({
    required String? hostText,
    required String? portText,
  }) async {
    final nextHost = (hostText ?? host.q).trim();
    if (nextHost.isEmpty) {
      _addLog("host missing");
      return _AlbatrossEndpointPreflight.invalid;
    }

    final nextPort = int.tryParse((portText ?? port.q.toString()).trim());
    if (nextPort == null || nextPort <= 0 || nextPort > 65535) {
      _addLog("port invalid");
      return _AlbatrossEndpointPreflight.invalid;
    }

    await setHost(nextHost);
    await setPort(nextPort);

    if (await probe()) return _AlbatrossEndpointPreflight.availableService;
    if (await _endpointCanBind(nextHost, nextPort)) return _AlbatrossEndpointPreflight.launchablePort;
    _addLog("endpoint unavailable: $nextHost:$nextPort");
    return _AlbatrossEndpointPreflight.invalid;
  }

  Future<bool> _endpointCanBind(String host, int port) async {
    try {
      final server = await ServerSocket.bind(host, port);
      await server.close();
      return true;
    } catch (e) {
      _addLog("endpoint bind failed: $e");
      return false;
    }
  }

  Future<bool> _runtimeAssetsReadyForStart() async {
    if (executablePath.q.isEmpty || !await File(executablePath.q).exists()) {
      _addLog("binary missing");
      return false;
    }
    if (tokenizerPath.q.isEmpty || !await File(tokenizerPath.q).exists()) {
      _addLog("tokenizer missing");
      return false;
    }

    final missingDlls = missingAlbatrossRuntimeDlls(
      executablePath: executablePath.q,
      isWindows: Platform.isWindows,
      fileExists: (filePath) => File(filePath).existsSync(),
    );
    if (missingDlls.isEmpty) return true;

    _addLog("missing runtime DLLs: ${missingDlls.join(", ")}");
    return false;
  }

  Future<bool> _modelReadyForStart() async {
    if (modelPath.q.isEmpty || !await File(modelPath.q).exists()) {
      _addLog("pth model missing");
      return false;
    }
    return true;
  }

  Future<void> copyLogsToClipboard() async {
    final content = _buildLogsExportContent();
    if (content.isEmpty) {
      Alert.warning(S.current.no_data);
      return;
    }
    await Clipboard.setData(ClipboardData(text: content));
    Alert.success(S.current.chat_copied_to_clipboard);
  }

  Future<void> exportLogsToTxt() async {
    final content = _buildLogsExportContent();
    if (content.isEmpty) {
      Alert.warning(S.current.no_data);
      return;
    }

    try {
      if (_shouldSaveLogsExportFile()) {
        await _saveLogsExportFile(content);
        return;
      }

      await _shareLogsExportFile(content);
    } catch (e, stackTrace) {
      qqe("Export Albatross logs failed: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
      Alert.error(S.current.export_failed);
    }
  }

  Future<void> refreshCudaInfo() async {
    final info = <String, String>{};

    if (!Platform.isWindows && !Platform.isLinux) {
      cudaInfo.q = info;
      return;
    }

    try {
      final queryResult = Platform.isWindows
          ? await Process.run("cmd", [
              "/c",
              "nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits 2>nul",
            ])
          : await Process.run("bash", [
              "-c",
              "nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1",
            ]);
      final output = queryResult.stdout.toString().trim();
      final firstLine = output.split(RegExp(r'[\r\n]+')).firstOrNull?.trim() ?? "";
      final parts = firstLine.split(",").map((part) => part.trim()).toList();
      if (parts.isNotEmpty && parts[0].isNotEmpty) info["NVIDIA GPU"] = parts[0];
      if (parts.length > 1 && parts[1].isNotEmpty) info["NVIDIA Driver"] = parts[1];
      if (parts.length > 2 && parts[2].isNotEmpty) info["NVIDIA VRAM"] = "${parts[2]} MB";

      final smiResult = Platform.isWindows
          ? await Process.run("cmd", ["/c", "nvidia-smi 2>nul"])
          : await Process.run("bash", ["-c", "nvidia-smi 2>/dev/null | head -5"]);
      final smiOutput = smiResult.stdout.toString();
      final cudaMatch = RegExp(r'CUDA Version:\s*([^\s|]+)').firstMatch(smiOutput);
      final cudaVersion = cudaMatch?.group(1);
      if (cudaVersion != null && cudaVersion.isNotEmpty) {
        info["CUDA Driver API"] = cudaVersion;
      }
    } catch (e) {
      _addLog("cuda info failed: $e");
    }

    cudaInfo.q = info;
  }

  String _buildLogsExportContent() {
    return buildAlbatrossRuntimeLogExportContent(
      launchCommandTitle: S.current.albatross_launch_command,
      runtimeLogsTitle: S.current.albatross_runtime_logs,
      launchCommand: launchCommand.q,
      logs: logs.q,
    );
  }

  bool _shouldSaveLogsExportFile() {
    if (Platform.isWindows) return true;
    if (Platform.isMacOS) return true;
    if (Platform.isLinux) return true;
    return false;
  }

  Future<void> _saveLogsExportFile(String content) async {
    final fileName = buildAlbatrossRuntimeLogExportFileName(now: DateTime.now());
    final targetPath = await file_picker.FilePicker.saveFile(
      dialogTitle: S.current.albatross_export_logs_txt,
      fileName: fileName,
      type: file_picker.FileType.custom,
      allowedExtensions: const <String>['txt'],
      lockParentWindow: true,
    );
    if (targetPath == null) return;

    final outputPath = _ensureTxtPath(targetPath);
    await File(outputPath).writeAsString(content, encoding: utf8);
    Alert.success("${S.current.export_success}\n\n$outputPath");
  }

  Future<void> _shareLogsExportFile(String content) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = buildAlbatrossRuntimeLogExportFileName(now: DateTime.now());
    final file = File(join(tempDir.path, fileName));
    await file.writeAsString(content, encoding: utf8);

    final xFile = XFile(file.path, mimeType: 'text/plain');
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[xFile],
        subject: fileName,
        title: S.current.albatross_export_logs_txt,
      ),
    );
  }

  String _ensureTxtPath(String targetPath) {
    if (extension(targetPath).isNotEmpty) return targetPath;
    return "$targetPath.txt";
  }

  bool _canLaunchRuntime({required bool showAlert}) {
    if (canLaunchAlbatrossRuntime(isMacOS: Platform.isMacOS)) return true;

    final message = S.current.albatross_backend_unsupported;
    lastError.q = message;
    _addLog("runtime launch unsupported on this platform");
    if (showAlert) Alert.info(message);
    return false;
  }

  String _buildChatCompletionPrompt(List<String> messages) {
    final assistantPrefix = _assistantPrefix();
    return buildAlbatrossCompletionPrompt(
      messages,
      systemPrompt: P.preference.promptTemplate.formatedSystemPrompt().trim(),
      assistantPrefix: assistantPrefix,
    );
  }

  List<Map<String, String>> _buildChatRequestMessages(List<String> messages) {
    final assistantPrefix = _assistantPrefix();
    return buildAlbatrossChatRequestMessages(
      messages,
      systemPrompt: P.preference.promptTemplate.formatedSystemPrompt().trim(),
      assistantPrefix: assistantPrefix,
    );
  }

  String _initialChatOutput(List<String> messages) {
    final assistantPrefix = _assistantPrefix();
    if (messages.isEmpty) return assistantPrefix.trim();
    if (messages.length.isOdd) return assistantPrefix.trim();
    return normalizeAlbatrossAssistantOutput(messages.last, assistantPrefix);
  }

  String _assistantPrefix() {
    return P.preference.promptTemplate.apply(P.rwkvParams.thinkingMode.q);
  }

  Map<String, Object?> _decodeParams() {
    return {
      "temperature": P.rwkvParams.arguments(Argument.temperature).q,
      "top_k": P.rwkvParams.arguments(Argument.topK).q,
      "top_p": P.rwkvParams.arguments(Argument.topP).q,
      "alpha_presence": P.rwkvParams.arguments(Argument.presencePenalty).q,
      "alpha_frequency": P.rwkvParams.arguments(Argument.frequencyPenalty).q,
      "alpha_decay": P.rwkvParams.arguments(Argument.penaltyDecay).q,
      "max_tokens": P.rwkvParams.arguments(Argument.maxLength).q,
    };
  }

  void _startMetricsPolling() {
    _stopMetricsPolling();
    _lastMetricGeneratedTokens = null;
    _lastMetricAt = null;
    unawaited(_pollMetricsOnce());
    _metricsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      unawaited(_pollMetricsOnce());
    });
  }

  void _stopMetricsPolling() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _metricsPollInFlight = false;
    _lastMetricGeneratedTokens = null;
    _lastMetricAt = null;
  }

  Future<void> _pollMetricsOnce() async {
    if (_metricsPollInFlight) return;
    _metricsPollInFlight = true;
    try {
      await _readMetricsStatus(includeLastRequest: false);
    } catch (e) {
      _debugMetricLog("poll failed: $e");
    } finally {
      _metricsPollInFlight = false;
    }
  }

  Future<void> _pollFinalMetricsOnce() async {
    try {
      await _readMetricsStatus(includeLastRequest: true);
    } catch (e) {
      _debugMetricLog("final poll failed: $e");
    }
  }

  Future<void> _readMetricsStatus({required bool includeLastRequest}) async {
    final uri = Uri.parse("${baseUrl.q}/v1/server/status");
    final response = await http.get(uri).timeout(const Duration(seconds: 1));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _debugMetricLog("status http ${response.statusCode}, includeLastRequest=$includeLastRequest");
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<dynamic, dynamic>) return;
    _debugMetricLog(
      "status includeLastRequest=$includeLastRequest active=${_metricRequestSummary(decoded["active_request"])} last=${_metricRequestSummary(decoded["last_request"])}",
    );
    final metricSource = _metricRequestFromStatus(decoded, includeLastRequest: includeLastRequest);
    if (metricSource == null) {
      _debugMetricLog("skip no metric request, includeLastRequest=$includeLastRequest");
      return;
    }
    final request = metricSource.request;

    final prefillSpeed = _jsonDouble(request["prefill_speed"]);
    final decodeSpeed = _jsonDouble(request["decode_speed"]);
    final generatedTokens = _jsonInt(request["generated_tokens"]);
    final prefillProgress = _jsonDouble(request["prefill_progress"]);
    final now = DateTime.now();
    _debugMetricLog(
      "apply source=${metricSource.source} endpoint=${request["endpoint"]} prefillSpeed=$prefillSpeed decodeSpeed=$decodeSpeed prefillProgress=$prefillProgress generatedTokens=$generatedTokens",
    );

    if (prefillSpeed != null && prefillSpeed > 0) {
      P.rwkvGeneration.prefillSpeed.q = prefillSpeed;
      _markPrefillComplete();
      _debugMetricLog(
        "stored prefillSpeed=${P.rwkvGeneration.prefillSpeed.q} prefillProgress=${P.rwkvGeneration.prefillProgress.q}",
      );
    }

    final effectiveDecodeSpeed = decodeSpeed != null && decodeSpeed > 0
        ? decodeSpeed
        : _estimateDecodeSpeed(generatedTokens: generatedTokens, now: now);
    if (effectiveDecodeSpeed != null && effectiveDecodeSpeed > 0) {
      P.rwkvGeneration.decodeSpeed.q = effectiveDecodeSpeed;
      P.telemetry.trackDecodeSpeed(effectiveDecodeSpeed);
      _debugMetricLog("stored decodeSpeed=${P.rwkvGeneration.decodeSpeed.q}");
    }

    _lastMetricGeneratedTokens = generatedTokens;
    _lastMetricAt = now;
  }

  ({Map<dynamic, dynamic> request, String source})? _metricRequestFromStatus(
    Map<dynamic, dynamic> decoded, {
    required bool includeLastRequest,
  }) {
    final activeRequest = decoded["active_request"];
    if (activeRequest is Map<dynamic, dynamic>) {
      return (request: activeRequest, source: "active_request");
    }
    if (!includeLastRequest) return null;

    final lastRequest = decoded["last_request"];
    if (lastRequest is Map<dynamic, dynamic>) {
      return (request: lastRequest, source: "last_request");
    }
    return null;
  }

  String _metricRequestSummary(Object? request) {
    if (request == null) return "null";
    if (request is! Map<dynamic, dynamic>) return request.runtimeType.toString();

    final endpoint = request["endpoint"];
    final prefillSpeed = request["prefill_speed"];
    final decodeSpeed = request["decode_speed"];
    final prefillProgress = request["prefill_progress"];
    final generatedTokens = request["generated_tokens"];
    return "{endpoint=$endpoint,prefill=$prefillSpeed,decode=$decodeSpeed,progress=$prefillProgress,generated=$generatedTokens}";
  }

  void _debugMetricLog(String message) {
    if (!kDebugMode) return;

    final line = "[AlbatrossMetrics] $message";
    if (_lastMetricsDebugLine == line) return;
    _lastMetricsDebugLine = line;
    qqq(line);
    _addLog(line);
  }

  void debugMetricRenderLog(String message) {
    if (!kDebugMode) return;

    final line = "[AlbatrossMetrics] $message";
    if (_lastMetricsDebugLine == line) return;
    _lastMetricsDebugLine = line;
    qqq(line);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addLog(line);
    });
  }

  double? _estimateDecodeSpeed({required int? generatedTokens, required DateTime now}) {
    if (generatedTokens == null) return null;
    final lastGeneratedTokens = _lastMetricGeneratedTokens;
    final lastMetricAt = _lastMetricAt;
    if (lastGeneratedTokens == null || lastMetricAt == null) return null;
    if (generatedTokens <= lastGeneratedTokens) return null;

    final elapsedMicroseconds = now.difference(lastMetricAt).inMicroseconds;
    if (elapsedMicroseconds <= 0) return null;

    final deltaTokens = generatedTokens - lastGeneratedTokens;
    return deltaTokens * Duration.microsecondsPerSecond / elapsedMicroseconds;
  }

  void _markPrefillComplete() {
    if (P.rwkvGeneration.prefillProgress.q >= 1) return;
    P.rwkvGeneration.prefillProgress.q = 1;
  }

  double? _jsonDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _jsonInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _ensureConfiguredAssets() async {
    if (executablePath.q.isEmpty || !await File(executablePath.q).exists()) {
      throw S.current.albatross_binary_required;
    }
    if (modelPath.q.isEmpty || !await File(modelPath.q).exists()) {
      throw S.current.albatross_model_required;
    }
    if (tokenizerPath.q.isEmpty || !await File(tokenizerPath.q).exists()) {
      throw S.current.albatross_tokenizer_required;
    }
    final missingDlls = missingAlbatrossRuntimeDlls(
      executablePath: executablePath.q,
      isWindows: Platform.isWindows,
      fileExists: (filePath) => File(filePath).existsSync(),
    );
    if (missingDlls.isEmpty) return;

    final missingText = missingDlls.join(", ");
    _addLog("missing runtime DLLs: $missingText");
    throw S.current.albatross_missing_runtime_dlls(missingText);
  }

  Future<void> _startProcess() async {
    if (_process != null) {
      if (!_detachedRuntimeLaunched || running.q) return;
      _process = null;
      launchedByApp.q = false;
      processId.q = null;
    }
    final args = _launchArgs();
    _addLog("start: ${[executablePath.q, ...args].join(" ")}");
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    final process = await Process.start(
      executablePath.q,
      args,
      workingDirectory: dirname(executablePath.q),
      environment: _launchEnvironment(),
      mode: ProcessStartMode.normal,
    );
    _process = process;
    _detachedRuntimeLaunched = false;
    launchedByApp.q = true;
    processId.q = process.pid;
    _addLog("process started: ${process.pid}");

    _stdoutSub = process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      qqq("Albatross: $line");
      _addLog("stdout: $line");
    });
    _stderrSub = process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      qqw("Albatross: $line");
      _addLog("stderr: $line");
    });
    unawaited(_watchProcessExit(process));
  }

  Future<bool> _waitUntilRunning() async {
    for (int i = 0; i < _albatrossStartupProbeAttempts; i++) {
      await Future<void>.delayed(_albatrossStartupProbeInterval);
      if (await probe(verbose: false)) {
        _addLog("service ready after ${i + 1}s");
        return true;
      }

      final exitCode = processExitCode.q;
      if (exitCode != null) {
        throw "${S.current.albatross_service_not_running} (${S.current.albatross_exit_code}: $exitCode)";
      }

      if ((i + 1) % 10 == 0) {
        _addLog("waiting for service: ${i + 1}s");
      }
    }
    throw S.current.albatross_service_not_running;
  }

  List<String> _launchArgs() {
    return _launchArgsFor(
      modelPath: modelPath.q,
      tokenizerPath: tokenizerPath.q,
      host: host.q,
      port: port.q,
    );
  }

  List<String> _launchArgsFor({
    required String modelPath,
    required String tokenizerPath,
    required String host,
    required int port,
  }) {
    final binaryConfig = _binaryConfig;
    final rawArgs = binaryConfig?["launch_args"] ?? binaryConfig?["args"];
    return buildAlbatrossLaunchArgs(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      host: host,
      port: port,
      rawArgs: rawArgs,
    );
  }

  Map<String, String>? _launchEnvironment() {
    if (!Platform.isWindows) return null;
    return <String, String>{
      "PATH": buildAlbatrossWindowsPath(
        executablePath: executablePath.q,
        existingPath: Platform.environment["PATH"] ?? "",
      ),
    };
  }

  Map<String, dynamic>? get _binaryConfig {
    final config = P.app._config.q;
    final albatross = config?["albatross"];
    if (albatross is! Map) return null;
    final binary = albatross["binary_config"] ?? albatross["binary"];
    if (binary is! Map) return null;
    return HF.json(binary);
  }

  Map<String, dynamic>? get _tokenizerConfig {
    final config = P.app._config.q;
    final albatross = config?["albatross"];
    if (albatross is! Map) return null;
    final tokenizer = albatross["tokenizer_config"] ?? albatross["tokenizer"];
    if (tokenizer is! Map) return null;
    return HF.json(tokenizer);
  }

  FileInfo? _fileInfoFromConfig(Map<String, dynamic>? config) {
    if (config == null) return null;
    if (config["url"] == null || config["name"] == null || config["fileSize"] == null) {
      return null;
    }
    return FileInfo.fromJSON({
      ...config,
      "platforms": config["platforms"] ?? const <String>["windows"],
      "availableIn": config["availableIn"] ?? const <String>["modelscope", "huggingface", "aifasthub"],
    });
  }

  String? _configString(Map<String, dynamic>? config, String key) {
    final value = config?[key];
    if (value is String) return value;
    return null;
  }

  int? _configInt(Map<String, dynamic>? config, String key) {
    final value = config?[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _watchProcessExit(Process process) async {
    final code = await process.exitCode;
    if (_process != process) return;
    processExitCode.q = code;
    _addLog("process exited: $code");
    _process = null;
    _detachedRuntimeLaunched = false;
    launchedByApp.q = false;
    running.q = false;
    processId.q = null;
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, "0");
  }

  String _formatLogTime(DateTime time) {
    final hour = _twoDigits(time.hour);
    final minute = _twoDigits(time.minute);
    final second = _twoDigits(time.second);
    return "$hour:$minute:$second";
  }

  void _addLog(String message) {
    final entry = "[${_formatLogTime(DateTime.now())}] $message";
    final current = logs.q;
    logs.q = [...current.length > _albatrossLogLimit ? current.sublist(current.length - _albatrossLogLimit) : current, entry];
  }
}
