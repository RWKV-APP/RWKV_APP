// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:path/path.dart' as path;

const List<String> albatrossWindowsRuntimeDlls = <String>[
  "drogon.dll",
  "trantor.dll",
  "jsoncpp.dll",
  "sqlite3.dll",
  "cudart64_12.dll",
  "cublas64_12.dll",
  "cublasLt64_12.dll",
  "msvcp140.dll",
  "vcruntime140.dll",
  "vcruntime140_1.dll",
];

const List<String> albatrossProbePaths = <String>[
  "/v1/server/status",
  "/v1/models",
  "/status",
];

class AlbatrossLocalDiscoveryPaths {
  final List<String> executablePaths;
  final List<String> tokenizerPaths;
  final List<String> modelDirectories;

  const AlbatrossLocalDiscoveryPaths({
    required this.executablePaths,
    required this.tokenizerPaths,
    required this.modelDirectories,
  });
}

class AlbatrossSseChoice {
  final int index;
  final String content;
  final String? finishReason;

  const AlbatrossSseChoice({
    required this.index,
    required this.content,
    required this.finishReason,
  });
}

class AlbatrossSseEvent {
  final bool done;
  final List<AlbatrossSseChoice> choices;

  const AlbatrossSseEvent({
    required this.done,
    required this.choices,
  });

  const AlbatrossSseEvent.done() : done = true, choices = const <AlbatrossSseChoice>[];
}

class AlbatrossSseParser {
  String _pending = "";

  List<AlbatrossSseEvent> add(String chunk) {
    _pending = _pending + chunk;
    final events = <AlbatrossSseEvent>[];

    while (true) {
      final separatorIndex = _pending.indexOf("\n\n");
      if (separatorIndex < 0) break;

      final rawEvent = _pending.substring(0, separatorIndex);
      _pending = _pending.substring(separatorIndex + 2);
      final event = _parseEvent(rawEvent);
      if (event == null) continue;
      events.add(event);
    }

    return events;
  }

  AlbatrossSseEvent? _parseEvent(String rawEvent) {
    final lines = rawEvent.split(RegExp(r'\r?\n'));
    final dataLines = <String>[];
    for (final line in lines) {
      if (!line.startsWith("data:")) continue;
      dataLines.add(line.substring(5).trimLeft());
    }
    if (dataLines.isEmpty) return null;

    final data = dataLines.join("\n").trim();
    if (data.isEmpty) return null;
    if (data == "[DONE]") return const AlbatrossSseEvent.done();

    final decoded = jsonDecode(data);
    if (decoded is! Map) return null;

    final rawChoices = decoded["choices"];
    if (rawChoices is! List) {
      return const AlbatrossSseEvent(done: false, choices: <AlbatrossSseChoice>[]);
    }

    final choices = <AlbatrossSseChoice>[];
    for (final rawChoice in rawChoices) {
      if (rawChoice is! Map) continue;
      final rawIndex = rawChoice["index"];
      final index = rawIndex is int ? rawIndex : 0;
      final delta = rawChoice["delta"];
      final String content;
      if (delta is Map) {
        content = delta["content"] as String? ?? "";
      } else {
        content = rawChoice["text"] as String? ?? "";
      }
      choices.add(
        AlbatrossSseChoice(
          index: index,
          content: content,
          finishReason: rawChoice["finish_reason"] as String?,
        ),
      );
    }

    return AlbatrossSseEvent(done: false, choices: choices);
  }
}

bool shouldShowAlbatrossEntry({
  required bool isWindows,
  required bool isWindowsX64,
  required bool isLinux,
  required bool isMacOS,
  required String gpuName,
}) {
  if (isMacOS) return true;
  if (isLinux) return true;
  if (!isWindows) return false;
  if (!isWindowsX64) return false;
  return gpuName.toLowerCase().contains("nvidia");
}

bool isAlbatrossCudaBackendAvailable({
  required bool isWindows,
  required bool isLinux,
  required bool isMacOS,
  required Map<String, String> telemetryInfo,
  required Map<String, String> cudaInfo,
}) {
  if (isMacOS) return false;
  if (!isWindows && !isLinux) return false;

  final gpuName = <String>[
    cudaInfo["NVIDIA GPU"] ?? "",
    telemetryInfo["GPUName"] ?? "",
  ].join(" ").toLowerCase();
  final hasNvidiaGpu = gpuName.contains("nvidia");
  final hasCudaDriverApi = cudaInfo["CUDA Driver API"]?.trim().isNotEmpty ?? false;
  return hasNvidiaGpu && hasCudaDriverApi;
}

