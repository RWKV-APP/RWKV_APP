part of 'p.dart';

class _AlbatrossRuntime {
  static const String _defaultHost = "127.0.0.1";
  static const int _defaultPort = 9527;
  static const List<int> _defaultStopTokens = <int>[0, 261, 24281];
  static const int _chunkSize = 3;

  Process? _process;
  http.Client? _client;
  // ignore: unused_field
  AppLifecycleListener? _lifecycleListener;

  late final enabled = qs(false);
  late final connecting = qs(false);
  late final running = qs(false);
  late final downloading = qs(false);
  late final launchedByApp = qs(false);
  late final host = qs(_defaultHost);
  late final port = qs(_defaultPort);
  late final executablePath = qs("");
  late final modelPath = qs("");
  late final tokenizerPath = qs("");
  late final lastError = qs("");

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
      gpuName: gpuName,
    );
  });

  late final canUse = qp<bool>((ref) {
    final enabled = ref.watch(this.enabled);
    final running = ref.watch(this.running);
    return enabled && running;
  });
}

extension $AlbatrossRuntime on _AlbatrossRuntime {
  Future<void> _init() async {
    _applyConfigDefaults();
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
    enableExternalMode();
    connecting.q = true;
    lastError.q = "";
    try {
      final connected = await probe();
      if (connected) return true;

      await _ensureConfiguredAssets();
      await _startProcess();
      return await _waitUntilRunning();
    } catch (e) {
      lastError.q = e.toString();
      Alert.error(e.toString());
      return false;
    } finally {
      connecting.q = false;
    }
  }

  Future<bool> probe() async {
    final client = http.Client();
    try {
      final uri = Uri.parse("${baseUrl.q}/status");
      final response = await client.get(uri).timeout(const Duration(seconds: 2));
      running.q = response.statusCode >= 200 && response.statusCode < 300;
      return running.q;
    } catch (_) {
      try {
        final uri = Uri.parse("${baseUrl.q}/v1/server/status");
        final response = await client.get(uri).timeout(const Duration(seconds: 2));
        running.q = response.statusCode >= 200 && response.statusCode < 300;
        return running.q;
      } catch (_) {
        running.q = false;
        return false;
      }
    } finally {
      client.close();
    }
  }

  Future<void> downloadConfiguredBinary() async {
    final fileInfo = _fileInfoFromConfig(_binaryConfig);
    if (fileInfo == null) {
      throw S.current.albatross_binary_config_missing;
    }
    downloading.q = true;
    try {
      await P.remote.getFile(fileInfo: fileInfo);
      executablePath.q = P.remote.locals(fileInfo).q.targetPath;
    } finally {
      downloading.q = false;
    }
  }

  Future<void> downloadConfiguredTokenizer() async {
    final fileInfo = _fileInfoFromConfig(_tokenizerConfig);
    if (fileInfo == null) {
      throw S.current.albatross_tokenizer_config_missing;
    }
    downloading.q = true;
    try {
      await P.remote.getFile(fileInfo: fileInfo);
      tokenizerPath.q = P.remote.locals(fileInfo).q.targetPath;
    } finally {
      downloading.q = false;
    }
  }

