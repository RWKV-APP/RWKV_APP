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
  "/v1/models",
  "/status",
  "/v1/server/status",
];

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
  required String gpuName,
}) {
  if (!isWindows) return false;
  if (!isWindowsX64) return false;
  return gpuName.toLowerCase().contains("nvidia");
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

  final executableDir = path.dirname(executablePath);
  final libDir = path.join(executableDir, "lib");
  final missing = <String>[];
  for (final dll in albatrossWindowsRuntimeDlls) {
    final inExecutableDir = path.join(executableDir, dll);
    final inLibDir = path.join(libDir, dll);
    if (fileExists(inExecutableDir) || fileExists(inLibDir)) continue;
    missing.add(dll);
  }
  return missing;
}

String buildAlbatrossWindowsPath({
  required String executablePath,
  required String existingPath,
}) {
  final executableDir = path.dirname(executablePath);
  final libDir = path.join(executableDir, "lib");
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

String buildAlbatrossCompletionPrompt(List<String> messages) {
  final buffer = StringBuffer();
  for (int i = 0; i < messages.length; i++) {
    final role = i.isEven ? "User" : "Assistant";
    final content = i.isEven ? messages[i].trim() : stripAlbatrossThinking(messages[i]).trim();
    if (content.isEmpty) continue;
    buffer.writeln("$role: $content");
    buffer.writeln();
  }
  buffer.write("Assistant:");
  return buffer.toString();
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

String _formatAlbatrossTimestamp(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');
  return '$year$month${day}_$hour$minute$second';
}