bool canLaunchAlbatrossRuntime({required bool isMacOS}) {
  return !isMacOS;
}

List<String> buildAlbatrossDiscoveryRoots({
  required String currentDirectory,
  required String resolvedExecutable,
}) {
  final roots = <String>[];

  void add(String value) {
    final normalized = path.normalize(value.trim());
    if (normalized.isEmpty) return;
    if (roots.contains(normalized)) return;
    roots.add(normalized);
  }

  void addWithParents(String value) {
    final normalized = path.normalize(value.trim());
    if (normalized.isEmpty) return;
    add(normalized);

    final parent = path.dirname(normalized);
    if (parent == normalized) return;
    add(parent);

    final grandparent = path.dirname(parent);
    if (grandparent == parent) return;
    add(grandparent);
  }

  addWithParents(currentDirectory);

  final executableDir = path.dirname(resolvedExecutable.trim());
  if (executableDir != ".") {
    addWithParents(executableDir);
  }

  return roots;
}

AlbatrossLocalDiscoveryPaths discoverAlbatrossLocalPaths({
  required Iterable<String> roots,
  required bool isWindows,
  required bool Function(String filePath) fileExists,
  required bool Function(String directoryPath) directoryExists,
}) {
  final executablePaths = <String>[];
  final tokenizerPaths = <String>[];
  final modelDirectories = <String>[];

  void addFileCandidate(List<String> segments, List<String> target) {
    final candidate = path.joinAll(segments);
    final normalized = path.normalize(candidate);
    if (target.contains(normalized)) return;
    if (!fileExists(normalized)) return;
    target.add(normalized);
  }

  void addDirectoryCandidate(List<String> segments) {
    final candidate = path.joinAll(segments);
    final normalized = path.normalize(candidate);
    if (modelDirectories.contains(normalized)) return;
    if (!directoryExists(normalized)) return;
    modelDirectories.add(normalized);
  }

  final executableFileNames = isWindows
      ? const <String>["rwkv_lighting_cuda.exe", "rwkv_lightning_cuda.exe"]
      : const <String>["rwkv_lighting_cuda", "rwkv_lightning_cuda"];

  for (final rawRoot in roots) {
    final root = path.normalize(rawRoot.trim());
    if (root.isEmpty) continue;

    for (final executableFileName in executableFileNames) {
      for (final relative in _albatrossExecutableRelativeSegments(executableFileName)) {
        addFileCandidate(<String>[root, ...relative], executablePaths);
      }
    }

    for (final relative in _albatrossTokenizerRelativeSegments()) {
      addFileCandidate(<String>[root, ...relative], tokenizerPaths);
    }

    for (final relative in _albatrossModelDirectoryRelativeSegments()) {
      addDirectoryCandidate(<String>[root, ...relative]);
    }
  }

  return AlbatrossLocalDiscoveryPaths(
    executablePaths: executablePaths,
    tokenizerPaths: tokenizerPaths,
    modelDirectories: modelDirectories,
  );
}

List<String> buildAlbatrossLaunchArgs({
  required String modelPath,
  required String tokenizerPath,
  required String host,
  required int port,
  Object? rawArgs,
}) {
  final replacements = <String, String>{
    "{model_path}": modelPath,
    "{tokenizer_path}": tokenizerPath,
    "{port}": port.toString(),
    "{host}": host,
  };

  final configuredArgs = _configuredAlbatrossLaunchArgs(
    rawArgs: rawArgs,
    replacements: replacements,
  );
  if (configuredArgs.isNotEmpty) return configuredArgs;

  return <String>[
    "--model-path",
    modelPath,
    "--vocab-path",
    tokenizerPath,
    "--port",
    port.toString(),
  ];
}

String buildAlbatrossLaunchCommand({
  required String executablePath,
  required List<String> args,
}) {
  return <String>[executablePath, ...args].join(" ");
}

Map<String, String> buildAlbatrossDisplaySystemInfo({
  required Map<String, String> telemetryInfo,
  required Map<String, String> cudaInfo,
  required bool isDesktop,
}) {
  final result = <String, String>{};
  for (final entry in telemetryInfo.entries) {
    if (isDesktop && (entry.key == "SocName" || entry.key == "SocBrand")) continue;
    result[entry.key] = entry.value;
  }

  for (final entry in cudaInfo.entries) {
    if (entry.key == "NVIDIA GPU" && (result["GPUName"]?.isNotEmpty ?? false)) continue;
    if (entry.key == "NVIDIA VRAM" && (result["TotalVRAM"]?.isNotEmpty ?? false)) continue;
    result[entry.key] = entry.value;
  }

  return result;
}