  Future<void> pickExecutable() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: const <String>["exe"],
    );
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;
    executablePath.q = path;
  }

  Future<void> pickModelPth() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: const <String>["pth"],
    );
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;
    modelPath.q = path;
  }

  Future<void> pickTokenizer() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: const <String>["txt", "json", "model"],
    );
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;
    tokenizerPath.q = path;
  }

  Future<void> pickModelFolder() async {
    final path = await file_picker.FilePicker.getDirectoryPath();
    if (path == null || path.isEmpty) return;
    await selectModelFolder(path);
  }

  Future<void> useDownloadedModel(FileInfo fileInfo) async {
    final local = P.remote.locals(fileInfo).q;
    if (!local.hasFile) {
      Alert.info(S.current.chat_you_need_download_model_if_you_want_to_use_it);
      return;
    }
    modelPath.q = local.targetPath;
  }

  Future<void> selectModelFolder(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) return;

    String nextModelPath = modelPath.q;
    String nextTokenizerPath = tokenizerPath.q;
    await for (final entity in directory.list(recursive: false, followLinks: false)) {
      if (entity is! File) continue;
      final basename = basenameWithoutExtension(entity.path).toLowerCase();
      final extension = entity.path.split('.').last.toLowerCase();
      if (nextModelPath.isEmpty && extension == "pth") {
        nextModelPath = entity.path;
      }
      if (nextTokenizerPath.isEmpty && (basename.contains("vocab") || basename.contains("tokenizer"))) {
        nextTokenizerPath = entity.path;
      }
    }
    modelPath.q = nextModelPath;
    tokenizerPath.q = nextTokenizerPath;
  }

  Future<void> handleDroppedPath(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await selectModelFolder(path);
      return;
    }
    final lower = path.toLowerCase();
    if (lower.endsWith(".pth")) {
      modelPath.q = path;
      return;
    }
    if (lower.endsWith(".txt") || lower.endsWith(".json") || lower.endsWith(".model")) {
      tokenizerPath.q = path;
      return;
    }
    if (lower.endsWith(".exe")) {
      executablePath.q = path;
    }
  }

  Stream<from_rwkv.FromRWKV> chat(List<String> messages, {int batchSize = 1}) async* {
    final prompt = buildAlbatrossCompletionPrompt(messages);
    await for (final event in _streamContents(
      contents: List<String>.filled(batchSize, prompt),
      includePromptInOutput: false,
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

  Stream<from_rwkv.ResponseBatchBufferContent> chatSlots(List<List<String>> batchMessages) {
    final contents = batchMessages.map(buildAlbatrossCompletionPrompt).toList();
    return _streamContents(contents: contents, includePromptInOutput: false);
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

  Stream<from_rwkv.ResponseBatchBufferContent> _streamContents({
    required List<String> contents,
    required bool includePromptInOutput,
  }) async* {
    final batchSize = contents.length;
    final result = includePromptInOutput ? List<String>.from(contents) : List<String>.filled(batchSize, "");
    final eosFound = List<bool>.filled(batchSize, false);
    final parser = AlbatrossSseParser();

    P.rwkvGeneration.generating.q = true;
    _client?.close();
    _client = http.Client();
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

      await for (final rawChunk in response.stream.transform(utf8.decoder)) {
        final events = parser.add(rawChunk);
        for (final event in events) {
          if (event.done) {
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
          }
          yield from_rwkv.ResponseBatchBufferContent(
            responseBufferContent: List<String>.from(result),
            eosFound: List<bool>.from(eosFound),
            batchSize: batchSize,
          );
        }
      }
    } finally {
      P.rwkvGeneration.generating.q = false;
      _client?.close();
      _client = null;
    }
  }

  Future<void> stop() async {
    _client?.close();
    _client = null;
    try {
      final uri = Uri.parse("${baseUrl.q}/v1/server/stop");
      await http.post(uri).timeout(const Duration(seconds: 2));
    } catch (e) {
      qqw("Albatross stop failed: $e");
    } finally {
      P.rwkvGeneration.generating.q = false;
    }
  }

  Future<void> shutdown() async {
    _client?.close();
    _client = null;
    if (!launchedByApp.q) return;
    _process?.kill();
    _process = null;
    launchedByApp.q = false;
    running.q = false;
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

  Future<void> _ensureConfiguredAssets() async {
    if (executablePath.q.isEmpty) {
      await downloadConfiguredBinary();
    }
    if (tokenizerPath.q.isEmpty) {
      try {
        await downloadConfiguredTokenizer();
      } catch (_) {
        //
      }
    }
    if (executablePath.q.isEmpty || !await File(executablePath.q).exists()) {
      throw S.current.albatross_binary_required;
    }
    if (modelPath.q.isEmpty || !await File(modelPath.q).exists()) {
      throw S.current.albatross_model_required;
    }
    if (tokenizerPath.q.isEmpty || !await File(tokenizerPath.q).exists()) {
      throw S.current.albatross_tokenizer_required;
    }
  }

  Future<void> _startProcess() async {
    if (_process != null) return;
    final args = _launchArgs();
    _process = await Process.start(
      executablePath.q,
      args,
      workingDirectory: dirname(executablePath.q),
    );
    launchedByApp.q = true;
    unawaited(_process!.stdout.transform(utf8.decoder).listen((text) => qqq("Albatross: $text")).asFuture<void>());
    unawaited(_process!.stderr.transform(utf8.decoder).listen((text) => qqw("Albatross: $text")).asFuture<void>());
  }

  Future<bool> _waitUntilRunning() async {
    for (int i = 0; i < 20; i++) {
      await 500.msLater;
      if (await probe()) return true;
    }
    throw S.current.albatross_service_not_running;
  }

  List<String> _launchArgs() {
    final binaryConfig = _binaryConfig;
    final rawArgs = binaryConfig?["launch_args"] ?? binaryConfig?["args"];
    final replacements = {
      "{model_path}": modelPath.q,
      "{tokenizer_path}": tokenizerPath.q,
      "{port}": port.q.toString(),
      "{host}": host.q,
    };

    if (rawArgs is List) {
      return rawArgs.map((entry) => _replaceLaunchArg(entry.toString(), replacements)).toList();
    }
    if (rawArgs is String && rawArgs.trim().isNotEmpty) {
      return rawArgs.split(RegExp(r'\s+')).map((entry) => _replaceLaunchArg(entry, replacements)).toList();
    }
    return <String>[
      "--model",
      modelPath.q,
      "--tokenizer",
      tokenizerPath.q,
      "--host",
      host.q,
      "--port",
      port.q.toString(),
    ];
  }

  String _replaceLaunchArg(String value, Map<String, String> replacements) {
    String result = value;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
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
}