List<String> missingAlbatrossRuntimeDlls({
  required String executablePath,
  required bool isWindows,
  required bool Function(String filePath) fileExists,
}) {
  if (!isWindows) return const <String>[];
  if (executablePath.trim().isEmpty) return albatrossWindowsRuntimeDlls;

  final executableDir = path.windows.dirname(executablePath);
  final libDir = path.windows.join(executableDir, "lib");
  final missing = <String>[];
  for (final dll in albatrossWindowsRuntimeDlls) {
    final inExecutableDir = path.windows.join(executableDir, dll);
    final inLibDir = path.windows.join(libDir, dll);
    if (fileExists(inExecutableDir) || fileExists(inLibDir)) continue;
    missing.add(dll);
  }
  return missing;
}

String buildAlbatrossWindowsPath({
  required String executablePath,
  required String existingPath,
}) {
  final executableDir = path.windows.dirname(executablePath);
  final libDir = path.windows.join(executableDir, "lib");
  if (existingPath.trim().isEmpty) return libDir;
  return "$libDir;$existingPath";
}

String buildAlbatrossRuntimeLogExportContent({
  required String launchCommandTitle,
  required String runtimeLogsTitle,
  required String launchCommand,
  required List<String> logs,
}) {
  if (logs.isEmpty) return "";

  final buffer = StringBuffer();
  if (launchCommand.trim().isNotEmpty) {
    buffer
      ..writeln("===== $launchCommandTitle =====")
      ..writeln()
      ..writeln(launchCommand.trim())
      ..writeln();
  }

  buffer
    ..writeln("===== $runtimeLogsTitle =====")
    ..writeln();
  for (final log in logs) {
    buffer.writeln(log);
  }

  return buffer.toString();
}

String buildAlbatrossRuntimeLogExportFileName({required DateTime now}) {
  return "rwkv_albatross_logs_${_formatAlbatrossTimestamp(now)}.txt";
}

String buildAlbatrossCompletionPrompt(
  List<String> messages, {
  String systemPrompt = "",
  String assistantPrefix = "",
}) {
  final entries = <String>[];
  final normalizedSystemPrompt = systemPrompt.trim();
  if (normalizedSystemPrompt.isNotEmpty) {
    entries.add("System: $normalizedSystemPrompt");
  }

  final lastAssistantIndex = messages.length.isEven ? messages.length - 1 : null;
  for (int i = 0; i < messages.length; i++) {
    final role = i.isEven ? "User" : "Assistant";
    final preserveAssistantPrefix = i == lastAssistantIndex;
    final content = i.isEven
        ? messages[i].trim()
        : preserveAssistantPrefix
        ? messages[i].trim().isEmpty
              ? ""
              : normalizeAlbatrossAssistantOutput(messages[i], assistantPrefix)
        : stripAlbatrossThinking(messages[i]).trim();
    if (content.isEmpty) {
      continue;
    }
    entries.add("$role: $content");
  }

  if (messages.length.isOdd || entries.isEmpty) {
    entries.add(_albatrossAssistantLine(assistantPrefix));
    return entries.join("\n\n");
  }

  final lastMessage = messages.isEmpty ? "" : messages.last.trim();
  if (lastMessage.isEmpty) {
    entries.add(_albatrossAssistantLine(assistantPrefix));
  }
  return entries.join("\n\n");
}

String _albatrossAssistantLine(String assistantPrefix) {
  final normalizedAssistantPrefix = assistantPrefix.trim();
  if (normalizedAssistantPrefix.isEmpty) return "Assistant:";
  return "Assistant: $normalizedAssistantPrefix";
}

String normalizeAlbatrossAssistantOutput(String value, String assistantPrefix) {
  final normalizedValue = value.trim();
  final normalizedAssistantPrefix = assistantPrefix.trim();
  if (normalizedValue.isEmpty) return normalizedAssistantPrefix;
  if (normalizedAssistantPrefix.isEmpty) return normalizedValue;
  if (normalizedValue.startsWith(normalizedAssistantPrefix)) return normalizedValue;
  if (normalizedValue.startsWith(">") && !normalizedAssistantPrefix.endsWith(">")) {
    return "$normalizedAssistantPrefix$normalizedValue";
  }
  return normalizedValue;
}

List<Map<String, String>> buildAlbatrossChatMessages(List<String> messages) {
  final result = <Map<String, String>>[];
  for (int i = 0; i < messages.length; i++) {
    final role = i.isEven ? "user" : "assistant";
    final content = i.isEven ? messages[i].trim() : stripAlbatrossThinking(messages[i]).trim();
    if (content.isEmpty) continue;
    result.add(<String, String>{
      "role": role,
      "content": content,
    });
  }
  return result;
}

List<Map<String, String>> buildAlbatrossChatRequestMessages(
  List<String> messages, {
  String systemPrompt = "",
  String assistantPrefix = "",
}) {
  final result = <Map<String, String>>[];
  final normalizedSystemPrompt = systemPrompt.trim();
  if (normalizedSystemPrompt.isNotEmpty) {
    result.add(<String, String>{
      "role": "system",
      "content": normalizedSystemPrompt,
    });
  }

  final lastAssistantIndex = messages.length.isEven ? messages.length - 1 : null;
  for (int i = 0; i < messages.length; i++) {
    final role = i.isEven ? "user" : "assistant";
    final preserveAssistantPrefix = i == lastAssistantIndex;
    final content = i.isEven
        ? messages[i].trim()
        : preserveAssistantPrefix
        ? messages[i].trim().isEmpty
              ? ""
              : normalizeAlbatrossAssistantOutput(messages[i], assistantPrefix)
        : stripAlbatrossThinking(messages[i]).trim();
    if (content.isEmpty) continue;
    result.add(<String, String>{
      "role": role,
      "content": content,
    });
  }

  return result;
}

String stripAlbatrossThinking(String value) {
  return value.replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '').trim();
}

List<String> _configuredAlbatrossLaunchArgs({
  required Object? rawArgs,
  required Map<String, String> replacements,
}) {
  if (rawArgs is List) {
    return rawArgs.map((entry) => _replaceAlbatrossLaunchArg(entry.toString(), replacements)).toList();
  }
  if (rawArgs is String && rawArgs.trim().isNotEmpty) {
    return rawArgs.split(RegExp(r'\s+')).map((entry) => _replaceAlbatrossLaunchArg(entry, replacements)).toList();
  }
  return const <String>[];
}

String _replaceAlbatrossLaunchArg(String value, Map<String, String> replacements) {
  String result = value;
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

List<List<String>> _albatrossExecutableRelativeSegments(String executableFileName) {
  return <List<String>>[
    <String>[executableFileName],
    <String>["V1.0.0", executableFileName],
    <String>["build_agent_sm86", "bundle", "rwkv_lighting_cuda", executableFileName],
    <String>["build_win10_sm86", "bundle", "rwkv_lighting_cuda", executableFileName],
    <String>["build_agent_sm86", "Release", executableFileName],
    <String>["build_win10_sm86", "Release", executableFileName],
    <String>["rwkv_lightning_cuda", "build_agent_sm86", "bundle", "rwkv_lighting_cuda", executableFileName],
    <String>["rwkv_lightning_cuda", "build_win10_sm86", "bundle", "rwkv_lighting_cuda", executableFileName],
    <String>["rwkv_lightning_cuda", "build_agent_sm86", "Release", executableFileName],
    <String>["rwkv_lightning_cuda", "build_win10_sm86", "Release", executableFileName],
    <String>["rwkv_lightning_cuda_run", "V1.0.0", executableFileName],
  ];
}

List<List<String>> _albatrossTokenizerRelativeSegments() {
  const tokenizerFileName = "rwkv_vocab_v20230424.txt";
  return const <List<String>>[
    <String>[tokenizerFileName],
    <String>["V1.0.0", tokenizerFileName],
    <String>["src", tokenizerFileName],
    <String>["assets", "config", "chat", tokenizerFileName],
    <String>["rwkv_lightning_cuda", "src", tokenizerFileName],
    <String>["rwkv_lightning_cuda_run", "V1.0.0", tokenizerFileName],
    <String>["rwkv_app", "assets", "config", "chat", tokenizerFileName],
  ];
}

List<List<String>> _albatrossModelDirectoryRelativeSegments() {
  return const <List<String>>[
    <String>["models"],
    <String>["rwkv_lightning_cuda_run", "models"],
  ];
}

String _formatAlbatrossTimestamp(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');
  return '$year$month${day}_$hour$minute$second';
}
